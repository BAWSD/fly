<template>
  <div class="flight-history-tab">
    <el-card shadow="never" class="history-header-card">
      <div class="history-header">
        <h3>{{ flightNumber }} 历史记录</h3>
        <el-button type="primary" @click="loadHistory" :loading="loading">
          <el-icon><Refresh /></el-icon>刷新
        </el-button>
      </div>
    </el-card>

    <el-row :gutter="20">
      <el-col :xs="24" :md="14">
        <el-card shadow="never" class="timeline-card">
          <template #header><span>状态变更时间线</span></template>
          <div v-if="historyData.length > 0">
            <el-timeline>
              <el-timeline-item
                v-for="(item, index) in historyData"
                :key="index"
                :timestamp="formatTime(item.timestamp || item.updateTime || item.createTime)"
                :type="getTimelineType(item.currentStatus || item.flightStatus)"
                :hollow="index !== 0"
                placement="top"
              >
                <el-card shadow="hover">
                  <div class="timeline-item-content">
                    <div class="status-row">
                      <el-tag :type="getStatusType(item.currentStatus || item.flightStatus)" size="small">
                        {{ getStatusText(item.currentStatus || item.flightStatus) }}
                      </el-tag>
                      <span class="delay-badge" v-if="item.delayMinutes > 0" :class="getDelayClass(item.delayMinutes)">
                        延误 +{{ item.delayMinutes }}分钟
                      </span>
                    </div>
                    <p class="description" v-if="item.description">{{ item.description }}</p>
                    <div class="position-row" v-if="item.latitude && item.longitude">
                      <el-icon><Location /></el-icon>
                      <span>{{ item.latitude?.toFixed(4) }}, {{ item.longitude?.toFixed(4) }}</span>
                    </div>
                    <div class="detail-row" v-if="item.currentAltitude || item.currentSpeed">
                      <span v-if="item.currentAltitude">高度: {{ item.currentAltitude }}ft</span>
                      <span v-if="item.currentSpeed">速度: {{ item.currentSpeed }}节</span>
                    </div>
                  </div>
                </el-card>
              </el-timeline-item>
            </el-timeline>
          </div>
          <el-empty v-else description="暂无历史记录" />
        </el-card>
      </el-col>

      <el-col :xs="24" :md="10">
        <el-card shadow="never" class="summary-card">
          <template #header><span>历史摘要</span></template>
          <el-descriptions :column="1" border size="small" v-if="historyData.length > 0">
            <el-descriptions-item label="记录总数">{{ historyData.length }}</el-descriptions-item>
            <el-descriptions-item label="首次记录">{{ formatTime(historyData[historyData.length-1]?.timestamp || historyData[historyData.length-1]?.createTime) }}</el-descriptions-item>
            <el-descriptions-item label="最近记录">{{ formatTime(historyData[0]?.timestamp || historyData[0]?.updateTime) }}</el-descriptions-item>
            <el-descriptions-item label="延误次数">{{ delayCount }}</el-descriptions-item>
            <el-descriptions-item label="最长延误">{{ maxDelay }}分钟</el-descriptions-item>
            <el-descriptions-item label="平均延误">{{ avgDelay }}分钟</el-descriptions-item>
          </el-descriptions>
          <el-empty v-else description="暂无数据" />
        </el-card>

        <el-card shadow="never" class="status-distribution-card" v-if="historyData.length > 0">
          <template #header><span>状态分布</span></template>
          <div class="status-bars">
            <div v-for="(item, key) in statusDistribution" :key="key" class="status-bar-item">
              <div class="bar-label">{{ getStatusText(key) }}</div>
              <div class="bar-track">
                <div class="bar-fill" :style="{ width: item.percentage + '%', background: getStatusColor(key) }"></div>
              </div>
              <div class="bar-count">{{ item.count }}次 ({{ item.percentage }}%)</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh, Location } from '@element-plus/icons-vue'
import { statusApi } from '@/api'

const props = defineProps({ flightNumber: String })
const loading = ref(false)
const historyData = ref([])

