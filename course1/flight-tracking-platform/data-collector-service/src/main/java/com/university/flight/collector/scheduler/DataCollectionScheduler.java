package com.university.flight.collector.scheduler;

import com.university.flight.collector.service.DataCollectionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class DataCollectionScheduler {

    @Autowired
    private DataCollectionService dataCollectionService;

    @Value("${collector.enabled:true}")
    private boolean enabled;

    /**
     * 定时采集航班数据
     */
    @Scheduled(fixedRateString = "${collector.interval:30000}")
    public void scheduleDataCollection() {
        if (!enabled) {
            log.debug("数据采集已禁用，跳过执行");
            return;
        }

        log.info("=== 定时数据采集任务开始 ===");
        try {
            dataCollectionService.collectFlightData();
        } catch (Exception e) {
            log.error("定时数据采集任务执行失败", e);
        }
        log.info("=== 定时数据采集任务结束 ===");
    }
}
