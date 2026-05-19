<template>
  <div class="flight-status-tab">
    <el-row :gutter="20" class="status-cards">
      <el-col :xs="24" :sm="12" :md="6" :lg="6" :xl="6">
        <el-card shadow="hover" class="status-card" :class="currentStatus">
          <div class="card-content">
            <div class="status-icon">
              <el-icon><Clock /></el-icon>
            </div>
            <div class="status-info">
              <div class="status-value">{{ statusText || '--' }}</div>
              <div class="status-label">当前状态</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6" :lg="6" :xl="6">
        <el-card shadow="hover" class="delay-card">
          <div class="card-content">
            <div class="status-icon">
              <el-icon><Timer /></el-icon>
            </div>
            <div class="status-info">
              <div class="status-value" :class="getDelayClass(realTimeStatus.delayMinutes)">
                {{ realTimeStatus.delayMinutes > 0 ? `+${realTimeStatus.delayMinutes}` : 0 }} 分钟
              </div>
              <div class="status-label">延误时间</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6" :lg="6" :xl="6">
        <el-card shadow="hover" class="altitude-card">
          <div class="card-content">
            <div class="status-icon">
              <el-icon><TrendCharts /></el-icon>
            </div>
            <div class="status-info">
              <div class="status-value">
                {{ realTimeStatus.currentAltitude ? `${realTimeStatus.currentAltitude.toLocaleString()} ft` : '--' }}
              </div>
              <div class="status-label">飞行高度</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6" :lg="6" :xl="6">
        <el-card shadow="hover" class="speed-card">
          <div class="card-content">
            <div class="status-icon">
              <el-icon><Aim /></el-icon>
            </div>
            <div class="status-info">
              <div class="status-value">
                {{ realTimeStatus.currentSpeed ? `${realTimeStatus.currentSpeed} 节` : '--' }}
              </div>
              <div class="status-label">飞行速度</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card shadow="never" class="timeline-card">
      <template #header>
        <div class="timeline-header">
          <span>状态时间线</span>
          <el-button type="primary" link @click="refreshStatus">
            <el-icon><Refresh /></el-icon>刷新
          </el-button>
        </div>
      </template>

      <div class="timeline-container">
        <el-timeline v-if="statusHistory.length > 0">
          <el-timeline-item
            v-for="(item, index) in statusHistory"
            :key="index"
            :timestamp="dateUtils.formatDate(item.timestamp)"
            :type="getTimelineType(item.status)"
            :hollow="index !== 0"
            placement="top"
          >
            <el-card>
              <h4>{{ getStatusText(item.status) }}</h4>
              <p>{{ item.description }}</p>
              <div v-if="item.latitude && item.longitude" class="position-info">
                <el-icon><Location /></el-icon>
                <span>位置: {{ item.latitude.toFixed(4) }}, {{ item.longitude.toFixed(4) }}</span>
              </div>
            </el-card>
          </el-timeline-item>
        </el-timeline>

        <div v-else class="empty-timeline">
          <el-empty description="暂无状态历史记录" />
        </div>
      </div>
    </el-card>

    <el-card shadow="never" class="position-card" v-if="showPosition">
      <template #header>
        <div class="position-header">
          <span>实时位置</span>
          <el-button type="primary" link @click="showOnMap">
            <el-icon><MapLocation /></el-icon>在地图查看
          </el-button>
        </div>
      </template>

      <div class="position-info">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="纬度">
            {{ realTimeStatus.latitude?.toFixed(6) || '--' }}
          </el-descriptions-item>
          <el-descriptions-item label="经度">
            {{ realTimeStatus.longitude?.toFixed(6) || '--' }}
          </el-descriptions-item>
          <el-descriptions-item label="最后更新">
            {{ realTimeStatus.lastUpdated ? dateUtils.formatTimeAgo(realTimeStatus.lastUpdated) : '--' }}
          </el-descriptions-item>
          <el-descriptions-item label="位置状态">
            {{ getPositionStatus() }}
          </el-descriptions-item>
        </el-descriptions>

        <div v-if="showSimpleMap" class="simple-map">
          <div class="map-placeholder">
            <el-icon><LocationInformation /></el-icon>
            <p>实时位置地图展示</p>
            <p>纬度: {{ realTimeStatus.latitude?.toFixed(4) || '--' }}</p>
            <p>经度: {{ realTimeStatus.longitude?.toFixed(4) || '--' }}</p>
          </div>
        </div>
      </div>
    </el-card>

    <el-card shadow="never" class="update-card">
      <template #header>
        <div class="update-header">
          <span>更新航班状态</span>
        </div>
      </template>

      <el-form :model="updateForm" :rules="updateRules" ref="updateFormRef" label-width="100px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="新状态" prop="status">
              <el-select
                v-model="updateForm.status"
                placeholder="选择新状态"
                style="width: 100%"
              >
                <el-option
                  v-for="status in statusOptions"
                  :key="status.value"
                  :label="status.label"
                  :value="status.value"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="延误时间" prop="delayMinutes">
              <el-input-number
                v-model="updateForm.delayMinutes"
                :min="0"
                :max="300"
                style="width: 100%"
                placeholder="延误分钟数"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="状态描述" prop="description">
          <el-input
            v-model="updateForm.description"
            type="textarea"
            :rows="3"
            placeholder="请输入状态描述"
            maxlength="500"
            show-word-limit
          />
        </el-form-item>

        <el-form-item label="AI生成摘要" v-if="updateForm.description.length > 20">
          <div class="ai-summary-section">
            <div v-if="aiSummary" class="summary-content">
              <p><strong>AI摘要:</strong> {{ aiSummary }}</p>
              <el-button
                type="primary"
                size="small"
                @click="applyAISummary"
                :loading="summarizing"
              >
                应用摘要
              </el-button>
            </div>
            <el-button
              v-else
              type="primary"
              link
              @click="generateSummary"
              :loading="summarizing"
            >
              <el-icon><MagicStick /></el-icon>AI生成摘要
            </el-button>
          </div>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="submitUpdate" :loading="updating">
            更新状态
          </el-button>
          <el-button @click="resetForm">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  Clock, Timer, TrendCharts, Aim, Location,
  Refresh, MapLocation, LocationInformation, MagicStick
} from '@element-plus/icons-vue'
import { statusApi, aiApi, flightApi } from '@/api'
import { dateUtils } from '@/utils/date'
import { useWebSocket } from '@/utils/websocket'