const delayCount = computed(() => historyData.value.filter(h => (h.currentStatus || h.flightStatus) === 'DELAYD' || h.delayMinutes > 0).length)
const maxDelay = computed(() => Math.max(0, ...historyData.value.map(h => h.delayMinutes || 0)))
const avgDelay = computed(() => {
  const delays = historyData.value.map(h => h.delayMinutes || 0).filter(d => d > 0)
  return delays.length > 0 ? Math.round(delays.reduce((a, b) => a + b, 0) / delays.length) : 0
})
const statusDistribution = computed(() => {
  const map = {}
  historyData.value.forEach(h => {
    const s = h.currentStatus || h.flightStatus || 'UNKNOWN'
    map[s] = (map[s] || 0) + 1
  })
  const total = historyData.value.length
  return Object.fromEntries(Object.entries(map).map(([k, v]) => [k, { count: v, percentage: Math.round(v / total * 100) }]))
})

const formatTime = (timeStr) => { if (!timeStr) return '--'; try { return new Date(timeStr).toLocaleString('zh-CN') } catch { return timeStr } }
const getStatusType = (status) => {
  const m = { SCHEDULED:'info', DELAYED:'warning', BOARDING:'', DEPARTED:'', IN_AIR:'success', LANDED:'success', ARRIVED:'success', CANCELLED:'danger' }
  return m[status] || 'info'
}
const getStatusText = (status) => {
  const m = { SCHEDULED:'计划中', DELAYED:'延误', BOARDING:'登机中', DEPARTED:'已起飞', IN_AIR:'飞行中', LANDED:'已降落', ARRIVED:'已到达', CANCELLED:'已取消' }
  return m[status] || status || '--'
}
const getStatusColor = (status) => {
  const m = { SCHEDULED:'#909399', DELAYED:'#E6A23C', BOARDING:'#409EFF', DEPARTED:'#409EFF', IN_AIR:'#67C23A', LANDED:'#67C23A', ARRIVED:'#67C23A', CANCELLED:'#F56C6C' }
  return m[status] || '#909399'
}
const getTimelineType = (status) => {
  const m = { SCHEDULED:'info', DELAYED:'warning', BOARDING:'primary', DEPARTED:'primary', IN_AIR:'success', LANDED:'success', ARRIVED:'success', CANCELLED:'danger' }
  return m[status] || 'info'
}
const getDelayClass = (min) => { if (min >= 60) return 'delay-severe'; if (min >= 30) return 'delay-moderate'; return 'delay-mild' }

const loadHistory = async () => {
  if (!props.flightNumber) return
  loading.value = true
  try {
    const res = await statusApi.getFlightTrack(props.flightNumber)
    historyData.value = (res.data || []).sort((a, b) => {
      const ta = new Date(a.timestamp || a.updateTime || a.createTime).getTime()
      const tb = new Date(b.timestamp || b.updateTime || b.createTime).getTime()
      return tb - ta
    })
  } catch (error) {
    console.error('加载历史记录失败:', error)
    ElMessage.error('加载历史记录失败')
  } finally { loading.value = false }
}

watch(() => props.flightNumber, () => { loadHistory() })
onMounted(() => { loadHistory() })
</script>

<style lang="scss" scoped>
.flight-history-tab {
  .history-header-card { margin-bottom: 16px;
    .history-header { display: flex; justify-content: space-between; align-items: center; h3 { margin: 0; } }
  }
  .timeline-card { margin-bottom: 16px; }
  .timeline-item-content {
    .status-row { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; }
    .delay-badge { font-size: 12px; padding: 2px 8px; border-radius: 4px; font-weight: bold;
      &.delay-mild { background: #fdf6ec; color: #E6A23C; }
      &.delay-moderate { background: #fef0f0; color: #F56C6C; }
      &.delay-severe { background: #fde2e2; color: #c45656; }
    }
    .description { margin: 4px 0; color: #606266; font-size: 13px; }
    .position-row { display: flex; align-items: center; gap: 4px; font-size: 12px; color: #909399; }
    .detail-row { font-size: 12px; color: #b0b0b0; span { margin-right: 12px; } }
  }
  .summary-card { margin-bottom: 16px; }
  .status-distribution-card {
    .status-bars { .status-bar-item { display: flex; align-items: center; gap: 10px; margin-bottom: 10px;
      .bar-label { width: 60px; font-size: 13px; text-align: right; }
      .bar-track { flex: 1; height: 16px; background: #f5f7fa; border-radius: 8px; overflow: hidden;
        .bar-fill { height: 100%; border-radius: 8px; transition: width 0.5s; }
      }
      .bar-count { width: 80px; font-size: 12px; color: #909399; }
    }}
  }
}
</style>

