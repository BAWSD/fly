package com.university.flight.info.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.university.flight.info.entity.FlightInfo;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface FlightInfoService extends IService<FlightInfo> {

    Page<FlightInfo> queryByCondition(String flightNumber, String departureAirport,
                                      String arrivalAirport, String airline,
                                      String status, LocalDateTime startTime,
                                      LocalDateTime endTime, Integer pageNum, Integer pageSize);

    FlightInfo getByFlightNumber(String flightNumber);

    Boolean updateStatus(String flightNumber, String status);

    Boolean batchUpdateStatus(List<String> flightNumbers, String status);

    Map<String, Long> countByStatus();

    List<FlightInfo> getFlightsByAirportAndTime(String airportCode,
                                                LocalDateTime startTime,
                                                LocalDateTime endTime);

    Boolean addFlight(FlightInfo flightInfo);

    Boolean updateFlight(String flightNumber, FlightInfo flightInfo);

    Boolean deleteFlight(String flightNumber);

    List<FlightInfo> searchFlights(String keyword);
}