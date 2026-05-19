-- 清空旧状态数据
DELETE FROM flight_status.flight_status;

-- 重新插入航班状态（含轨迹点数据）
INSERT INTO flight_status.flight_status (flight_info_id, flight_number, current_status, delay_minutes, current_altitude, current_speed, latitude, longitude, last_updated, description) VALUES
(1, 'CA1234', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(2, 'MU5678', 'DELAYED', 30, NULL, NULL, NULL, NULL, NOW(), '流量控制'),
(3, 'CZ9012', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(4, '3U8899', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(5, 'HU7602', 'IN_AIR', 0, 35000, 480, 23.1291, 113.2644, NOW(), '飞行中'),
(6, 'MU2153', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(7, 'CA1501', 'DELAYED', 45, NULL, NULL, NULL, NULL, NOW(), '流量控制延误45分钟'),
(8, 'CZ3102', 'CANCELLED', 0, NULL, NULL, NULL, NULL, NOW(), '因天气原因取消'),
(9, '3U8633', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(10, 'HU7890', 'DEPARTED', 0, 28000, 420, 31.2343, 121.4726, NOW(), '已起飞'),
(11, 'CA981', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(12, 'MU587', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(13, 'CZ327', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(14, '3U8882', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(15, 'HU482', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(16, 'CA1235', 'ARRIVED', 0, NULL, NULL, 31.1979, 121.3363, NOW(), '已到达'),
(17, 'MU5679', 'DEPARTED', 0, 15000, 320, 23.3924, 113.2988, NOW(), '已起飞'),
(18, 'CZ9013', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(19, 'HU7603', 'IN_AIR', 0, 32000, 460, 31.2343, 121.4726, NOW(), '飞行中'),
(20, 'CA1502', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(21, 'MU8888', 'ON_TIME', 0, NULL, NULL, NULL, NULL, NOW(), ''),
(22, 'CZ6688', 'ARRIVED', 0, NULL, NULL, 20.0253, 110.3493, NOW(), '已到达');

-- HU7602 飞行轨迹 (PEK->CAN) 5个轨迹点
INSERT INTO flight_status.flight_status (flight_info_id, flight_number, current_status, delay_minutes, current_altitude, current_speed, latitude, longitude, last_updated, description) VALUES
(5, 'HU7602', 'IN_AIR', 0, 5000, 300, 39.5000, 116.8000, DATE_SUB(NOW(), INTERVAL 120 MINUTE), '起飞爬升'),
(5, 'HU7602', 'IN_AIR', 0, 35000, 500, 36.2000, 115.5000, DATE_SUB(NOW(), INTERVAL 90 MINUTE), '巡航中'),
(5, 'HU7602', 'IN_AIR', 0, 36000, 510, 33.0000, 114.2000, DATE_SUB(NOW(), INTERVAL 60 MINUTE), '巡航中'),
(5, 'HU7602', 'IN_AIR', 0, 32000, 470, 28.5000, 113.5000, DATE_SUB(NOW(), INTERVAL 30 MINUTE), '下降阶段'),
(5, 'HU7602', 'IN_AIR', 0, 28000, 420, 25.5000, 113.0000, NOW(), '进近中');

-- HU7890 飞行轨迹 (PEK->PVG) 4个轨迹点
INSERT INTO flight_status.flight_status (flight_info_id, flight_number, current_status, delay_minutes, current_altitude, current_speed, latitude, longitude, last_updated, description) VALUES
(10, 'HU7890', 'DEPARTED', 0, 8000, 350, 38.5000, 117.2000, DATE_SUB(NOW(), INTERVAL 60 MINUTE), '爬升阶段'),
(10, 'HU7890', 'DEPARTED', 0, 33000, 470, 35.0000, 119.0000, DATE_SUB(NOW(), INTERVAL 40 MINUTE), '巡航中'),
(10, 'HU7890', 'DEPARTED', 0, 30000, 450, 32.8000, 120.5000, DATE_SUB(NOW(), INTERVAL 20 MINUTE), '下降阶段'),
(10, 'HU7890', 'DEPARTED', 0, 28000, 420, 31.2343, 121.4726, NOW(), '进近中');

-- HU7603 飞行轨迹 (PVG->PEK) 4个轨迹点
INSERT INTO flight_status.flight_status (flight_info_id, flight_number, current_status, delay_minutes, current_altitude, current_speed, latitude, longitude, last_updated, description) VALUES
(19, 'HU7603', 'IN_AIR', 0, 6000, 320, 31.5000, 121.8000, DATE_SUB(NOW(), INTERVAL 90 MINUTE), '起飞爬升'),
(19, 'HU7603', 'IN_AIR', 0, 35000, 490, 33.5000, 120.0000, DATE_SUB(NOW(), INTERVAL 60 MINUTE), '巡航中'),
(19, 'HU7603', 'IN_AIR', 0, 34000, 480, 36.0000, 118.5000, DATE_SUB(NOW(), INTERVAL 30 MINUTE), '巡航中'),
(19, 'HU7603', 'IN_AIR', 0, 32000, 460, 38.5000, 117.2000, NOW(), '下降阶段');

-- MU5679 飞行轨迹 (CAN->PVG) 3个轨迹点
INSERT INTO flight_status.flight_status (flight_info_id, flight_number, current_status, delay_minutes, current_altitude, current_speed, latitude, longitude, last_updated, description) VALUES
(17, 'MU5679', 'DEPARTED', 0, 10000, 350, 24.0000, 113.5000, DATE_SUB(NOW(), INTERVAL 45 MINUTE), '爬升阶段'),
(17, 'MU5679', 'DEPARTED', 0, 28000, 430, 27.5000, 117.0000, DATE_SUB(NOW(), INTERVAL 20 MINUTE), '巡航中'),
(17, 'MU5679', 'DEPARTED', 0, 15000, 320, 30.0000, 120.0000, NOW(), '下降阶段');

-- CA1235 飞行轨迹 (SHA->PEK) 3个轨迹点
INSERT INTO flight_status.flight_status (flight_info_id, flight_number, current_status, delay_minutes, current_altitude, current_speed, latitude, longitude, last_updated, description) VALUES
(16, 'CA1235', 'ARRIVED', 0, 5000, 280, 32.0000, 120.5000, DATE_SUB(NOW(), INTERVAL 150 MINUTE), '起飞爬升'),
(16, 'CA1235', 'ARRIVED', 0, 35000, 500, 36.5000, 118.0000, DATE_SUB(NOW(), INTERVAL 100 MINUTE), '巡航中'),
(16, 'CA1235', 'ARRIVED', 0, 2000, 200, 39.8000, 116.5000, DATE_SUB(NOW(), INTERVAL 30 MINUTE), '已降落');

-- CZ6688 飞行轨迹 (CAN->HAK) 3个轨迹点
INSERT INTO flight_status.flight_status (flight_info_id, flight_number, current_status, delay_minutes, current_altitude, current_speed, latitude, longitude, last_updated, description) VALUES
(22, 'CZ6688', 'ARRIVED', 0, 5000, 300, 22.5000, 113.5000, DATE_SUB(NOW(), INTERVAL 80 MINUTE), '起飞爬升'),
(22, 'CZ6688', 'ARRIVED', 0, 30000, 450, 21.0000, 112.0000, DATE_SUB(NOW(), INTERVAL 50 MINUTE), '巡航中'),
(22, 'CZ6688', 'ARRIVED', 0, 2000, 180, 20.0253, 110.3493, DATE_SUB(NOW(), INTERVAL 10 MINUTE), '已降落');

-- 为历史数据补充不同天的createTime，使延误趋势图有数据
UPDATE flight_status.flight_status SET create_time = DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 168) HOUR) WHERE create_time IS NULL;
UPDATE flight_status.flight_status SET create_time = NOW() WHERE id <= 22;
