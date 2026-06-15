package com.university.flight.info.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.university.flight.common.exception.BizException;
import com.university.flight.info.entity.FlightInfo;
import com.university.flight.info.mapper.FlightInfoMapper;
import com.university.flight.info.service.FlightInfoService;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.CollectionUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Slf4j
@Service
public class FlightInfoServiceImpl extends ServiceImpl<FlightInfoMapper, FlightInfo>
        implements FlightInfoService {

    private static final String FLIGHT_CACHE_KEY = "flight:info:";
    private static final long CACHE_EXPIRE_HOURS = 1;

    @Autowired
    private org.springframework.data.redis.core.RedisTemplate<String, Object> redisTemplate;

    @Override
    public Page<FlightInfo> queryByCondition(String flightNumber, String departureAirport,
                             String arrivalAirport, String airline,
                             String status, LocalDateTime startTime,
                             LocalDateTime endTime, Integer pageNum, Integer pageSize) {
        Page<FlightInfo> page = new Page<>(pageNum, pageSize);
        LambdaQueryWrapper<FlightInfo> wrapper = new LambdaQueryWrapper<>();

        List<String> statusList = new ArrayList<>();
        if (StringUtils.isNotBlank(status)) {
            for (String item : status.split(",")) {
            if (StringUtils.isNotBlank(item)) {
                statusList.add(item.trim());
            }
            }
        }

        wrapper.like(StringUtils.isNotBlank(flightNumber), FlightInfo::getFlightNumber, flightNumber)
            .and(StringUtils.isNotBlank(departureAirport), w -> w.like(FlightInfo::getDepartureAirportCode, departureAirport)
                .or()
                .like(FlightInfo::getDepartureAirportName, departureAirport))
            .and(StringUtils.isNotBlank(arrivalAirport), w -> w.like(FlightInfo::getArrivalAirportCode, arrivalAirport)
                .or()
                .like(FlightInfo::getArrivalAirportName, arrivalAirport))
            .and(StringUtils.isNotBlank(airline), w -> w.like(FlightInfo::getAirlineCode, airline)
                .or()
                .like(FlightInfo::getAirlineName, airline))
            .in(!CollectionUtils.isEmpty(statusList), FlightInfo::getFlightStatus, statusList)
                .ge(startTime != null, FlightInfo::getPlannedDepartureTime, startTime)
                .le(endTime != null, FlightInfo::getPlannedDepartureTime, endTime)
                .orderByAsc(FlightInfo::getPlannedDepartureTime);

        return this.page(page, wrapper);
    }

    @Override
    public FlightInfo getByFlightNumber(String flightNumber) {
        // 先从缓存中获取（带异常保护）
        String cacheKey = FLIGHT_CACHE_KEY + flightNumber;
        try {
            Object cached = redisTemplate.opsForValue().get(cacheKey);
            if (cached != null) {
                log.info("从缓存中获取航班信息: {}", flightNumber);
                return (FlightInfo) cached;
            }
        } catch (Exception e) {
            log.warn("Redis缓存读取失败，将直接从数据库查询: {}", e.getMessage());
        }
        
        // 缓存未命中或读取失败，从数据库查询
        LambdaQueryWrapper<FlightInfo> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FlightInfo::getFlightNumber, flightNumber)
                .last("LIMIT 1");
        FlightInfo flight = this.getOne(wrapper);
        if (flight == null) {
            throw new BizException(404, "Flight not found: " + flightNumber);
        }
        
        // 写入缓存（带异常保护）
        try {
            redisTemplate.opsForValue().set(cacheKey, flight, CACHE_EXPIRE_HOURS, TimeUnit.HOURS);
        } catch (Exception e) {
            log.warn("Redis缓存写入失败: {}", e.getMessage());
        }
        return flight;
    }

    @Override
    public Boolean updateStatus(String flightNumber, String status) {
        FlightInfo flight = this.getByFlightNumber(flightNumber);
        flight.setFlightStatus(status);
        flight.setUpdateTime(LocalDateTime.now());
        Boolean result = this.updateById(flight);
        
        // 更新缓存（带异常保护）
        if (result) {
            try {
                String cacheKey = FLIGHT_CACHE_KEY + flightNumber;
                redisTemplate.opsForValue().set(cacheKey, flight, CACHE_EXPIRE_HOURS, TimeUnit.HOURS);
            } catch (Exception e) {
                log.warn("Redis缓存更新失败: {}", e.getMessage());
            }
        }
        
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Boolean batchUpdateStatus(List<String> flightNumbers, String status) {
        if (CollectionUtils.isEmpty(flightNumbers)) {
            return true;
        }

        LambdaUpdateWrapper<FlightInfo> wrapper = new LambdaUpdateWrapper<>();
        wrapper.in(FlightInfo::getFlightNumber, flightNumbers)
                .set(FlightInfo::getFlightStatus, status)
                .set(FlightInfo::getUpdateTime, LocalDateTime.now());

        return this.update(wrapper);
    }

    @Override
    public Map<String, Long> countByStatus() {
        List<FlightInfo> allFlights = this.list();
        return allFlights.stream()
                .collect(Collectors.groupingBy(
                        FlightInfo::getFlightStatus,
                        Collectors.counting()
                ));
    }

    @Override
    public List<FlightInfo> getFlightsByAirportAndTime(String airportCode,
                                                       LocalDateTime startTime,
                                                       LocalDateTime endTime) {
        LambdaQueryWrapper<FlightInfo> wrapper = new LambdaQueryWrapper<>();
        wrapper.and(w -> w.eq(FlightInfo::getDepartureAirportCode, airportCode)
                        .or()
                        .eq(FlightInfo::getArrivalAirportCode, airportCode))
                .between(FlightInfo::getPlannedDepartureTime, startTime, endTime)
                .orderByAsc(FlightInfo::getPlannedDepartureTime);

        return this.list(wrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Boolean addFlight(FlightInfo flightInfo) {
        FlightInfo existing = this.getByFlightNumberWithoutException(flightInfo.getFlightNumber());
        if (existing != null) {
            throw new BizException(400, "航班号已存在: " + flightInfo.getFlightNumber());
        }

        if (StringUtils.isBlank(flightInfo.getFlightStatus())) {
            flightInfo.setFlightStatus("SCHEDULED");
        }

        return this.save(flightInfo);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Boolean updateFlight(String flightNumber, FlightInfo flightInfo) {
        FlightInfo existing = this.getByFlightNumber(flightNumber);

        if (!flightNumber.equals(flightInfo.getFlightNumber())) {
            FlightInfo sameFlightNumber = this.getByFlightNumberWithoutException(flightInfo.getFlightNumber());
            if (sameFlightNumber != null && !sameFlightNumber.getId().equals(existing.getId())) {
                throw new BizException(400, "航班号已存在: " + flightInfo.getFlightNumber());
            }
        }

        BeanUtils.copyProperties(flightInfo, existing, "id", "createTime", "deleted");
        existing.setUpdateTime(LocalDateTime.now());

        return this.updateById(existing);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Boolean deleteFlight(String flightNumber) {
        FlightInfo flight = this.getByFlightNumber(flightNumber);
        Boolean result = this.removeById(flight.getId());
        
        // 删除缓存（带异常保护）
        if (result) {
            try {
                String cacheKey = FLIGHT_CACHE_KEY + flightNumber;
                redisTemplate.delete(cacheKey);
            } catch (Exception e) {
                log.warn("Redis缓存删除失败: {}", e.getMessage());
            }
        }
        
        return result;
    }

    @Override
    public List<FlightInfo> searchFlights(String keyword) {
        if (StringUtils.isBlank(keyword)) {
            return new ArrayList<>();
        }

        LambdaQueryWrapper<FlightInfo> wrapper = new LambdaQueryWrapper<>();
        wrapper.like(FlightInfo::getFlightNumber, keyword)
                .or()
                .like(FlightInfo::getAirlineName, keyword)
                .or()
                .like(FlightInfo::getDepartureAirportName, keyword)
                .or()
                .like(FlightInfo::getArrivalAirportName, keyword)
                .or()
                .like(FlightInfo::getAircraftType, keyword)
                .orderByAsc(FlightInfo::getPlannedDepartureTime);

        return this.list(wrapper);
    }

    private FlightInfo getByFlightNumberWithoutException(String flightNumber) {
        try {
            return getByFlightNumber(flightNumber);
        } catch (BizException e) {
            return null;
        }
    }
}
