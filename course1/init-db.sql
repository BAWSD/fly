-- ============================================================
-- 航班信息跟踪平台 —— 数据库完整初始化脚本
-- 用途：新建库 + 新建表 + 插入演示种子数据
-- 执行方式：
--   mysql -u root -p12345678 < init-db.sql
-- 或使用 Docker：
--   Get-Content init-db.sql -Encoding UTF8 | docker exec -i flight-mysql mysql -uroot -p12345678 --default-character-set=utf8mb4
-- ============================================================

-- ============================================================
-- 第一部分：创建数据库（如已存在则跳过）
-- ============================================================
CREATE DATABASE IF NOT EXISTS flight_info CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS flight_status CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS airport_map CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS flight_data CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ============================================================
-- 第二部分：创建表（如已存在则跳过）
-- ============================================================

-- 航班基础信息表（flight_info.flight_info）
USE flight_info;
CREATE TABLE IF NOT EXISTS `flight_info` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `flight_number` varchar(20) NOT NULL COMMENT '航班号，如 CA1234',
  `airline_code` varchar(10) NOT NULL COMMENT '航空公司代码，如 CA',
  `airline_name` varchar(50) NOT NULL COMMENT '航空公司名称',
  `departure_airport_code` varchar(10) NOT NULL COMMENT '出发机场三字码，如 PEK',
  `departure_airport_name` varchar(100) NOT NULL COMMENT '出发机场名称',
  `arrival_airport_code` varchar(10) NOT NULL COMMENT '到达机场三字码，如 SHA',
  `arrival_airport_name` varchar(100) NOT NULL COMMENT '到达机场名称',
  `planned_departure_time` datetime NOT NULL COMMENT '计划起飞时间',
  `planned_arrival_time` datetime NOT NULL COMMENT '计划到达时间',
  `actual_departure_time` datetime DEFAULT NULL COMMENT '实际起飞时间',
  `actual_arrival_time` datetime DEFAULT NULL COMMENT '实际到达时间',
  `aircraft_type` varchar(50) DEFAULT NULL COMMENT '机型，如 A320',
  `flight_status` varchar(20) DEFAULT 'SCHEDULED' COMMENT '航班状态: SCHEDULED, DELAYED, CANCELLED, DEPARTED, ARRIVED',
  `gate` varchar(20) DEFAULT NULL COMMENT '登机口',
  `terminal` varchar(10) DEFAULT NULL COMMENT '航站楼',
  `description` text COMMENT '航班描述',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_flight_number` (`flight_number`),
  KEY `idx_departure_time` (`planned_departure_time`),
  KEY `idx_status` (`flight_status`),
  KEY `idx_departure_airport` (`departure_airport_code`),
  KEY `idx_arrival_airport` (`arrival_airport_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='航班基础信息表';

-- 航班实时状态表（flight_status.flight_status）
USE flight_status;
CREATE TABLE IF NOT EXISTS `flight_status` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `flight_info_id` bigint NOT NULL COMMENT '关联flight_info.id',
  `flight_number` varchar(20) NOT NULL,
  `current_status` varchar(50) NOT NULL COMMENT '当前状态: ON_TIME, DELAYED, BOARDING, DEPARTED, IN_AIR, LANDED, ARRIVED, CANCELLED',
  `delay_minutes` int DEFAULT '0' COMMENT '延误分钟数',
  `current_altitude` int DEFAULT NULL COMMENT '当前海拔(英尺)',
  `current_speed` int DEFAULT NULL COMMENT '当前速度(节)',
  `latitude` decimal(10, 6) DEFAULT NULL COMMENT '当前纬度',
  `longitude` decimal(10, 6) DEFAULT NULL COMMENT '当前经度',
  `last_updated` datetime NOT NULL COMMENT '最后更新时间',
  `description` text COMMENT '状态描述文本，如"流量控制"、"天气原因"',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_flight_number` (`flight_number`),
  KEY `idx_last_updated` (`last_updated`),
  KEY `idx_status` (`current_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='航班实时状态表';

