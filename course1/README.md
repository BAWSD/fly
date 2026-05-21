# 航班信息跟踪平台

面向航班运行监控与态势展示的课程设计项目，提供航班实时状态、轨迹回放、机场分布、统计分析与系统监控等能力。

## 技术栈

- 前端: Vue 3, Vite, Element Plus, Baidu Map WebGL
- 后端: Spring Boot, Spring Cloud Gateway, MyBatis-Plus
- 基础设施: MySQL, Redis, Nacos
- 实时通信: WebSocket (SockJS + STOMP)
- AI 分析服务: Python Flask (可选)

## 架构概览

```
浏览器 (localhost:5173)
	|  /api/* 代理到网关 (18080)
	v
API Gateway
	|-- /api/flight/info/**   -> flight-info-service (8081)
	|-- /api/flight/status/** -> flight-status-service (8082)
	|-- /ws-flight/**         -> flight-status-service (WebSocket)
	|-- /api/airport/**       -> airport-map-service (8083)
	|-- /api/collector/**     -> data-collector-service (8084)
	`-- /api/ai/**            -> ai-analysis-service (5000, 可选)

服务注册与发现: Nacos (8848)
数据存储: MySQL (3306) + Redis (6379)
```

## 功能特性

- 实时航班态势: 航班状态、速度、高度、延误提示
- 航班轨迹: 轨迹线展示与回放
- 机场分布: 机场坐标可视化与信息弹窗
- 航班列表与检索: 过滤、排序、快速定位
- 统计分析与系统监控: 运行概览与监控指标

## 接口文档摘要

网关统一入口: `http://localhost:18080`

- 航班信息服务: `GET /api/flight/info/**`
- 航班状态服务: `GET /api/flight/status/**`
- 机场地图服务: `GET /api/airport/**`
- 数据采集服务: `GET /api/collector/**`
- AI 分析服务(可选): `GET /api/ai/**`

WebSocket:

- 连接地址: `/ws-flight/**`
- 常用主题: `/topic/flight.positions.all`, `/topic/flight.updates`

说明: 实际请求路径以各服务 Controller 为准，可在启动后通过日志或网关路由确认。

## 部署方式

- 本地开发(推荐): 按 [启动流程.md](启动流程.md) 启动 MySQL/Redis/Nacos、导入 `init-all.sql`，再启动后端与前端。
- 一键脚本: 项目根目录 `start.ps1` 可自动完成基础设施、初始化与服务启动。
- 旧版脚本: `flight-tracking-platform/deploy/start-all.ps1` 适用于演示或快速验证。

## 目录结构

```
course1/
	flight-tracking-frontend/    前端项目
	flight-tracking-platform/    后端微服务
	init-all.sql                 一体化初始化脚本
	start.ps1                    一键启动脚本
	启动流程.md                  详细启动说明
```

## 快速开始

1. 按照 [启动流程.md](启动流程.md) 配置数据库密码与百度地图 AK。
2. 启动基础设施 (MySQL/Redis/Nacos)。
3. 执行 [init-all.sql](init-all.sql) 初始化数据库与演示数据。
4. 启动后端微服务与前端。

> 推荐直接参考 [启动流程.md](启动流程.md) 的完整步骤与排错指南。

## 数据初始化

`init-all.sql` 包含建库、建表、演示数据与轨迹数据，支持重复执行且不会重复插入。

## 开发与调试建议

- 后端: 先 `mvn clean install -DskipTests` 再分服务启动。
- 前端: `npm install` 后执行 `npm run dev`。
- WebSocket: 关注 `/ws-flight/**` 与 `/topic/flight.positions.all` 等主题。

## 常见问题

- 端口冲突: 修改服务端 `application.yml` 的 `server.port` 并同步更新网关与前端代理。
- 地图白屏: 检查 `VITE_BAIDU_MAP_AK` 是否配置正确。
- 数据为空: 确认 `init-all.sql` 已导入。

## 许可

课程设计用途，未设置开源许可。
