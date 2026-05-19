package com.university.flight.status.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("flight_status")
public class FlightStatus {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long flightInfoId;
    private String flightNumber;
    private String currentStatus;
    private Integer delayMinutes;
    private Integer currentAltitude;
    private Integer currentSpeed;

    private BigDecimal latitude;
    private BigDecimal longitude;

    private LocalDateTime lastUpdated;
    private String description;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
}