const props = defineProps({
  flightNumber: String
})

const emit = defineEmits(['update'])

const router = useRouter()
const { subscribeFlight } = useWebSocket()

const realTimeStatus = ref({})
const statusHistory = ref([])
const loading = ref(false)
const updating = ref(false)
const summarizing = ref(false)
const aiSummary = ref('')
const showSimpleMap = ref(true)

const updateFormRef = ref()
const updateForm = reactive({
  status: '',
  delayMinutes: 0,
  description: ''
})

const statusOptions = [
  { value: 'SCHEDULED', label: '计划中' },
  { value: 'DELAYED', label: '延误' },
  { value: 'BOARDING', label: '登机中' },
  { value: 'DEPARTED', label: '已起飞' },
  { value: 'IN_AIR', label: '飞行中' },
  { value: 'LANDED', label: '已降落' },
  { value: 'ARRIVED', label: '已到达' },
  { value: 'CANCELLED', label: '已取消' }
]

const updateRules = {
  status: [
    { required: true, message: '请选择状态', trigger: 'change' }
  ],
  description: [
    { required: true, message: '请输入描述', trigger: 'blur' },
    { min: 5, message: '描述至少5个字符', trigger: 'blur' }
  ]
}

const currentStatus = computed(() => {
  return realTimeStatus.value.currentStatus?.toLowerCase() || 'scheduled'
})

const statusText = computed(() => {
  return dateUtils.getFlightStatusText(realTimeStatus.value.currentStatus)
})

const showPosition = computed(() => {
  return realTimeStatus.value.latitude && realTimeStatus.value.longitude
})

