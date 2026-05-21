<template>
  <div class="dashboard">
    <!-- Stats Row -->
    <el-row :gutter="16" class="stats-row">
      <el-col :xs="12" :sm="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-icon gradient-purple">
              <el-icon :size="24"><Collection /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.totalFlights }}</div>
              <div class="stat-label">总航班数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-icon gradient-pink">
              <el-icon :size="24"><Aim /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.activeFlights }}</div>
              <div class="stat-label">活跃航班</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-icon gradient-orange">
              <el-icon :size="24"><Clock /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.delayedFlights }}</div>
              <div class="stat-label">延误航班</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-icon gradient-blue">
              <el-icon :size="24"><Location /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.airports }}</div>
              <div class="stat-label">监控机场</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Map + Controls + Flight List -->
    <el-row :gutter="16" class="middle-row">
      <!-- Map Controls (left) -->
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

      <!-- Map -->
      <el-col :xs="24" :md="16">
        <el-card shadow="hover" class="map-card">
          <template #header>
            <div class="card-header">
              <span>实时航班追踪地图</span>
              <div class="header-actions">
                <el-button size="small" @click="refreshMap">
                  <el-icon><Refresh /></el-icon>刷新
                </el-button>
              </div>
            </div>
          </template>
          <RealTimeMap
            ref="realTimeMapRef"
            :limitFlights="10"
            :flightNumbers="recentFlightNumbers"
          />
        </el-card>
      </el-col>

      <!-- Flight List (right, reduced width) -->
      <el-col :xs="24" :md="6">
        <el-card shadow="hover" class="flight-list-card">
          <template #header>
            <div class="card-header">
              <span>最新航班动态</span>
              <el-button size="small" @click="loadRecentFlights">
                <el-icon><Refresh /></el-icon>刷新
              </el-button>
            </div>
          </template>
          <el-scrollbar class="flight-list">
            <div v-if="recentFlights.length === 0" class="empty-list">
              <el-empty description="暂无航班数据" :image-size="80" />
            </div>
            <div
              v-for="flight in recentFlights"
              :key="flight.id || flight.flightNumber"
              class="flight-item"
              @click="focusRecentFlight(flight)"
            >
              <div class="flight-header">
                <span class="flight-number">{{ flight.flightNumber }}</span>
                <el-tag :type="dateUtils.getFlightStatusColor(flight.flightStatus)" size="small">
                  {{ dateUtils.getFlightStatusText(flight.flightStatus) }}
                </el-tag>
              </div>
              <div class="flight-route">
                <span class="airport-code">{{ flight.departureAirportCode }}</span>
                <el-icon><Right /></el-icon>
                <span class="airport-code">{{ flight.arrivalAirportCode }}</span>
              </div>
              <div class="flight-time">
                <span>计划: {{ dateUtils.formatDate(flight.plannedDepartureTime, 'HH:mm') }}</span>
                <span v-if="flight.actualDepartureTime">
                  实际: {{ dateUtils.formatDate(flight.actualDepartureTime, 'HH:mm') }}
                </span>
              </div>
            </div>
          </el-scrollbar>
        </el-card>
      </el-col>
    </el-row>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Collection, Aim, Clock, Location, Refresh, Right, Search } from '@element-plus/icons-vue'
import { flightApi } from '@/api'
import { dateUtils } from '@/utils/date'
import RealTimeMap from '@/components/map/RealTimeMap.vue'

const router = useRouter()

const stats = ref({
  totalFlights: 0,
  activeFlights: 0,
  delayedFlights: 0,
  airports: 5
})

const recentFlights = ref([])
const selectedFlight = ref(null)
const realTimeMapRef = ref()

const recentFlightNumbers = computed(() => {
  return recentFlights.value
    .map(flight => flight.flightNumber)
    .filter(Boolean)
})

// Map controls state
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

