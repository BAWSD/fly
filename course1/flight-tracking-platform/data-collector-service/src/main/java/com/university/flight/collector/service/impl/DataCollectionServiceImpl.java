package com.university.flight.collector.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.university.flight.collector.entity.CollectedFlightData;
import com.university.flight.collector.mapper.CollectedFlightDataMapper;
import com.university.flight.collector.service.DataCollectionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class DataCollectionServiceImpl extends ServiceImpl<CollectedFlightDataMapper, CollectedFlightData>
        implements DataCollectionService {

    @Value("${collector.api-url:https://api.example.com/flights}")
    private String apiUrl;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void collectFlightData() {
        log.info("开始执行数据采集任务，数据源: {}", apiUrl);
        
        try {
            // 模拟从外部 API 采集数据
            List<CollectedFlightData> collectedData = simulateDataCollection();
            
            // 批量保存采集的数据
            if (!collectedData.isEmpty()) {
                this.saveBatch(collectedData);
                log.info("成功采集并保存 {} 条航班数据", collectedData.size());
            }
        } catch (Exception e) {
            log.error("数据采集失败", e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void processCollectedData(Long dataId) {
        CollectedFlightData data = this.getById(dataId);
        if (data == null) {
            log.warn("未找到采集数据: {}", dataId);
            return;
        }

        try {
            log.info("处理采集数据: {}", dataId);
            // TODO: 实现数据处理逻辑，如解析 JSON、转换为标准格式等
            
            data.setStatus(1); // 1-已处理
            this.updateById(data);
        } catch (Exception e) {
            log.error("处理采集数据失败: {}", dataId, e);
            data.setStatus(2); // 2-处理失败
            data.setErrorMessage(e.getMessage());
            this.updateById(data);
        }
    }

    /**
     * 模拟数据采集（实际项目中应该调用真实的外部 API）
     */
    private List<CollectedFlightData> simulateDataCollection() {
        List<CollectedFlightData> dataList = new ArrayList<>();
        
        // 模拟数据
        String[] flightNumbers = {"CA1234", "MU5678", "CZ9012", "HU3456"};
        for (String flightNumber : flightNumbers) {
            CollectedFlightData data = new CollectedFlightData();
            data.setFlightNumber(flightNumber);
            data.setSource("SIMULATED_API");
            data.setRawData("{\"flight\":\"" + flightNumber + "\",\"status\":\"ON_TIME\"}");
            data.setCollectionTime(LocalDateTime.now());
            data.setStatus(0); // 0-未处理
            dataList.add(data);
        }
        
        return dataList;
    }
}
