<template>
  <div class="airport-map-view">
    <!-- Main Row - Map Controls + Map + Sidebar -->
    <el-row :gutter="20" class="main-row">
      <!-- 地图控制面板 (左侧) -->
      <el-col :xs="24" :md="2">
        <el-card shadow="hover" class="control-card">
          <template #header>
            <div class="card-header"><span>地图控制</span></div>
          </template>
          <div class="control-body">
            <div class="control-section">
              <div class="control-title">状态筛选</div>
              <el-checkbox-group v-model="mapStatusFilter" @change="handleMapFilter">
                <el-checkbox v-for="s in statusOptions" :key="s.value" :label="s.value" size="small">
                  {{ s.label }}
                </el-checkbox>
              </el-checkbox-group>
            </div>
            <div class="control-section">
              <div class="control-title">显示选项</div>
              <el-checkbox v-model="showFlightPath" size="small" @change="handleTogglePath">航线</el-checkbox>
              <el-checkbox v-model="showAirports" size="small" @change="handleToggleAirports">机场</el-checkbox>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 地图 -->
      <el-col :xs="24" :md="16">
        <div class="map-wrapper">
          <el-card shadow="hover" class="main-map-card">
            <template #header>
                <div class="card-header">
                  <span>实时航班追踪与机场监控</span>
                  <div class="header-actions">
                    <el-button size="small" type="primary" @click="refreshAll">
                      <el-icon><Refresh /></el-icon>刷新全部
                    </el-button>
                  </div>
                </div>
            </template>
            <RealTimeMap ref="realTimeMapRef" />
          </el-card>
        </div>
      </el-col>

      <!-- 右侧侧边栏 -->
      <el-col :xs="24" :md="6">
        <el-card shadow="hover" class="sidebar-card">
          <el-tabs v-model="activeTab" class="info-tabs">
            <el-tab-pane label="机场信息" name="airports">
              <div class="airport-panel">
                <AirportView :airports="airports" @select-airport="handleSelectAirport" />
              </div>
            </el-tab-pane>
            <el-tab-pane label="航班列表" name="flights">
              <div class="flight-sidebar">
                <el-input
                  v-model="flightFilter"
                  placeholder="搜索航班..."
                  clearable
                  class="flight-search"
                >
                  <template #prefix>
                    <el-icon><Search /></el-icon>
                  </template>
                </el-input>

                <div class="flight-list-container">
                  <div
                    v-for="flight in filteredFlights"
                    :key="flight.flightNumber"
                    class="flight-item"
                    :class="{ active: selectedFlight?.flightNumber === flight.flightNumber }"
                    @click="selectFlight(flight)"
                  >
                    <div class="flight-header">
                      <span class="flight-number">{{ flight.flightNumber }}</span>
                      <el-tag :type="dateUtils.getFlightStatusColor(flight.flightStatus)" size="small">
                        {{ dateUtils.getFlightStatusText(flight.flightStatus) }}
                      </el-tag>
                    </div>
                    <div class="flight-route">
                      <span class="airport">{{ flight.departureAirportCode }}</span>
                      <el-icon><Right /></el-icon>
                      <span class="airport">{{ flight.arrivalAirportCode }}</span>
                    </div>
                    <div class="flight-time">
                      计划: {{ dateUtils.formatDate(flight.plannedDepartureTime, 'HH:mm') }}
                    </div>
                  </div>

                  <div v-if="filteredFlights.length === 0" class="empty-list">
                    <el-empty description="暂无航班数据" />
                  </div>
                </div>
              </div>
            </el-tab-pane>
            <el-tab-pane label="统计分析" name="stats">
              <div class="stats-container">
                <!-- 状态概览 -->
                <div class="stats-section">
                  <h4>航班状态概览</h4>
                  <div class="status-overview">
                    <div class="status-summary-item" v-for="(item, key) in flightStatusSummary" :key="key">
                      <div class="status-dot" :style="{ background: getStatusColor(key) }"></div>
                      <div class="status-detail">
                        <span class="status-name">{{ getStatusText(key) }}</span>
                        <span class="status-count">{{ item.count }} 架次</span>
                      </div>
                      <div class="status-bar-mini">
                        <div class="bar-fill" :style="{ width: item.percentage + '%', background: getStatusColor(key) }"></div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- 机场流量排名 -->
                <div class="stats-section">
                  <h4>机场流量排名</h4>
                  <div class="airport-traffic">
                    <div
                      v-for="(traffic, index) in airportTraffic"
                      :key="traffic.airport"
                      class="traffic-item"
                    >
                      <div class="traffic-rank">{{ index + 1 }}</div>
                      <div class="traffic-info">
                        <div class="airport-name">{{ traffic.airportName || traffic.airport }}</div>
                        <div class="traffic-count">航班数: {{ traffic.count }}</div>
                      </div>
                      <div class="traffic-bar">
                        <div class="bar-fill" :style="{ width: traffic.percentage + '%' }"></div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- 航线热度 -->
                <div class="stats-section">
                  <h4>热门航线</h4>
                  <div class="hot-routes-list">
                    <div v-for="(route, index) in hotRoutes" :key="index" class="route-item">
                      <div class="route-rank">{{ index + 1 }}</div>
                      <div class="route-info">
                        <div class="route-name">{{ route.route }}</div>
                        <div class="route-count">{{ route.count }} 架次</div>
                      </div>
                    </div>
                    <div v-if="hotRoutes.length === 0" class="empty-hint">暂无航线数据</div>
                  </div>
                </div>

                <!-- 航空公司分布 -->
                <div class="stats-section">
                  <h4>航空公司分布</h4>
                  <div class="airline-stats">
                    <div v-for="(item, index) in airlineStats" :key="index" class="airline-item">
                      <div class="airline-code">{{ item.code }}</div>
                      <div class="airline-bar-track">
                        <div class="bar-fill" :style="{ width: item.percentage + '%' }"></div>
                      </div>
                      <div class="airline-count">{{ item.count }} 架次</div>
                    </div>
                    <div v-if="airlineStats.length === 0" class="empty-hint">暂无航空公司数据</div>
                  </div>
                </div>
              </div>
            </el-tab-pane>
          </el-tabs>
        </el-card>
      </el-col>
    </el-row>

    <!-- Control Panel (Bottom) -->
    <el-row :gutter="20" class="bottom-row">
      <el-col :span="24">
        <el-card shadow="hover" class="control-panel">
          <div class="control-content">
            <div class="control-group">
              <span class="control-label">显示范围:</span>
              <el-select
                v-model="viewRange"
                size="small"
                style="width: 120px;"
                @change="changeViewRange"
              >
                <el-option label="全国范围" value="nationwide" />
                <el-option label="区域范围" value="regional" />
                <el-option label="机场周边" value="airport" />
              </el-select>
            </div>

            <div class="control-group">
              <span class="control-label">刷新间隔:</span>
              <el-select
                v-model="refreshInterval"
                size="small"
                style="width: 120px;"
                @change="changeRefreshInterval"
              >
                <el-option label="5秒" :value="5" />
                <el-option label="10秒" :value="10" />
                <el-option label="30秒" :value="30" />
                <el-option label="1分钟" :value="60" />
                <el-option label="不自动刷新" :value="0" />
              </el-select>
            </div>

            <div class="control-group">
              <el-button size="small" type="primary" @click="refreshAll">
                <el-icon><Refresh /></el-icon>刷新全部
              </el-button>
            </div>

          </div>
        </el-card>
      </el-col>
    </el-row>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Refresh, Search, Right } from '@element-plus/icons-vue'
