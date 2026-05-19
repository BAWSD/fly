package com.university.flight.info.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.university.flight.info.entity.FlightInfo;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface FlightInfoMapper extends BaseMapper<FlightInfo> {
}