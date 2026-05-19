package com.university.flight.status.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.university.flight.status.entity.FlightStatus;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface FlightStatusMapper extends BaseMapper<FlightStatus> {
}
