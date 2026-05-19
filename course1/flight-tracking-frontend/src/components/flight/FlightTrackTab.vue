<template>
  <div class="flight-track-tab">
    <el-card shadow="never" class="track-header-card">
      <div class="track-header">
        <div class="track-info">
          <h3>{{ flightNumber }} 飞行轨迹</h3>
          <span class="track-summary" v-if="trackData.length > 0">共 {{ trackData.length }} 个轨迹点</span>
        </div>
        <div class="track-actions">
          <el-button type="primary" @click="loadTrackData" :loading="loading">
            <el-icon><Refresh /></el-icon>刷新轨迹
          </el-button>
          <el-button @click="toggleAnimation" :disabled="trackData.length === 0">
            <el-icon><VideoPlay v-if="!animating" /><VideoPause v-else /></el-icon>
            {{ animating ? '暂停' : '播放' }}动画
          </el-button>
        </div>
      </div>
    </el-card>

    <el-row :gutter="20">
      <el-col :xs="24" :md="16">
        <el-card shadow="never" class="map-card">
          <div class="map-container" ref="mapContainer">
            <div class="map-placeholder" v-if="!mapLoaded">
              <el-icon :size="48"><MapLocation /></el-icon>
              <p>地图加载中...</p>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :md="8">
        <el-card shadow="never" class="track-list-card">
          <template #header><span>轨迹点列表</span></template>
          <div class="track-list" v-if="trackData.length > 0">
            <div v-for="(point, index) in trackData" :key="index" class="track-point" :class="{ active: activePointIndex === index }" @click="focusPoint(index)">
              <div class="point-index">{{ index + 1 }}</div>
              <div class="point-info">
                <div class="point-time">{{ formatTime(point.timestamp) }}</div>
                <div class="point-coords">{{ point.latitude?.toFixed(4) }}, {{ point.longitude?.toFixed(4) }}</div>
                <div class="point-details" v-if="point.currentAltitude || point.currentSpeed">
                  <span v-if="point.currentAltitude">高度: {{ point.currentAltitude }}ft</span>
                  <span v-if="point.currentSpeed">速度: {{ point.currentSpeed }}节</span>
                </div>
              </div>
              <div class="point-status">
                <el-tag size="small" :type="getStatusType(point.currentStatus)">{{ getStatusText(point.currentStatus) }}</el-tag>
              </div>
            </div>
          </div>
          <el-empty v-else description="暂无轨迹数据" />
        </el-card>
        <el-card shadow="never" class="track-stats-card" v-if="trackData.length > 0">
          <template #header><span>轨迹统计</span></template>
          <el-descriptions :column="1" border size="small">
            <el-descriptions-item label="起始时间">{{ formatTime(trackData[0]?.timestamp) }}</el-descriptions-item>
            <el-descriptions-item label="最新时间">{{ formatTime(trackData[trackData.length - 1]?.timestamp) }}</el-descriptions-item>
            <el-descriptions-item label="最高高度">{{ maxAltitude }} ft</el-descriptions-item>
            <el-descriptions-item label="最大速度">{{ maxSpeed }} 节</el-descriptions-item>
            <el-descriptions-item label="状态变化">{{ statusChangeCount }} 次</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh, VideoPlay, VideoPause, MapLocation } from '@element-plus/icons-vue'
import { statusApi } from '@/api'
import { dateUtils } from '@/utils/date'

const props = defineProps({ flightNumber: String })
const loading = ref(false)
const trackData = ref([])
const activePointIndex = ref(-1)
const animating = ref(false)
const mapContainer = ref(null)
const mapLoaded = ref(false)
let map = null
let polyline = null
let markers = []
let animationTimer = null
let BMap = null

const maxAltitude = computed(() => {
  const alts = trackData.value.map(p => p.currentAltitude || 0).filter(a => a > 0)
  return alts.length > 0 ? Math.max(...alts) : 0
})
const maxSpeed = computed(() => {
  const speeds = trackData.value.map(p => p.currentSpeed || 0).filter(s => s > 0)
  return speeds.length > 0 ? Math.max(...speeds) : 0
})
const statusChangeCount = computed(() => {
  let count = 0
  for (let i = 1; i < trackData.value.length; i++) {
    if (trackData.value[i].currentStatus !== trackData.value[i - 1].currentStatus) count++
  }
  return count
})

const formatTime = (timeStr) => {
  if (!timeStr) return '--'
  try { return new Date(timeStr).toLocaleString('zh-CN') } catch { return timeStr }
}
const getStatusType = (status) => {
  const m = { SCHEDULED:'info', DELAYED:'warning', BOARDING:'', DEPARTED:'', IN_AIR:'success', LANDED:'success', ARRIVED:'success', CANCELLED:'danger' }
  return m[status] || 'info'
}
const getStatusText = (status) => {
  const m = { SCHEDULED:'计划中', DELAYED:'延误', BOARDING:'登机中', DEPARTED:'已起飞', IN_AIR:'飞行中', LANDED:'已降落', ARRIVED:'已到达', CANCELLED:'已取消' }
  return m[status] || status || '--'
}