const loadRealTimeStatus = async () => {
  if (!props.flightNumber) return

  try {
    const res = await statusApi.getRealTimeStatus(props.flightNumber)
    realTimeStatus.value = res.data || {}
    emit('update', res.data)
  } catch (error) {
    console.error('加载实时状态失败:', error)
  }
}

const loadStatusHistory = async () => {
  if (!props.flightNumber) return

  try {
    statusHistory.value = [
      {
        status: 'SCHEDULED',
        description: '航班计划中，开始值机',
        timestamp: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
        latitude: 40.0799,
        longitude: 116.6031
      },
      {
        status: 'BOARDING',
        description: '开始登机，旅客前往登机口',
        timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
        latitude: 40.0799,
        longitude: 116.6031
      },
      {
        status: 'DEPARTED',
        description: '航班已起飞，正在爬升',
        timestamp: new Date(Date.now() - 1.5 * 60 * 60 * 1000).toISOString(),
        latitude: 40.2000,
        longitude: 116.8000
      },
      {
        status: 'IN_AIR',
        description: '正常巡航中',
        timestamp: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
        latitude: 35.5000,
        longitude: 114.2000
      }
    ]
  } catch (error) {
    console.error('加载状态历史失败:', error)
  }
}

const getTimelineType = (status) => {
  const statusMap = {
    SCHEDULED: 'primary',
    DELAYED: 'warning',
    BOARDING: 'info',
    DEPARTED: 'success',
    IN_AIR: 'success',
    LANDED: 'success',
    ARRIVED: 'success',
    CANCELLED: 'danger'
  }
  return statusMap[status] || 'primary'
}

const getStatusText = (status) => {
  return dateUtils.getFlightStatusText(status)
}

const getDelayClass = (delay) => {
  if (!delay || delay <= 0) return 'on-time'
  if (delay <= 30) return 'small-delay'
  if (delay <= 60) return 'medium-delay'
  return 'large-delay'
}

const getPositionStatus = () => {
  if (!realTimeStatus.value.latitude || !realTimeStatus.value.longitude) {
    return '未知'
  }

  const lat = realTimeStatus.value.latitude
  const lng = realTimeStatus.value.longitude

  if (lat > 40 && lat < 42 && lng > 115 && lng < 118) {
    return '北京区域'
  } else if (lat > 30 && lat < 32 && lng > 120 && lng < 122) {
    return '上海区域'
  } else if (lat > 22 && lat < 24 && lng > 112 && lng < 114) {
    return '广州区域'
  } else {
    return '飞行中'
  }
}

const showOnMap = () => {
  if (realTimeStatus.value.latitude && realTimeStatus.value.longitude) {
    router.push({
      name: 'Tracking',
      query: {
        flight: props.flightNumber,
        lat: realTimeStatus.value.latitude,
        lng: realTimeStatus.value.longitude
      }
    })
  }
}

const refreshStatus = async () => {
  loading.value = true
  try {
    await Promise.all([loadRealTimeStatus(), loadStatusHistory()])
    ElMessage.success('状态已刷新')
  } finally {
    loading.value = false
  }
}

const generateSummary = async () => {
  if (!updateForm.description.trim()) {
    ElMessage.warning('请先输入描述内容')
    return
  }

  summarizing.value = true
  try {
    const res = await aiApi.summarizeStatus({ text: updateForm.description })
    aiSummary.value = res.data.ai_summary
  } catch (error) {
    console.error('AI摘要生成失败:', error)
    ElMessage.error('摘要生成失败')
  } finally {
    summarizing.value = false
  }
}

const applyAISummary = () => {
  if (aiSummary.value) {
    updateForm.description = aiSummary.value
    aiSummary.value = ''
    ElMessage.success('已应用AI摘要')
  }
}

