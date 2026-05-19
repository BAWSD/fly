package com.university.flight.map.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.university.flight.map.entity.AirportInfo;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AirportMapper extends BaseMapper<AirportInfo> {
}
