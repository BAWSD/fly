package com.university.flight.status.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.university.flight.status.entity.FlightStatus;

import java.util.List;
import java.util.Map;

public interface FlightStatusService extends IService<FlightStatus> {

    FlightStatus getLatestStatus(String flightNumber);

    List<FlightStatus> getActiveFlights();

    void updatePosition(FlightStatus flightStatus);

    List<FlightStatus> getFlightStatusByNumbers(List<String> flightNumbers);

    void saveOrUpdateStatus(FlightStatus flightStatus);

    List<FlightStatus> getFlightTrack(String flightNumber, String startTime, String endTime);

    Map<String, Object> getDelayStats(int days);
}
