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