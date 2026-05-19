package com.university.flight.collector.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("collected_flight_data")
public class CollectedFlightData {
    @TableId(type = IdType.AUTO)
    private Long id;

    private String flightNumber;
    private String source;
    private String rawData;

    private LocalDateTime collectionTime;
    private Integer status;
    private String errorMessage;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
}
