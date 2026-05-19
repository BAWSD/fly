package com.university.flight.collector.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.university.flight.collector.entity.CollectedFlightData;

public interface DataCollectionService extends IService<CollectedFlightData> {

    /**
     * 执行数据采集任务
     */
    void collectFlightData();

    /**
     * 处理采集到的数据
     */
    void processCollectedData(Long dataId);
}
