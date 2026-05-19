package com.university.flight.map.controller;

import com.university.flight.common.model.Result;
import com.university.flight.map.entity.AirportInfo;
import com.university.flight.map.service.AirportService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.constraints.NotBlank;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/airport")
public class AirportController {

    @Autowired
    private AirportService airportService;

    @GetMapping("/{airportCode}")
    public Result<AirportInfo> getAirport(@PathVariable @NotBlank String airportCode) {
        log.info("查询机场信息: {}", airportCode);
        AirportInfo airport = airportService.getByAirportCode(airportCode);
        return Result.success(airport);
    }

    @GetMapping("/list")
    public Result<List<AirportInfo>> getAllAirports() {
        log.info("查询所有机场列表");
        List<AirportInfo> airports = airportService.getAllAirports();
        return Result.success(airports);
    }

    @GetMapping("/search/city")
    public Result<List<AirportInfo>> searchByCity(@RequestParam String cityName) {
        log.info("按城市搜索机场: {}", cityName);
        List<AirportInfo> airports = airportService.searchByCity(cityName);
        return Result.success(airports);
    }

    @GetMapping("/search/country")
    public Result<List<AirportInfo>> searchByCountry(@RequestParam String country) {
        log.info("按国家搜索机场: {}", country);
        List<AirportInfo> airports = airportService.searchByCountry(country);
        return Result.success(airports);
    }
}