const submitUpdate = async () => {
  if (!updateFormRef.value) return

  try {
    await updateFormRef.value.validate()

    updating.value = true

    await flightApi.updateFlightStatus(props.flightNumber, updateForm.status)

    const updateData = {
      currentStatus: updateForm.status,
      delayMinutes: updateForm.delayMinutes,
      description: updateForm.description,
      lastUpdated: new Date().toISOString()
    }

    statusHistory.value.unshift({
      status: updateForm.status,
      description: updateForm.description,
      timestamp: new Date().toISOString(),
      latitude: realTimeStatus.value.latitude,
      longitude: realTimeStatus.value.longitude
    })

    realTimeStatus.value = { ...realTimeStatus.value, ...updateData }
    emit('update', updateData)

    resetForm()

    ElMessage.success('状态更新成功')
  } catch (error) {
    console.error('更新失败:', error)
    if (error instanceof Error) {
      ElMessage.error('表单验证失败')
    } else {
      ElMessage.error('更新失败')
    }
  } finally {
    updating.value = false
  }
}

const resetForm = () => {
  if (updateFormRef.value) {
    updateFormRef.value.resetFields()
  }
  aiSummary.value = ''
  updateForm.delayMinutes = 0
}

let unsubscribe = null
const initWebSocket = async () => {
  try {
    unsubscribe = subscribeFlight(props.flightNumber, (data) => {
      realTimeStatus.value = { ...realTimeStatus.value, ...data }
    })
  } catch (error) {
    console.error('WebSocket连接失败:', error)
  }
}

onMounted(async () => {
  await Promise.all([loadRealTimeStatus(), loadStatusHistory()])
  await initWebSocket()
})

onUnmounted(() => {
  if (unsubscribe && typeof unsubscribe === 'function') {
    unsubscribe()
  }
})
</script>

<style lang="scss" scoped>
.flight-status-tab {
  .status-cards {
    margin-bottom: 20px;

    .status-card, .delay-card, .altitude-card, .speed-card {
      height: 120px;

      .card-content {
        display: flex;
        align-items: center;
        height: 100%;

        .status-icon {
          width: 60px;
          height: 60px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-right: 20px;
          color: white;

          .el-icon {
            font-size: 28px;
          }
        }

        .status-info {
          .status-value {
            font-size: 24px;
            font-weight: bold;
            color: #333;
            line-height: 1.2;
            margin-bottom: 5px;
          }

          .status-label {
            font-size: 14px;
            color: #999;
          }
        }
      }
    }

    .status-card {
      &.scheduled .status-icon { background-color: #1890ff; }
      &.delayed .status-icon { background-color: #faad14; }
      &.boarding .status-icon { background-color: #13c2c2; }
      &.departed .status-icon { background-color: #52c41a; }
      &.in_air .status-icon { background-color: #52c41a; }
      &.landed .status-icon { background-color: #52c41a; }
      &.arrived .status-icon { background-color: #d9d9d9; }
      &.cancelled .status-icon { background-color: #ff4d4f; }
    }

    .delay-card .status-icon { background-color: #faad14; }
    .altitude-card .status-icon { background-color: #13c2c2; }
    .speed-card .status-icon { background-color: #722ed1; }
  }

  .timeline-card {
    margin-bottom: 20px;

    .timeline-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .timeline-container {
      max-height: 400px;
      overflow-y: auto;

      .position-info {
        display: flex;
        align-items: center;
        gap: 5px;
        font-size: 12px;
        color: #666;
        margin-top: 5px;
      }

      .empty-timeline {
        text-align: center;
        padding: 40px 0;
      }
    }
  }

  .position-card {
    margin-bottom: 20px;

    .position-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .simple-map {
      margin-top: 20px;

      .map-placeholder {
        height: 200px;
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        border-radius: 8px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: #666;

        .el-icon {
          font-size: 48px;
          color: #1890ff;
          margin-bottom: 10px;
        }

        p {
          margin: 5px 0;
        }
      }
    }
  }

  .update-card {
    .update-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .ai-summary-section {
      .summary-content {
        padding: 10px;
        background-color: #f5f7fa;
        border-radius: 4px;
        border: 1px solid #e4e7ed;
        margin-bottom: 10px;

        p {
          margin: 0 0 10px 0;
          line-height: 1.5;
        }
      }
    }
  }

  .on-time {
    color: #52c41a;
  }

  .small-delay {
    color: #faad14;
  }

  .medium-delay {
    color: #ff7a45;
  }

  .large-delay {
    color: #ff4d4f;
  }
}
</style>