import { flightApi, statusApi } from '@/api'
import { dateUtils } from '@/utils/date'
import RealTimeMap from '@/components/map/RealTimeMap.vue'
import AirportView from '@/components/map/AirportView.vue'

const route = useRoute()
const realTimeMapRef = ref()

const activeTab = ref('flights')
const flightFilter = ref('')
const selectedFlight = ref(null)

// 地图控制状态
const mapStatusFilter = ref(['IN_AIR', 'DEPARTED', 'ARRIVED'])
const showFlightPath = ref(true)
const showAirports = ref(true)
const mapStyle = ref('normal')
const searchFlightText = ref('')
const statusOptions = [
  { value: 'SCHEDULED', label: '计划中' },
  { value: 'DELAYED', label: '延误' },
  { value: 'IN_AIR', label: '飞行中' },
  { value: 'DEPARTED', label: '已起飞' },
  { value: 'ARRIVED', label: '已到达' },
  { value: 'CANCELLED', label: '已取消' }
]

const viewRange = ref('nationwide')
const refreshInterval = ref(10)
const autoCenter = ref(true)

const airports = ref([
  { code: 'PEK', name: '北京首都国际机场', flights: 45, lat: 40.0799, lng: 116.6031 },
  { code: 'PVG', name: '上海浦东国际机场', flights: 38, lat: 31.1443, lng: 121.8083 },
  { code: 'CAN', name: '广州白云国际机场', flights: 32, lat: 23.3924, lng: 113.2988 },
  { code: 'SZX', name: '深圳宝安国际机场', flights: 28, lat: 22.6392, lng: 113.8107 },
  { code: 'CTU', name: '成都双流国际机场', flights: 25, lat: 30.5785, lng: 103.9467 }
])

