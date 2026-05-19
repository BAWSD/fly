package com.university.flight.map.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.university.flight.common.exception.BizException;
import com.university.flight.map.entity.AirportInfo;
import com.university.flight.map.mapper.AirportMapper;
import com.university.flight.map.service.AirportService;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
public class AirportServiceImpl extends ServiceImpl<AirportMapper, AirportInfo>
        implements AirportService {

    @Override
    public AirportInfo getByAirportCode(String airportCode) {
        LambdaQueryWrapper<AirportInfo> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(AirportInfo::getAirportCode, airportCode)
                .last("LIMIT 1");
        
        AirportInfo airport = this.getOne(wrapper);
        if (airport == null) {
            throw new BizException(404, "Airport not found: " + airportCode);
        }
        return airport;
    }

    @Override
    public List<AirportInfo> getAllAirports() {
        return this.list();
    }

    @Override
    public List<AirportInfo> searchByCity(String cityName) {
        if (StringUtils.isBlank(cityName)) {
            return this.getAllAirports();
        }
        
        LambdaQueryWrapper<AirportInfo> wrapper = new LambdaQueryWrapper<>();
        wrapper.like(AirportInfo::getCityName, cityName)
                .orderByAsc(AirportInfo::getAirportName);
        return this.list(wrapper);
    }

    @Override
    public List<AirportInfo> searchByCountry(String country) {
        if (StringUtils.isBlank(country)) {
            return this.getAllAirports();
        }
        
        LambdaQueryWrapper<AirportInfo> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(AirportInfo::getCountry, country)
                .orderByAsc(AirportInfo::getAirportName);
        return this.list(wrapper);
    }
}