-- 机场信息表（airport_map.airport_info）
USE airport_map;
CREATE TABLE IF NOT EXISTS `airport_info` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `airport_code` varchar(10) NOT NULL COMMENT '机场三字码，如 PEK',
  `airport_name` varchar(100) NOT NULL COMMENT '机场名称',
  `city_name` varchar(50) NOT NULL COMMENT '所在城市',
  `country` varchar(50) NOT NULL COMMENT '所在国家',
  `latitude` decimal(10, 6) DEFAULT NULL COMMENT '纬度',
  `longitude` decimal(10, 6) DEFAULT NULL COMMENT '经度',
  `altitude` int DEFAULT NULL COMMENT '海拔(米)',
  `timezone` varchar(50) DEFAULT NULL COMMENT '时区',
  `website` varchar(200) DEFAULT NULL COMMENT '官网',
  `description` text COMMENT '描述',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_airport_code` (`airport_code`),
  KEY `idx_city` (`city_name`),
  KEY `idx_country` (`country`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='机场信息表';

-- 采集的航班数据表（flight_data.collected_flight_data）
USE flight_data;
CREATE TABLE IF NOT EXISTS `collected_flight_data` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `flight_number` varchar(20) NOT NULL COMMENT '航班号',
  `source` varchar(50) NOT NULL COMMENT '数据来源',
  `raw_data` text COMMENT '原始数据(JSON)',
  `collection_time` datetime NOT NULL COMMENT '采集时间',
  `status` tinyint(1) DEFAULT '0' COMMENT '处理状态: 0-未处理, 1-已处理, 2-处理失败',
  `error_message` text COMMENT '错误信息',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_flight_number` (`flight_number`),
  KEY `idx_collection_time` (`collection_time`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采集的航班数据表';

-- ============================================================
-- 第三部分：插入演示数据（跳过已存在的记录）
-- ============================================================

-- 3.1 航班基础数据
INSERT IGNORE INTO flight_info.flight_info (flight_number, airline_code, airline_name, departure_airport_code, departure_airport_name, arrival_airport_code, arrival_airport_name, planned_departure_time, planned_arrival_time, aircraft_type, flight_status, gate, terminal, description) VALUES
('CA1234', 'CA', '中国国际航空', 'PEK', '北京首都国际机场', 'SHA', '上海虹桥国际机场', '2026-05-18 07:00:00', '2026-05-18 09:15:00', 'A330', 'SCHEDULED', 'B12', 'T3', '京沪快线'),
('MU5678', 'MU', '中国东方航空', 'PVG', '上海浦东国际机场', 'CAN', '广州白云国际机场', '2026-05-18 08:30:00', '2026-05-18 10:45:00', 'B737', 'DELAYED', 'A08', 'T1', '延误30分钟'),
('CZ9012', 'CZ', '中国南方航空', 'CAN', '广州白云国际机场', 'PEK', '北京首都国际机场', '2026-05-18 09:00:00', '2026-05-18 11:50:00', 'A380', 'SCHEDULED', 'C15', 'T2', ''),
('3U8899', '3U', '四川航空', 'CTU', '成都双流国际机场', 'PEK', '北京首都国际机场', '2026-05-18 10:00:00', '2026-05-18 12:40:00', 'A320', 'SCHEDULED', 'D06', 'T1', ''),
('HU7602', 'HU', '海南航空', 'PEK', '北京首都国际机场', 'CAN', '广州白云国际机场', '2026-05-18 11:20:00', '2026-05-18 14:20:00', 'B787', 'IN_AIR', 'B22', 'T1', '飞行中'),
('MU2153', 'MU', '中国东方航空', 'XIY', '西安咸阳国际机场', 'PVG', '上海浦东国际机场', '2026-05-18 12:00:00', '2026-05-18 14:10:00', 'A321', 'SCHEDULED', 'E03', 'T2', ''),
('CA1501', 'CA', '中国国际航空', 'PEK', '北京首都国际机场', 'CTU', '成都双流国际机场', '2026-05-18 13:00:00', '2026-05-18 15:55:00', 'A330', 'DELAYED', 'B08', 'T3', '流量控制延误45分钟'),
('CZ3102', 'CZ', '中国南方航空', 'CAN', '广州白云国际机场', 'CTU', '成都双流国际机场', '2026-05-18 14:00:00', '2026-05-18 16:10:00', 'A320', 'CANCELLED', '', 'T2', '因天气原因取消'),
('3U8633', '3U', '四川航空', 'CTU', '成都双流国际机场', 'CKG', '重庆江北国际机场', '2026-05-18 14:30:00', '2026-05-18 15:20:00', 'A319', 'SCHEDULED', 'D12', 'T1', ''),
('HU7890', 'HU', '海南航空', 'PEK', '北京首都国际机场', 'PVG', '上海浦东国际机场', '2026-05-18 15:00:00', '2026-05-18 17:00:00', 'B787', 'DEPARTED', 'B15', 'T1', '已起飞'),
('CA981', 'CA', '中国国际航空', 'PEK', '北京首都国际机场', 'JFK', '纽约肯尼迪国际机场', '2026-05-18 16:00:00', '2026-05-19 06:00:00', 'B777', 'SCHEDULED', 'E01', 'T3', '国际航线'),
('MU587', 'MU', '中国东方航空', 'PVG', '上海浦东国际机场', 'NRT', '东京成田国际机场', '2026-05-18 17:00:00', '2026-05-18 20:30:00', 'B777', 'SCHEDULED', 'A10', 'T1', '国际航线'),
('CZ327', 'CZ', '中国南方航空', 'CAN', '广州白云国际机场', 'LAX', '洛杉矶国际机场', '2026-05-18 18:00:00', '2026-05-19 02:00:00', 'A350', 'SCHEDULED', 'C18', 'T2', '国际航线'),
('3U8882', '3U', '四川航空', 'CTU', '成都双流国际机场', 'PEK', '北京首都国际机场', '2026-05-18 18:30:00', '2026-05-18 21:10:00', 'A320', 'SCHEDULED', 'D08', 'T1', ''),
('HU482', 'HU', '海南航空', 'HAK', '海口美兰国际机场', 'PEK', '北京首都国际机场', '2026-05-18 19:00:00', '2026-05-18 22:20:00', 'B737', 'SCHEDULED', 'F05', 'T2', ''),
('CA1235', 'CA', '中国国际航空', 'SHA', '上海虹桥国际机场', 'PEK', '北京首都国际机场', '2026-05-18 20:00:00', '2026-05-18 22:15:00', 'A330', 'ARRIVED', '', 'T2', '已到达'),
('MU5679', 'MU', '中国东方航空', 'CAN', '广州白云国际机场', 'PVG', '上海浦东国际机场', '2026-05-18 21:00:00', '2026-05-18 23:10:00', 'B737', 'DEPARTED', 'A12', 'T1', '已起飞'),
('CZ9013', 'CZ', '中国南方航空', 'PEK', '北京首都国际机场', 'CAN', '广州白云国际机场', '2026-05-18 22:00:00', '2026-05-19 00:50:00', 'A380', 'SCHEDULED', 'C10', 'T2', ''),
('HU7603', 'HU', '海南航空', 'PVG', '上海浦东国际机场', 'PEK', '北京首都国际机场', '2026-05-18 22:30:00', '2026-05-19 00:30:00', 'B787', 'IN_AIR', 'A22', 'T1', '飞行中'),
('CA1502', 'CA', '中国国际航空', 'CTU', '成都双流国际机场', 'SHA', '上海虹桥国际机场', '2026-05-18 23:00:00', '2026-05-19 01:30:00', 'A330', 'SCHEDULED', 'D10', 'T1', ''),
('MU8888', 'MU', '中国东方航空', 'PVG', '上海浦东国际机场', 'XIY', '西安咸阳国际机场', '2026-05-18 23:30:00', '2026-05-19 01:40:00', 'A321', 'SCHEDULED', 'A06', 'T1', ''),
('CZ6688', 'CZ', '中国南方航空', 'CAN', '广州白云国际机场', 'HAK', '海口美兰国际机场', '2026-05-18 06:30:00', '2026-05-18 07:50:00', 'A320', 'ARRIVED', '', 'T2', '已到达');

-- 3.2 航班实时状态
INSERT IGNORE INTO flight_status.flight_status (flight_info_id, flight_number, current_status, delay_minutes, current_altitude, current_speed, latitude, longitude, last_updated, description) VALUES
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

-- 3.3 机场信息
INSERT IGNORE INTO airport_map.airport_info (airport_code, airport_name, city_name, country, latitude, longitude, altitude, timezone, website, description) VALUES
('PEK', '北京首都国际机场', '北京', '中国', 40.0799, 116.6031, 36, 'Asia/Shanghai', 'https://www.bcia.com.cn', '中国最大机场之一'),
('SHA', '上海虹桥国际机场', '上海', '中国', 31.1979, 121.3363, 3, 'Asia/Shanghai', 'https://www.shairport.com', '上海主要国内机场'),
('PVG', '上海浦东国际机场', '上海', '中国', 31.1443, 121.8083, 4, 'Asia/Shanghai', 'https://www.shairport.com', '上海主要国际机场'),
('CAN', '广州白云国际机场', '广州', '中国', 23.3924, 113.2988, 15, 'Asia/Shanghai', 'https://www.gbiac.com', '广州主要机场'),
('SZX', '深圳宝安国际机场', '深圳', '中国', 22.6392, 113.8107, 4, 'Asia/Shanghai', 'https://www.szairport.com', '深圳主要机场'),
('CTU', '成都双流国际机场', '成都', '中国', 30.5785, 103.9467, 495, 'Asia/Shanghai', 'https://www.cdairport.com', '成都主要机场'),
('CKG', '重庆江北国际机场', '重庆', '中国', 29.7192, 106.6417, 416, 'Asia/Shanghai', 'https://www.cqa.cn', '重庆主要机场'),
('XIY', '西安咸阳国际机场', '西安', '中国', 34.4471, 108.7516, 479, 'Asia/Shanghai', 'https://www.xxia.com', '西安主要机场'),
('KMG', '昆明长水国际机场', '昆明', '中国', 25.1019, 102.9292, 2103, 'Asia/Shanghai', 'https://www.kmairport.com', '昆明主要机场'),
('HGH', '杭州萧山国际机场', '杭州', '中国', 30.2295, 120.4345, 7, 'Asia/Shanghai', 'https://www.hzairport.com', '杭州主要机场'),
('NKG', '南京禄口国际机场', '南京', '中国', 31.7420, 118.8620, 15, 'Asia/Shanghai', 'https://www.njairport.com.cn', '南京主要机场'),
('HAK', '海口美兰国际机场', '海口', '中国', 19.9349, 110.4590, 23, 'Asia/Shanghai', 'https://www.mlairport.com', '海口主要机场'),
('JFK', '纽约肯尼迪国际机场', '纽约', '美国', 40.6413, -73.7781, 4, 'America/New_York', 'https://www.jfkairport.com', '纽约主要国际机场'),
('NRT', '东京成田国际机场', '东京', '日本', 35.7647, 140.3864, 41, 'Asia/Tokyo', 'https://www.narita-airport.jp', '东京主要国际机场'),
('LAX', '洛杉矶国际机场', '洛杉矶', '美国', 33.9416, -118.4085, 30, 'America/Los_Angeles', 'https://www.flylax.com', '洛杉矶主要机场');

-- ============================================================
-- 完成
-- ============================================================
SELECT '数据库初始化完成！' AS status;
SELECT CONCAT('  flight_info.flight_info: ', COUNT(*), ' 行') FROM flight_info.flight_info;
SELECT CONCAT('  flight_status.flight_status: ', COUNT(*), ' 行') FROM flight_status.flight_status;
SELECT CONCAT('  airport_map.airport_info: ', COUNT(*), ' 行') FROM airport_map.airport_info;
SELECT CONCAT('  flight_data.collected_flight_data: ', COUNT(*), ' 行') FROM flight_data.collected_flight_data;