const flights = ref([])
const flightStats = ref({})
const airportTraffic = ref([])
const hotRoutes = ref([])
const airlineStats = ref([])
let refreshTimer = null

const airportNameMap = {
  PEK: '北京首都', PVG: '上海浦东', SHA: '上海虹桥', CAN: '广州白云',
  SZX: '深圳宝安', CTU: '成都双流', CKG: '重庆江北', XIY: '西安咸阳',
  KMG: '昆明长水', HGH: '杭州萧山', NKG: '南京禄口', HAK: '海口美兰',
  JFK: '纽约肯尼迪', NRT: '东京成田', LAX: '洛杉矶'
}

const getStatusText = (status) => {
  const map = {
    SCHEDULED: '计划中', DELAYED: '延误', BOARDING: '登机中',
    DEPARTED: '已起飞', IN_AIR: '飞行中', LANDED: '已降落',
    ARRIVED: '已到达', CANCELLED: '已取消', ON_TIME: '准点'
  }
  return map[status] || status || '--'
}

const getStatusColor = (status) => {
  const map = {
    SCHEDULED: '#909399', DELAYED: '#E6A23C', BOARDING: '#409EFF',
    DEPARTED: '#409EFF', IN_AIR: '#67C23A', LANDED: '#67C23A',
    ARRIVED: '#67C23A', CANCELLED: '#F56C6C', ON_TIME: '#67C23A'
  }
  return map[status] || '#909399'
}

const flightStatusSummary = computed(() => {
  const map = {}
  flights.value.forEach(f => {
    const s = f.flightStatus || 'UNKNOWN'
    map[s] = (map[s] || 0) + 1
  })
  const total = flights.value.length || 1
  return Object.fromEntries(
    Object.entries(map).map(([k, v]) => [k, { count: v, percentage: Math.round(v / total * 100) }])
  )
})

const filteredFlights = computed(() => {
  if (!flightFilter.value) return flights.value

  const keyword = flightFilter.value.toLowerCase()
  return flights.value.filter(flight =>
    (flight.flightNumber || '').toLowerCase().includes(keyword) ||
    (flight.departureAirportName || '').toLowerCase().includes(keyword) ||
    (flight.arrivalAirportName || '').toLowerCase().includes(keyword) ||
    (flight.airlineName || '').toLowerCase().includes(keyword)
  )
})

const loadFlightData = async () => {
  try {
    const res = await flightApi.getFlightList({ pageSize: 200 })

    flights.value = res.data?.records || []
    calculateFlightStats()
    calculateAirportTraffic()
    calculateHotRoutes()
    calculateAirlineStats()
  } catch (error) {
    console.error('加载航班数据失败:', error)
  }
}

const calculateFlightStats = () => {
  const stats = {}
  flights.value.forEach(flight => {
    const status = flight.flightStatus
    stats[status] = (stats[status] || 0) + 1
  })
  flightStats.value = stats
}

const calculateAirportTraffic = () => {
  const trafficMap = {}

  flights.value.forEach(flight => {
    const depCode = flight.departureAirportCode
    const arrCode = flight.arrivalAirportCode
    if (depCode) {
      if (!trafficMap[depCode]) trafficMap[depCode] = { airport: depCode, airportName: airportNameMap[depCode] || flight.departureAirportName || depCode, count: 0 }
      trafficMap[depCode].count++
    }
    if (arrCode) {
      if (!trafficMap[arrCode]) trafficMap[arrCode] = { airport: arrCode, airportName: airportNameMap[arrCode] || flight.arrivalAirportName || arrCode, count: 0 }
      trafficMap[arrCode].count++
    }
  })

  const maxCount = Math.max(...Object.values(trafficMap).map(t => t.count), 1)
  airportTraffic.value = Object.values(trafficMap)
    .sort((a, b) => b.count - a.count)
    .slice(0, 10)
    .map(item => ({
      ...item,
      percentage: Math.round((item.count / maxCount) * 100)
    }))
}

