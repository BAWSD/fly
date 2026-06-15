package com.university.flight.info.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.university.flight.common.model.Result;
import com.university.flight.info.entity.FlightInfo;
import com.university.flight.info.service.FlightInfoService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotBlank;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Slf4j
@Validated
@RestController
@RequestMapping("/api/flight/info")
public class FlightInfoController {

    @Autowired
    private FlightInfoService flightInfoService;

    @GetMapping("/{flightNumber}")
    public Result<FlightInfo> getFlight(@PathVariable @NotBlank String flightNumber) {
        log.info("查询航班信息: {}", flightNumber);
        FlightInfo flight = flightInfoService.getByFlightNumber(flightNumber);
        return Result.success(flight);
    }

    @GetMapping("/list")
    public Result<Page<FlightInfo>> getFlightList(
            @RequestParam(required = false) String flightNumber,
            @RequestParam(required = false) String departureAirport,
            @RequestParam(required = false) String arrivalAirport,
            @RequestParam(required = false) String airline,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime,
            @RequestParam(defaultValue = "1") @Min(1) Integer pageNum,
            @RequestParam(defaultValue = "20") @Min(1) Integer pageSize) {

        log.info("查询航班列表: flightNumber={}, departureAirport={}, arrivalAirport={}, airline={}, status={}, startTime={}, endTime={}, pageNum={}, pageSize={}",
            flightNumber, departureAirport, arrivalAirport, airline, status, startTime, endTime, pageNum, pageSize);

        Page<FlightInfo> page = flightInfoService.queryByCondition(flightNumber, departureAirport,
            arrivalAirport, airline, status, startTime, endTime, pageNum, pageSize);

        return Result.success(page);
    }

    @PutMapping("/{flightNumber}/status")
    public Result<Boolean> updateFlightStatus(@PathVariable @NotBlank String flightNumber,
                                              @RequestParam @NotBlank String status) {
        log.info("更新航班状态: flightNumber={}, status={}", flightNumber, status);
        Boolean result = flightInfoService.updateStatus(flightNumber, status);
        return Result.success(result);
    }

    @PutMapping("/batch/status")
    public Result<Boolean> batchUpdateFlightStatus(@RequestParam @NotBlank String status,
                                                   @RequestBody List<String> flightNumbers) {
        log.info("批量更新航班状态: status={}, flightNumbers={}", status, flightNumbers);
        Boolean result = flightInfoService.batchUpdateStatus(flightNumbers, status);
        return Result.success(result);
    }

    @GetMapping("/stats/count-by-status")
    public Result<Map<String, Long>> countFlightsByStatus() {
        log.info("按状态统计航班数量");
        Map<String, Long> stats = flightInfoService.countByStatus();
        return Result.success(stats);
    }

    @GetMapping("/airport/{airportCode}")
    public Result<List<FlightInfo>> getFlightsByAirport(
            @PathVariable @NotBlank String airportCode,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime) {

        log.info("查询机场航班: airportCode={}, startTime={}, endTime={}", airportCode, startTime, endTime);

        if (startTime == null) {
            startTime = LocalDateTime.now().minusHours(2);
        }
        if (endTime == null) {
            endTime = LocalDateTime.now().plusHours(6);
        }

        List<FlightInfo> flights = flightInfoService.getFlightsByAirportAndTime(airportCode, startTime, endTime);
        return Result.success(flights);
    }

    @PostMapping
    public Result<Boolean> addFlight(@Valid @RequestBody FlightInfo flightInfo) {
        log.info("添加航班: {}", flightInfo);
        Boolean result = flightInfoService.addFlight(flightInfo);
        return Result.success(result);
    }

    @PutMapping("/{flightNumber}")
    public Result<Boolean> updateFlight(@PathVariable @NotBlank String flightNumber,
                                        @Valid @RequestBody FlightInfo flightInfo) {
        log.info("更新航班: flightNumber={}, flightInfo={}", flightNumber, flightInfo);
        Boolean result = flightInfoService.updateFlight(flightNumber, flightInfo);
        return Result.success(result);
    }

    @DeleteMapping("/{flightNumber}")
    public Result<Boolean> deleteFlight(@PathVariable @NotBlank String flightNumber) {
        log.info("删除航班: {}", flightNumber);
        Boolean result = flightInfoService.deleteFlight(flightNumber);
        return Result.success(result);
    }

    @GetMapping("/search")
    public Result<List<FlightInfo>> searchFlights(@RequestParam(required = false) String keyword) {
        log.info("搜索航班: keyword={}", keyword);
        List<FlightInfo> flights = flightInfoService.searchFlights(keyword);
        return Result.success(flights);
    }
}