const loadTrackData = async () => {
  if (!props.flightNumber) return
  loading.value = true
  try {
    const res = await statusApi.getFlightTrack(props.flightNumber)
    trackData.value = res.data || []
    if (trackData.value.length > 0) { await nextTick(); renderMap() }
  } catch (error) {
    console.error('加载轨迹数据失败:', error)
    ElMessage.error('加载轨迹数据失败')
  } finally { loading.value = false }
}

const initMap = async () => {
  try {
    const AK = import.meta.env.VITE_BAIDU_MAP_AK
    if (!AK) { mapLoaded.value = true; return }
    BMap = window.BMapGL || window.BMap
    if (!BMap) {
      await new Promise((resolve, reject) => {
        const script = document.createElement('script')
        script.src = `https://api.map.baidu.com/api?v=1.0&type=webgl&ak=${AK}&callback=_bmapInitTrack`
        window._bmapInitTrack = () => { BMap = window.BMapGL; resolve() }
        script.onerror = reject
        document.head.appendChild(script)
      })
    }
    if (mapContainer.value && BMap) {
      map = new BMap.Map(mapContainer.value)
      map.enableScrollWheelZoom(true)
      mapLoaded.value = true
    }
  } catch (e) { console.warn('地图加载失败:', e); mapLoaded.value = true }
}

const renderMap = () => {
  if (!map || !BMap || trackData.value.length === 0) return
  map.clearOverlays()
  markers = []
  const points = trackData.value.filter(p => p.latitude && p.longitude).map(p => new BMap.Point(p.longitude, p.latitude))
  if (points.length === 0) return
  polyline = new BMap.Polyline(points, { strokeColor: '#409EFF', strokeWeight: 4, strokeOpacity: 0.8 })
  map.addOverlay(polyline)
  const startMarker = new BMap.Marker(points[0], { title: '起点' })
  const endMarker = new BMap.Marker(points[points.length - 1], { title: '终点' })
  map.addOverlay(startMarker)
  map.addOverlay(endMarker)
  markers.push(startMarker, endMarker)
  const step = Math.max(1, Math.floor(points.length / 10))
  for (let i = step; i < points.length - 1; i += step) {
    const m = new BMap.Marker(points[i])
    map.addOverlay(m)
    markers.push(m)
  }
  map.setViewport(points)
}

const focusPoint = (index) => {
  activePointIndex.value = index
  const point = trackData.value[index]
  if (map && BMap && point.latitude && point.longitude) {
    map.panTo(new BMap.Point(point.longitude, point.latitude))
  }
}

const toggleAnimation = () => {
  if (animating.value) { clearInterval(animationTimer); animating.value = false; return }
  if (trackData.value.length === 0) return
  animating.value = true
  let idx = 0
  animationTimer = setInterval(() => {
    if (idx >= trackData.value.length) { clearInterval(animationTimer); animating.value = false; return }
    focusPoint(idx)
    idx++
  }, 800)
}

watch(() => props.flightNumber, () => { loadTrackData() })
onMounted(async () => { await initMap(); await loadTrackData() })
onUnmounted(() => { if (animationTimer) clearInterval(animationTimer); if (map) map = null })
</script>

<style lang="scss" scoped>
.flight-track-tab {
  .track-header-card { margin-bottom: 16px;
    .track-header { display: flex; justify-content: space-between; align-items: center;
      .track-info { h3 { margin: 0 0 4px; } .track-summary { color: #909399; font-size: 13px; } }
      .track-actions { display: flex; gap: 8px; }
    }
  }
  .map-card {
    .map-container { height: 500px; border-radius: 8px; overflow: hidden; background: #f5f7fa; position: relative; }
    .map-placeholder { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; color: #909399; }
  }
  .track-list-card { margin-bottom: 16px; }
  .track-list { max-height: 350px; overflow-y: auto; }
  .track-point { display: flex; align-items: center; gap: 10px; padding: 8px 10px; cursor: pointer; border-radius: 6px; transition: background 0.2s;
    &:hover { background: #f5f7fa; } &.active { background: #ecf5ff; }
    .point-index { width: 28px; height: 28px; border-radius: 50%; background: #409EFF; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 12px; flex-shrink: 0; }
    .point-info { flex: 1; .point-time { font-size: 13px; font-weight: 500; } .point-coords { font-size: 12px; color: #909399; } .point-details { font-size: 11px; color: #b0b0b0; span { margin-right: 8px; } } }
    .point-status { flex-shrink: 0; }
  }
  .track-stats-card { margin-bottom: 16px; }
}
</style>

