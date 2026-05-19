package com.university.flight.map.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("airport_info")
public class AirportInfo {
    @TableId(type = IdType.AUTO)
    private Long id;

    private String airportCode;
    private String airportName;
    private String cityName;
    private String country;

    private BigDecimal latitude;
    private BigDecimal longitude;
    private Integer altitude;

    private String timezone;
    private String website;
    private String description;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;

    @TableLogic
    private Integer deleted;
}