const calculateHotRoutes = () => {
  const routeMap = {}
  flights.value.forEach(flight => {
    const dep = flight.departureAirportCode || '?'
    const arr = flight.arrivalAirportCode || '?'
    const key = dep + '-' + arr
    if (!routeMap[key]) {
      routeMap[key] = {
        route: (airportNameMap[dep] || dep) + ' → ' + (airportNameMap[arr] || arr),
        count: 0
      }
    }
    routeMap[key].count++
  })
  hotRoutes.value = Object.values(routeMap)
    .sort((a, b) => b.count - a.count)
    .slice(0, 8)
}

const calculateAirlineStats = () => {
  const map = {}
  flights.value.forEach(flight => {
    const code = flight.airlineCode || 'OTHER'
    if (!map[code]) map[code] = { code, name: flight.airlineName || code, count: 0 }
    map[code].count++
  })
  const maxCount = Math.max(...Object.values(map).map(a => a.count), 1)
  airlineStats.value = Object.values(map)
    .sort((a, b) => b.count - a.count)
    .map(item => ({
      ...item,
      percentage: Math.round((item.count / maxCount) * 100)
    }))
}

// 地图控制事件处理
const handleMapFilter = () => {
  if (realTimeMapRef.value?.filterFlights) {
    realTimeMapRef.value.filterFlights(mapStatusFilter.value)
  }
}

const handleTogglePath = (val) => {
  if (realTimeMapRef.value?.toggleFlightPath) {
    realTimeMapRef.value.toggleFlightPath(val)
  }
}

const handleToggleAirports = (val) => {
  if (realTimeMapRef.value?.toggleAirports) {
    realTimeMapRef.value.toggleAirports(val)
  }
}

const handleMapStyleChange = (val) => {
  if (realTimeMapRef.value?.changeMapStyle) {
    realTimeMapRef.value.changeMapStyle(val)
  }
}

const handleSearchFlight = () => {
  if (!searchFlightText.value.trim()) return
  if (realTimeMapRef.value?.searchFlightOnMap) {
    realTimeMapRef.value.searchFlightOnMap(searchFlightText.value)
  }
}

const handleSelectAirport = (airport) => {
  if (realTimeMapRef.value?.centerOnAirport) {
    realTimeMapRef.value.centerOnAirport(airport)
  }
  ElMessage.info(`已定位到 ${airport.name}`)
}

const selectFlight = (flight) => {
  selectedFlight.value = flight

  if (autoCenter.value && realTimeMapRef.value?.focusFlightOnMap) {
    realTimeMapRef.value.focusFlightOnMap(flight.flightNumber)
  }
}

const refreshAll = () => {
  loadFlightData()
  if (realTimeMapRef.value?.refresh) {
    realTimeMapRef.value.refresh()
  }
  ElMessage.success('已刷新数据')
}

const changeViewRange = (range) => {
  if (realTimeMapRef.value?.setViewRange) {
    realTimeMapRef.value.setViewRange(range)
  }
  ElMessage.info(`视图范围已设置为: ${getRangeText(range)}`)
}

const getRangeText = (range) => {
  const texts = {
    nationwide: '全国范围',
    regional: '区域范围',
    airport: '机场周边'
  }
  return texts[range] || range
}

const changeRefreshInterval = (interval) => {
  clearInterval(refreshTimer)

  if (interval > 0) {
    refreshTimer = setInterval(() => {
      loadFlightData()
    }, interval * 1000)
  }

  ElMessage.info(`刷新间隔已设置为: ${interval === 0 ? '不自动刷新' : interval + '秒'}`)
}

const applyInitialMapFilter = (attempt = 0) => {
  if (realTimeMapRef.value?.filterFlights) {
    realTimeMapRef.value.filterFlights(mapStatusFilter.value)
    return
  }
  if (attempt < 10) {
    setTimeout(() => applyInitialMapFilter(attempt + 1), 100)
  }
}

