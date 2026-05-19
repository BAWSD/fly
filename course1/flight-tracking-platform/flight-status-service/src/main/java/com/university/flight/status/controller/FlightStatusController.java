package com.university.flight.status.controller;

import com.university.flight.common.model.Result;
import com.university.flight.status.entity.FlightStatus;
import com.university.flight.status.service.FlightStatusService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/flight/status")
public class FlightStatusController {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private FlightStatusService flightStatusService;

    @GetMapping("/{flightNumber}/realtime")
    public Result<FlightStatus> getRealTimeStatus(@PathVariable String flightNumber) {
        log.info("获取航班实时状态: {}", flightNumber);
        FlightStatus status = flightStatusService.getLatestStatus(flightNumber);
        return Result.success(status);
    }

    @GetMapping("/{flightNumber}/track")
    public Result<List<FlightStatus>> getFlightTrack(@PathVariable String flightNumber,
                                              @RequestParam(required = false) String startTime,
                                              @RequestParam(required = false) String endTime) {
        log.info("获取航班轨迹: flightNumber={}", flightNumber);
        List<FlightStatus> track = flightStatusService.getFlightTrack(flightNumber, startTime, endTime);
        return Result.success(track);
    }

    @GetMapping("/stats/delay")
    public Result<Map<String, Object>> getDelayStats(@RequestParam(defaultValue = "7") int days) {
        log.info("获取延迟统计: days={}", days);
        Map<String, Object> stats = flightStatusService.getDelayStats(days);
        return Result.success(stats);
    }

    @GetMapping("/active")
    public Result<List<FlightStatus>> getActiveFlights() {
        log.info("获取活跃航班列表");
        List<FlightStatus> flights = flightStatusService.getActiveFlights();
        return Result.success(flights);
    }

    @MessageMapping("/flight.subscribe")
    @SendTo("/topic/flight.updates")
    public FlightStatus subscribeFlight(String flightNumber) {
        log.info("Client subscribed to flight: {}", flightNumber);
        return flightStatusService.getLatestStatus(flightNumber);
    }

    @Scheduled(fixedRate = 10000)
    public void broadcastFlightPositions() {
        List<FlightStatus> activeFlights = flightStatusService.getActiveFlights();
        for (FlightStatus status : activeFlights) {
            simulateMovement(status);
            flightStatusService.updatePosition(status);
            messagingTemplate.convertAndSend("/topic/flight.position." + status.getFlightNumber(), status);
            messagingTemplate.convertAndSend("/topic/flight.positions.all", status);
        }
    }

    private void simulateMovement(FlightStatus status) {
        if (status.getLatitude() != null && status.getLongitude() != null) {
            double lat = status.getLatitude().doubleValue() + (Math.random() * 0.01 - 0.005);
            double lon = status.getLongitude().doubleValue() + (Math.random() * 0.01 - 0.005);
            status.setLatitude(BigDecimal.valueOf(lat));
            status.setLongitude(BigDecimal.valueOf(lon));
        }
    }
}