const loadDashboardData = async () => {
  try {
    const [statsRes, recentRes] = await Promise.all([
      flightApi.getFlightStats(),
      flightApi.getFlightList({ pageSize: 10, sortField: 'planned_departure_time', sortOrder: 'desc' })
    ])

    if (statsRes.data) {
      updateStats(statsRes.data)
    }

    if (recentRes.data) {
      // 只保留最新的10条
      const all = recentRes.data.records || []
      recentFlights.value = all.slice(0, 10)
      if (recentFlights.value.length > 0) {
        selectedFlight.value = recentFlights.value[0]
      }
    }

  } catch (error) {
    console.error('加载仪表板数据失败:', error)
    ElMessage.error('加载仪表板数据失败')
  }
}

const updateStats = (data) => {
  let total = 0
  let delayed = 0

  Object.entries(data || {}).forEach(([status, count]) => {
    total += count
    if (status === 'DELAYED') {
      delayed = count
    }
  })

  stats.value = {
    totalFlights: total,
    delayedFlights: delayed,
    activeFlights: data?.IN_AIR || 0,
    airports: 5
  }
}

const focusRecentFlight = (flight) => {
  selectedFlight.value = flight
  if (realTimeMapRef.value?.focusFlightOnMap) {
    realTimeMapRef.value.focusFlightOnMap(flight.flightNumber)
  }
}

const refreshMap = () => {
  if (realTimeMapRef.value?.refresh) {
    realTimeMapRef.value.refresh()
  }
}

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

const loadRecentFlights = async () => {
  try {
    const res = await flightApi.getFlightList({
      pageSize: 10,
      sortField: 'planned_departure_time',
      sortOrder: 'desc'
    })
    recentFlights.value = res.data?.records || []
    ElMessage.success('航班列表已刷新')
  } catch (error) {
    ElMessage.error('刷新航班列表失败')
  }
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

onMounted(async () => {
  await loadDashboardData()
  applyInitialMapFilter()
})
</script>

<style lang="scss" scoped>
.dashboard {
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;

  .stats-row {
    flex-shrink: 0;
    margin-bottom: 16px;

    .stat-card {
      .stat-content {
        display: flex;
        align-items: center;

        .stat-icon {
          width: 52px;
          height: 52px;
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-right: 16px;
          flex-shrink: 0;

          &.gradient-purple {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          }
          &.gradient-pink {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
          }
          &.gradient-orange {
            background: linear-gradient(135deg, #f6d365 0%, #fda085 100%);
          }
          &.gradient-blue {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
          }

          .el-icon {
            color: white;
          }
        }

        .stat-info {
          .stat-value {
            font-size: 24px;
            font-weight: 700;
            color: var(--text-primary);
            line-height: 1.2;
          }
          .stat-label {
            font-size: 13px;
            color: var(--text-secondary);
            margin-top: 4px;
          }
        }
      }
    }
  }

  .middle-row {
    margin-bottom: 16px;
    flex: 1;
    overflow: hidden;

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

    .map-card {
      height: 100%;

      :deep(.el-card__body) {
        height: calc(100% - 52px);
        padding: 0 !important;
      }
    }

      .flight-list-card {
        height: 100%;
        max-height: 560px;

        :deep(.el-card__body) {
          height: calc(100% - 52px);
          max-height: calc(560px - 52px);
          padding: 16px 20px !important;
          overflow: hidden;
          display: flex;
          flex-direction: column;
        }

        .flight-list {
          flex: 1;
          min-height: 0;
          overflow-y: auto;
          padding-right: 6px;

          &::-webkit-scrollbar {
            width: 6px;
          }

          &::-webkit-scrollbar-thumb {
            background: #c4c9d4;
            border-radius: 3px;
          }

        .empty-list {
          height: 100%;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .flight-item {
          padding: 10px 12px;
          border-bottom: 1px solid var(--border-color);
          cursor: pointer;
          transition: background-color 0.2s;
          border-radius: 8px;
          margin-bottom: 4px;

          &:hover {
            background-color: rgba(67, 97, 238, 0.04);
          }

          &:last-child {
            border-bottom: none;
            margin-bottom: 0;
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

            .airport-code {
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
            display: flex;
            justify-content: space-between;
            font-size: 12px;
            color: var(--text-secondary);
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
  }
}
</style>
