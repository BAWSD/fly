package com.university.flight.collector.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.university.flight.collector.entity.CollectedFlightData;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface CollectedFlightDataMapper extends BaseMapper<CollectedFlightData> {
}
