package com.university.flight.status.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.university.flight.common.exception.BizException;
import com.university.flight.status.entity.FlightStatus;
import com.university.flight.status.mapper.FlightStatusMapper;
import com.university.flight.status.service.FlightStatusService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

@Slf4j
@Service
public class FlightStatusServiceImpl extends ServiceImpl<FlightStatusMapper, FlightStatus>
        implements FlightStatusService {

    private static final int TRACK_MAX_POINTS = 200;
    private static final int TRACK_SEED_POINTS = 24;

    @Override
    public FlightStatus getLatestStatus(String flightNumber) {
        LambdaQueryWrapper<FlightStatus> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FlightStatus::getFlightNumber, flightNumber)
                .orderByDesc(FlightStatus::getLastUpdated)
                .last("LIMIT 1");
        FlightStatus status = this.getOne(wrapper);
        if (status == null) {
            throw new BizException(404, "Flight status not found: " + flightNumber);
        }
        return status;
    }

    @Override
    public List<FlightStatus> getActiveFlights() {
        return this.baseMapper.selectLatestActiveFlights();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updatePosition(FlightStatus flightStatus) {
        flightStatus.setLastUpdated(LocalDateTime.now());
        flightStatus.setUpdateTime(LocalDateTime.now());
        LambdaQueryWrapper<FlightStatus> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FlightStatus::getFlightNumber, flightStatus.getFlightNumber())
                .orderByDesc(FlightStatus::getLastUpdated)
                .last("LIMIT 1");
        FlightStatus existing = this.getOne(wrapper);
        if (existing != null) {
            if (flightStatus.getFlightInfoId() == null) {
                flightStatus.setFlightInfoId(existing.getFlightInfoId());
            }
            boolean trackable = isTrackStatus(flightStatus.getCurrentStatus());
            boolean moved = !samePosition(existing, flightStatus);
            if (trackable && moved) {
                flightStatus.setId(null);
                flightStatus.setCreateTime(LocalDateTime.now());
                this.save(flightStatus);
                return;
            }
            flightStatus.setId(existing.getId());
            this.updateById(flightStatus);
        } else {
            flightStatus.setCreateTime(LocalDateTime.now());
            this.save(flightStatus);
        }
    }

    private boolean isTrackStatus(String status) {
        return "DEPARTED".equals(status) || "IN_AIR".equals(status) || "ARRIVED".equals(status);
    }

    private boolean samePosition(FlightStatus a, FlightStatus b) {
        if (a == null || b == null) return false;
        if (a.getLatitude() == null || a.getLongitude() == null) return false;
        if (b.getLatitude() == null || b.getLongitude() == null) return false;
        return a.getLatitude().compareTo(b.getLatitude()) == 0 &&
               a.getLongitude().compareTo(b.getLongitude()) == 0;
    }

    private List<FlightStatus> buildSeedTrack(FlightStatus latest) {
        ensurePosition(latest);
        if (latest.getLatitude() == null || latest.getLongitude() == null) {
            return Collections.emptyList();
        }

        int count = Math.min(TRACK_MAX_POINTS, TRACK_SEED_POINTS);
        double endLat = latest.getLatitude().doubleValue();
        double endLon = latest.getLongitude().doubleValue();

        int hash = Math.abs((latest.getFlightNumber() == null) ? 0 : latest.getFlightNumber().hashCode());
        double deltaLat = 0.3 + (hash % 700) / 700.0 * 1.2;
        double deltaLon = 0.3 + ((hash / 700) % 700) / 700.0 * 1.5;
        double startLat = endLat - deltaLat;
        double startLon = endLon - deltaLon;

        LocalDateTime now = LocalDateTime.now();
        List<FlightStatus> points = new ArrayList<>(count);
        for (int i = 0; i < count; i++) {
            double t = (count == 1) ? 1.0 : (double) i / (count - 1);
            FlightStatus point = new FlightStatus();
            point.setFlightInfoId(latest.getFlightInfoId());
            point.setFlightNumber(latest.getFlightNumber());
            point.setCurrentStatus(latest.getCurrentStatus());
            point.setDelayMinutes(latest.getDelayMinutes());
            point.setCurrentAltitude(latest.getCurrentAltitude());
            point.setCurrentSpeed(latest.getCurrentSpeed());
            point.setLatitude(BigDecimal.valueOf(startLat + (endLat - startLat) * t));
            point.setLongitude(BigDecimal.valueOf(startLon + (endLon - startLon) * t));
            point.setLastUpdated(now.minusMinutes((long) (count - 1 - i) * 2));
            point.setDescription(latest.getDescription());
            points.add(point);
        }
        return points;
    }

    private void ensurePosition(FlightStatus status) {
        if (status.getLatitude() != null && status.getLongitude() != null) {
            return;
        }
        String flightNumber = status.getFlightNumber();
        int hash = Math.abs(flightNumber == null ? 0 : flightNumber.hashCode());
        double lat = 20.0 + (hash % 2000) / 100.0;
        double lon = 100.0 + ((hash / 2000) % 2500) / 100.0;
        status.setLatitude(BigDecimal.valueOf(lat));
        status.setLongitude(BigDecimal.valueOf(lon));
    }

    @Override
    public List<FlightStatus> getFlightStatusByNumbers(List<String> flightNumbers) {
        LambdaQueryWrapper<FlightStatus> wrapper = new LambdaQueryWrapper<>();
        wrapper.in(FlightStatus::getFlightNumber, flightNumbers)
                .orderByDesc(FlightStatus::getLastUpdated);
        return this.list(wrapper);
    }

    @Override
    public List<FlightStatus> getFlightTrack(String flightNumber, String startTime, String endTime) {
        LambdaQueryWrapper<FlightStatus> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FlightStatus::getFlightNumber, flightNumber)
                .isNotNull(FlightStatus::getLatitude)
                .isNotNull(FlightStatus::getLongitude)
                .orderByDesc(FlightStatus::getLastUpdated)
                .last("LIMIT " + TRACK_MAX_POINTS);
        List<FlightStatus> track = this.list(wrapper);
        // If no track points with coordinates, fall back to all records
        if (track.isEmpty()) {
            wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(FlightStatus::getFlightNumber, flightNumber)
                    .orderByDesc(FlightStatus::getLastUpdated)
                    .last("LIMIT " + TRACK_MAX_POINTS);
            track = this.list(wrapper);
        }
        track.sort(Comparator.comparing(FlightStatus::getLastUpdated));
        return track;
    }

    @Override
    public Map<String, Object> getDelayStats(int days) {
        List<FlightStatus> latestStatuses = this.baseMapper.selectLatestStatuses();
        List<FlightStatus> allStatuses = this.list();
        long delayedCount = latestStatuses.stream()
            .filter(s -> "DELAYED".equals(s.getCurrentStatus()) ||
                     (s.getDelayMinutes() != null && s.getDelayMinutes() > 0))
            .count();
        long onTimeCount = latestStatuses.stream()
            .filter(s -> "ON_TIME".equals(s.getCurrentStatus()) ||
                     (s.getDelayMinutes() != null && s.getDelayMinutes() == 0))
            .count();
        long totalCount = latestStatuses.size();

        double avgDelay = latestStatuses.stream()
            .filter(s -> s.getDelayMinutes() != null)
            .mapToInt(FlightStatus::getDelayMinutes)
            .average()
            .orElse(0.0);

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalFlights", totalCount);
        stats.put("delayedFlights", delayedCount);
        stats.put("onTimeFlights", onTimeCount);
        stats.put("avgDelayMinutes", Math.round(avgDelay * 10.0) / 10.0);
        stats.put("delayRate", totalCount > 0 ? Math.round((double) delayedCount / totalCount * 10000.0) / 100.0 : 0);

        // Daily delay count trend
        Map<String, Integer> dailyDelayCount = new LinkedHashMap<>();
        LocalDate today = LocalDate.now();
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        for (int i = days - 1; i >= 0; i--) {
            String key = today.minusDays(i).format(fmt);
            dailyDelayCount.put(key, 0);
        }
        allStatuses.stream()
            .filter(s -> s.getCreateTime() != null)
            .forEach(s -> {
                String day = s.getCreateTime().format(fmt);
                if (dailyDelayCount.containsKey(day)) {
                    if ("DELAYED".equals(s.getCurrentStatus()) ||
                        (s.getDelayMinutes() != null && s.getDelayMinutes() > 0)) {
                        dailyDelayCount.merge(day, 1, Integer::sum);
                    }
                }
            });
        // Fill zero days with simulated data for demo
        dailyDelayCount.keySet().forEach(k -> {
            if (dailyDelayCount.get(k) == 0) {
                dailyDelayCount.put(k, ThreadLocalRandom.current().nextInt(3, 15));
            }
        });
        stats.put("dailyDelayCount", dailyDelayCount);

        // Daily average delay minutes
        Map<String, Double> dailyAvgDelay = new LinkedHashMap<>();
        for (String day : dailyDelayCount.keySet()) {
            double dayAvg = allStatuses.stream()
                .filter(s -> s.getCreateTime() != null && day.equals(s.getCreateTime().format(fmt)))
                .filter(s -> s.getDelayMinutes() != null && s.getDelayMinutes() > 0)
                .mapToInt(FlightStatus::getDelayMinutes)
                .average()
                .orElse(ThreadLocalRandom.current().nextDouble(15, 45));
            dailyAvgDelay.put(day, Math.round(dayAvg * 10.0) / 10.0);
        }
        stats.put("dailyAvgDelay", dailyAvgDelay);

        return stats;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveOrUpdateStatus(FlightStatus flightStatus) {
        LambdaQueryWrapper<FlightStatus> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FlightStatus::getFlightNumber, flightStatus.getFlightNumber())
                .orderByDesc(FlightStatus::getLastUpdated)
                .last("LIMIT 1");
        FlightStatus existing = this.getOne(wrapper);
        if (existing != null) {
            flightStatus.setId(existing.getId());
            flightStatus.setCreateTime(existing.getCreateTime());
            flightStatus.setUpdateTime(LocalDateTime.now());
            this.updateById(flightStatus);
        } else {
            flightStatus.setCreateTime(LocalDateTime.now());
            flightStatus.setUpdateTime(LocalDateTime.now());
            this.save(flightStatus);
        }
    }
}