onMounted(() => {
  loadFlightData()
  changeRefreshInterval(refreshInterval.value)
  applyInitialMapFilter()
})

watch(() => route.query.flight, (flightNumber) => {
  if (!flightNumber || !realTimeMapRef.value?.focusFlightOnMap) return
  realTimeMapRef.value.focusFlightOnMap(flightNumber)
  activeTab.value = 'flights'
}, { immediate: true })

onUnmounted(() => {
  clearInterval(refreshTimer)
})
</script>

<style lang="scss" scoped>
.airport-map-view {
  height: calc(100vh - 120px);
  display: flex;
  flex-direction: column;
  overflow: hidden;

  .main-row {
    flex: 1;
    margin-bottom: 10px;
    overflow: hidden;

    .map-wrapper {
      height: 100%;

      .main-map-card {
        height: 100%;

        :deep(.el-card__body) {
          height: calc(100% - 52px);
          padding: 0 !important;
        }
      }
    }

    .control-card {
      height: 100%;

      :deep(.el-card__body) {
        height: calc(100% - 52px);
        overflow-y: auto;
      }

      .control-body {
        display: flex;
        flex-direction: column;
        gap: 16px;

        .control-section {
          .control-title {
            font-size: 12px;
            font-weight: 600;
            color: var(--text-secondary);
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
          }

          .el-checkbox {
            display: flex;
            margin-right: 0;
            margin-bottom: 6px;
          }
        }
      }
    }

    .sidebar-card {
      height: 100%;
      max-height: 600px;

      :deep(.el-card__body) {
        height: calc(100% - 52px);
        max-height: calc(600px - 52px);
        padding: 16px 20px !important;
        overflow: hidden;
      }

      .info-tabs {
        height: 100%;
        display: flex;
        flex-direction: column;

        :deep(.el-tabs__content) {
          flex: 1;
          overflow: hidden;
        }

        :deep(.el-tab-pane) {
          height: 100%;
          overflow: hidden;
        }
      }

      .airport-panel {
        height: 100%;
        overflow-y: auto;

        &::-webkit-scrollbar {
          width: 6px;
        }
        &::-webkit-scrollbar-thumb {
          background: #c4c9d4;
          border-radius: 3px;
        }
      }

      .flight-sidebar {
        height: 100%;
        display: flex;
        flex-direction: column;

        .flight-search {
          margin-bottom: 12px;
          flex-shrink: 0;
        }

        .flight-list-container {
          flex: 1;
          overflow-y: auto;
          padding-right: 4px;

          &::-webkit-scrollbar {
            width: 6px;
          }
          &::-webkit-scrollbar-thumb {
            background: #c4c9d4;
            border-radius: 3px;
          }

          .flight-item {
            padding: 10px 12px;
            border-bottom: 1px solid var(--border-color);
            cursor: pointer;
            transition: background-color 0.2s;
            border-radius: 6px;
            margin-bottom: 4px;

            &:hover {
              background-color: rgba(67, 97, 238, 0.04);
            }

            &.active {
              background-color: rgba(67, 97, 238, 0.08);
              border-left: 3px solid var(--primary-color);
            }

            &:last-child {
              border-bottom: none;
            }

            .flight-header {
              display: flex;
              justify-content: space-between;
              align-items: center;
              margin-bottom: 6px;

              .flight-number {
                font-weight: 700;
                font-size: 15px;
                color: var(--text-primary);
              }
            }

            .flight-route {
              display: flex;
              align-items: center;
              margin-bottom: 4px;

              .airport {
                font-size: 16px;
                font-weight: 700;
                color: var(--primary-color);
              }

              .el-icon {
                margin: 0 8px;
                color: var(--text-secondary);
                font-size: 12px;
              }
            }

            .flight-time {
              font-size: 12px;
              color: var(--text-secondary);
            }
          }

          .empty-list {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 200px;
          }
        }
      }

      .stats-container {
        height: 100%;
        overflow-y: auto;
        padding-right: 6px;

        &::-webkit-scrollbar {
          width: 6px;
        }
        &::-webkit-scrollbar-thumb {
          background: #c4c9d4;
          border-radius: 3px;
        }

        .stats-section {
          margin-bottom: 16px;
          padding-bottom: 12px;
          border-bottom: 1px solid #f0f0f0;

          &:last-child {
            border-bottom: none;
          }

          h4 {
            margin: 0 0 10px 0;
            font-size: 14px;
            color: var(--text-primary);
            font-weight: 600;
          }
        }

        .status-overview {
          .status-summary-item {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 8px;

            .status-dot {
              width: 8px;
              height: 8px;
              border-radius: 50%;
              flex-shrink: 0;
            }

            .status-detail {
              flex: 0 0 100px;
              display: flex;
              flex-direction: column;

              .status-name {
                font-size: 13px;
                font-weight: 500;
              }

              .status-count {
                font-size: 11px;
                color: var(--text-secondary);
              }
            }

            .status-bar-mini {
              flex: 1;
              height: 6px;
              background: #f5f7fa;
              border-radius: 3px;
              overflow: hidden;

              .bar-fill {
                height: 100%;
                border-radius: 3px;
                transition: width 0.5s ease;
              }
            }
          }
        }

        .airport-traffic {
          .traffic-item {
            display: flex;
            align-items: center;
            padding: 6px 0;
            border-bottom: 1px solid var(--border-color);

            &:last-child {
              border-bottom: none;
            }

            .traffic-rank {
              width: 24px;
              height: 24px;
              background: linear-gradient(135deg, var(--primary-color), var(--primary-light));
              color: white;
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              font-weight: 700;
              font-size: 12px;
              margin-right: 8px;
              flex-shrink: 0;
            }

            .traffic-info {
              flex: 1;

              .airport-name {
                font-weight: 600;
                font-size: 13px;
                margin-bottom: 2px;
              }

              .traffic-count {
                font-size: 11px;
                color: var(--text-secondary);
              }
            }

            .traffic-bar {
              width: 80px;
              height: 5px;
              background-color: var(--border-color);
              border-radius: 3px;
              overflow: hidden;

              .bar-fill {
                height: 100%;
                background: linear-gradient(90deg, var(--primary-color), #13c2c2);
                transition: width 0.3s ease;
              }
            }
          }
        }

        .hot-routes-list {
          .route-item {
            display: flex;
            align-items: center;
            padding: 6px 0;
            border-bottom: 1px solid #f5f5f5;

            &:last-child { border-bottom: none; }

            .route-rank {
              width: 22px;
              height: 22px;
              background: #e6f7ff;
              color: var(--primary-color);
              border-radius: 4px;
              display: flex;
              align-items: center;
              justify-content: center;
              font-weight: 700;
              font-size: 11px;
              margin-right: 8px;
              flex-shrink: 0;
            }

            .route-info {
              flex: 1;

              .route-name {
                font-size: 13px;
                font-weight: 500;
              }

              .route-count {
                font-size: 11px;
                color: var(--text-secondary);
              }
            }
          }

          .empty-hint {
            text-align: center;
            color: #c0c4cc;
            font-size: 13px;
            padding: 12px 0;
          }
        }

        .airline-stats {
          .airline-item {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 8px;

            .airline-code {
              width: 32px;
              font-size: 12px;
              font-weight: 700;
              color: var(--primary-color);
              text-align: center;
              flex-shrink: 0;
            }

            .airline-bar-track {
              flex: 1;
              height: 8px;
              background: #f5f7fa;
              border-radius: 4px;
              overflow: hidden;

              .bar-fill {
                height: 100%;
                background: linear-gradient(90deg, #667eea, #764ba2);
                border-radius: 4px;
                transition: width 0.5s ease;
              }
            }

            .airline-count {
              width: 50px;
              font-size: 11px;
              color: var(--text-secondary);
              text-align: right;
              flex-shrink: 0;
            }
          }

          .empty-hint {
            text-align: center;
            color: #c0c4cc;
            font-size: 13px;
            padding: 12px 0;
          }
        }
      }
    }
  }

  .bottom-row {
    margin-bottom: 16px;

    .control-panel {
      .control-content {
        display: flex;
        flex-wrap: wrap;
        gap: 20px;
        align-items: center;

        .control-group {
          display: flex;
          align-items: center;
          gap: 8px;

          .control-label {
            font-size: 13px;
            color: var(--text-secondary);
            white-space: nowrap;
          }
        }
      }
    }
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;

    span {
      font-weight: 600;
      font-size: 15px;
      color: var(--text-primary);
    }

    .header-actions {
      display: flex;
      gap: 8px;
    }
  }
}
</style>
