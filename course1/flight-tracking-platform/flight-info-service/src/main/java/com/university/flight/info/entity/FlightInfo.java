package com.university.flight.info.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("flight_info")
public class FlightInfo {
    @TableId(type = IdType.AUTO)
    private Long id;

    private String flightNumber;
    private String airlineCode;
    private String airlineName;
    private String departureAirportCode;
    private String departureAirportName;
    private String arrivalAirportCode;
    private String arrivalAirportName;

    private LocalDateTime plannedDepartureTime;
    private LocalDateTime plannedArrivalTime;
    private LocalDateTime actualDepartureTime;
    private LocalDateTime actualArrivalTime;

    private String aircraftType;
    private String flightStatus;
    private String gate;
    private String terminal;
    private String description;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;
}