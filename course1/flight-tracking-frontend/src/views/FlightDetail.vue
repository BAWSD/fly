<template>
  <div class="flight-detail-view">
    <el-card shadow="never" class="breadcrumb-card">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item :to="{ name: 'FlightList' }">航班管理</el-breadcrumb-item>
        <el-breadcrumb-item>航班详情</el-breadcrumb-item>
        <el-breadcrumb-item>{{ flightNumber }}</el-breadcrumb-item>
      </el-breadcrumb>
    </el-card>

    <el-card shadow="never" class="overview-card">
      <div class="overview-content">
        <div class="overview-header">
          <div class="flight-info">
            <h1 class="flight-number">{{ flightData.flightNumber || '--' }}</h1>
            <el-tag
              :type="dateUtils.getFlightStatusColor(flightData.flightStatus)"
              size="large"
              effect="dark"
              class="status-tag"
            >
              {{ dateUtils.getFlightStatusText(flightData.flightStatus) || '--' }}
            </el-tag>
            <div class="airline">
              <el-avatar :size="40" :src="getAirlineLogo(flightData.airlineCode)" />
              <div class="airline-name">
                <div class="name">{{ flightData.airlineName || '--' }}</div>
                <div class="code">{{ flightData.airlineCode || '--' }}</div>
              </div>
            </div>
          </div>

          <div v-if="delayMinutes > 0" class="delay-info">
            <el-alert
              title="航班延误"
              type="warning"
              :description="`延误 ${delayMinutes} 分钟`"
              show-icon
              :closable="false"
            />
          </div>
        </div>

        <div class="action-buttons">
          <el-button type="primary" @click="showOnMap">
            <el-icon><MapLocation /></el-icon>在地图显示
          </el-button>
          <el-button @click="showAIPrediction">
            <el-icon><MagicStick /></el-icon>AI预测分析
          </el-button>
          <el-button type="danger" @click="deleteFlight">
            <el-icon><Delete /></el-icon>删除航班
          </el-button>
        </div>
      </div>
    </el-card>

    <el-tabs v-model="activeTab" class="detail-tabs">
      <el-tab-pane label="航班信息" name="info">
        <FlightInfoTab :flight="flightData" />
      </el-tab-pane>
      <el-tab-pane label="实时状态" name="status">
        <FlightStatusTab :flight-number="flightNumber" @update="handleStatusUpdate" />
      </el-tab-pane>
      <el-tab-pane label="飞行轨迹" name="track">
        <FlightTrackTab :flight-number="flightNumber" />
      </el-tab-pane>
      <el-tab-pane label="AI分析" name="ai">
        <FlightAIAnalysisTab :flight="flightData" />
      </el-tab-pane>
      <el-tab-pane label="历史记录" name="history">
        <FlightHistoryTab :flight-number="flightNumber" />
      </el-tab-pane>
    </el-tabs>

    <AIPredictionDialog
      v-model="aiDialogVisible"
      :flight="flightData"
      @update="handleAIPredictionUpdate"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { MapLocation, MagicStick, Delete } from '@element-plus/icons-vue'
import { flightApi } from '@/api'
import { dateUtils } from '@/utils/date'
import FlightInfoTab from '@/components/flight/FlightInfoTab.vue'
import FlightStatusTab from '@/components/flight/FlightStatusTab.vue'
import FlightTrackTab from '@/components/flight/FlightTrackTab.vue'
import FlightAIAnalysisTab from '@/components/flight/FlightAIAnalysisTab.vue'
import FlightHistoryTab from '@/components/flight/FlightHistoryTab.vue'
import AIPredictionDialog from '@/components/ai/AIPredictionDialog.vue'

const route = useRoute()
const router = useRouter()

const flightNumber = ref(route.params.flightNumber)
const flightData = ref({})
const activeTab = ref('info')
const aiDialogVisible = ref(false)
const loading = ref(false)

const delayMinutes = computed(() => {
  if (!flightData.value.plannedDepartureTime || !flightData.value.actualDepartureTime) {
    return 0
  }
  return dateUtils.calculateDelay(
    flightData.value.plannedDepartureTime,
    flightData.value.actualDepartureTime
  )
})

const airlineColors = {
  CA: { bg: '#1890ff', text: '#fff' },
  MU: { bg: '#e4393c', text: '#fff' },
  CZ: { bg: '#008755', text: '#fff' },
  HU: { bg: '#f15a22', text: '#fff' },
  '3U': { bg: '#003366', text: '#fff' }
}

const getAirlineLogo = (airlineCode) => {
  const fallbackText = encodeURIComponent((airlineCode || 'FL').substring(0, 2))
  const bgColor = (airlineColors[airlineCode]?.bg || '#999').slice(1)
  return `data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='40' height='40'%3E%3Crect width='40' height='40' rx='8' fill='%23${bgColor}'/%3E%3Ctext x='20' y='27' text-anchor='middle' fill='%23fff' font-size='16' font-weight='bold'%3E${fallbackText}%3C/text%3E%3C/svg%3E`
}

const loadFlightData = async () => {
  loading.value = true
  try {
    const res = await flightApi.getFlightDetail(flightNumber.value)
    flightData.value = res.data || {}
  } catch (error) {
    console.error('加载航班数据失败:', error)
    ElMessage.error('航班不存在或加载失败')
    router.push({ name: 'FlightList' })
  } finally {
    loading.value = false
  }
}

const showOnMap = () => {
  router.push({
    name: 'Tracking',
    query: { flight: flightNumber.value }
  })
}

const showAIPrediction = () => {
  aiDialogVisible.value = true
}

const deleteFlight = async () => {
  try {
    await ElMessageBox.confirm(
      `确定要删除航班 ${flightNumber.value} 吗？此操作不可恢复。`,
      '警告',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    await flightApi.deleteFlight(flightNumber.value)
    ElMessage.success('航班删除成功')
    router.push({ name: 'FlightList' })
  } catch (error) {
    console.log('取消删除')
  }
}

const handleStatusUpdate = (newStatus) => {
  flightData.value = { ...flightData.value, ...newStatus }
}

const handleAIPredictionUpdate = () => {
  ElMessage.success('AI预测已更新')
}

onMounted(async () => {
  await loadFlightData()
})
</script>

<style lang="scss" scoped>
.flight-detail-view {
  .breadcrumb-card {
    margin-bottom: 20px;
  }

  .overview-card {
    margin-bottom: 20px;

    .overview-content {
      .overview-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 30px;

        .flight-info {
          display: flex;
          align-items: center;
          gap: 20px;

          .flight-number {
            margin: 0;
            font-size: 32px;
            color: #333;
            font-weight: bold;
          }

          .status-tag {
            font-size: 16px;
            padding: 8px 16px;
          }

          .airline {
            display: flex;
            align-items: center;
            gap: 10px;

            .airline-name {
              .name {
                font-weight: bold;
                font-size: 16px;
                color: #333;
              }

              .code {
                font-size: 12px;
                color: #666;
              }
            }
          }
        }

        .delay-info {
          width: 300px;
        }
      }

      .action-buttons {
        display: flex;
        gap: 10px;
        justify-content: center;
        padding-top: 20px;
        border-top: 1px solid #f0f0f0;
      }
    }
  }

  .detail-tabs {
    :deep(.el-tabs__content) {
      padding: 20px;
    }
  }
}
</style>
