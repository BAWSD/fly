<template>
  <div class="real-time-map">
    <div ref="mapContainer" class="map-container"></div>
    <div v-if="selectedFlight" class="flight-info-panel">
      <el-card shadow="never" class="info-card">
        <template #header>
          <div class="info-header">
            <span>航班详情 - {{ selectedFlight.flightNumber }}</span>
            <el-button type="danger" link @click="closeInfoPanel">
              <el-icon><Close /></el-icon>
            </el-button>
          </div>
        </template>

        <div class="flight-details">
          <div class="info-section">
            <h4>基础信息</h4>
            <el-descriptions :column="2" border>
              <el-descriptions-item label="航空公司">{{ selectedFlight.airlineName }}</el-descriptions-item>
              <el-descriptions-item label="机型">{{ selectedFlight.aircraftType || 'N/A' }}</el-descriptions-item>
              <el-descriptions-item label="出发机场">{{ selectedFlight.departureAirportName }}</el-descriptions-item>
              <el-descriptions-item label="到达机场">{{ selectedFlight.arrivalAirportName }}</el-descriptions-item>
              <el-descriptions-item label="计划时间">
                {{ dateUtils.formatDate(selectedFlight.plannedDepartureTime, 'MM-dd HH:mm') }}
              </el-descriptions-item>
              <el-descriptions-item label="实际时间">
                {{ selectedFlight.actualDepartureTime ? dateUtils.formatDate(selectedFlight.actualDepartureTime, 'MM-dd HH:mm') : '--' }}
              </el-descriptions-item>
            </el-descriptions>
          </div>

          <div class="info-section">
            <h4>实时状态</h4>
            <div class="status-info">
              <el-tag :type="getStatusColor(selectedFlight.flightStatus)" size="large">
                {{ getStatusText(selectedFlight.flightStatus) }}
              </el-tag>

              <div v-if="selectedFlight.delayMinutes > 0" class="delay-info">
                <el-icon><Clock /></el-icon>
                <span>延误 {{ selectedFlight.delayMinutes }} 分钟</span>
              </div>

              <div v-if="selectedFlight.currentSpeed" class="speed-info">
                <el-icon><Aim /></el-icon>
                <span>速度 {{ selectedFlight.currentSpeed }} 节</span>
              </div>

              <div v-if="selectedFlight.currentAltitude" class="altitude-info">
                <el-icon><TrendCharts /></el-icon>
                <span>高度 {{ selectedFlight.currentAltitude }} 英尺</span>
              </div>
            </div>
          </div>

          <div v-if="selectedFlight.latitude && selectedFlight.longitude" class="info-section">
            <h4>当前位置</h4>
            <div class="position-info">
              <div>纬度: {{ selectedFlight.latitude.toFixed(4) }}</div>
              <div>经度: {{ selectedFlight.longitude.toFixed(4) }}</div>
              <div>最后更新: {{ dateUtils.formatTimeAgo(selectedFlight.lastUpdated) }}</div>
            </div>
          </div>

          <div class="action-buttons">
            <el-button type="primary" @click="viewFlightDetail">
              <el-icon><View /></el-icon>查看详情
            </el-button>
            <el-button v-if="!currentTrackFlightNumber || currentTrackFlightNumber !== selectedFlight?.flightNumber" @click="showFlightTrack">
              <el-icon><TrendCharts /></el-icon>查看轨迹
            </el-button>
            <el-button v-else type="warning" @click="hideFlightTrack">
              <el-icon><TrendCharts /></el-icon>隐藏轨迹
            </el-button>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'

// 当 limitFlights > 0 时，地图只显示最新的 N 条航班（按 lastUpdated 排序）
const props = defineProps({
  limitFlights: { type: Number, default: 0 },
  flightNumbers: { type: Array, default: () => [] }
})
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  Search, Close, View, Aim, TrendCharts,
  Clock, Expand
} from '@element-plus/icons-vue'
import { dateUtils } from '@/utils/date'
import { useWebSocket } from '@/utils/websocket'
import { flightApi, statusApi } from '@/api'

const router = useRouter()
const { subscribeAllFlights, subscribeFlightUpdates, connectWebSocket } = useWebSocket()

const mapContainer = ref(null)
let map = null
let BMap = null
let BMapGL = null
let trafficLayer = null

const flightMarkers = new Map()
const airportMarkers = new Map()
const flightPaths = new Map()
const trackOverlays = []  // 存储当前显示的轨迹 overlay，用于清除
const currentTrackFlightNumber = ref('')
const selectedStatus = ref(['IN_AIR', 'DEPARTED', 'DELAYED'])
const selectedFlight = ref(null)
const focusedFlightNumber = ref('')
const mapReady = ref(false)
const showFlightPath = ref(true)
const showAirports = ref(true)
const showWeather = ref(false)
const mapStyle = ref('normal')
const searchFlight = ref('')

const statusOptions = [
  { value: 'SCHEDULED', label: '计划中' },
  { value: 'DELAYED', label: '延误' },
  { value: 'IN_AIR', label: '飞行中' },
  { value: 'DEPARTED', label: '已起飞' },
  { value: 'ARRIVED', label: '已到达' },
  { value: 'CANCELLED', label: '已取消' }
]

const statusColors = {
  SCHEDULED: '#1890ff',
  DELAYED: '#faad14',
  IN_AIR: '#52c41a',
  DEPARTED: '#52c41a',
  ARRIVED: '#d9d9d9',
  CANCELLED: '#ff4d4f'
}

const isFlightAllowed = (flightNumber) => {
  if (!props.flightNumbers || props.flightNumbers.length === 0) return true
  const normalized = String(flightNumber || '').toUpperCase()
  return props.flightNumbers.some(item => String(item || '').toUpperCase() === normalized)
}

const normalizeFlightData = (flight) => {
  if (!flight) return null
  const flightNumber = flight.flightNumber || flight.flight_number || flight.number
  const latitude = flight.latitude ?? flight.lat
  const longitude = flight.longitude ?? flight.lng
  // 状态优先级: flight_status.current_status > flight_flightStatus > flight.status > flight.current_status
  // flight_info 中的 status 是静态旧数据，flight_status 中的 current_status 才是实时状态
  const flightStatus = flight.currentStatus || flight.current_status || flight.flightStatus || flight.status
  return {
    ...flight,
    flightNumber: flightNumber ? String(flightNumber).toUpperCase() : flightNumber,
    latitude,
    longitude,
    flightStatus
  }
}

const loadBaiduMap = () => {
  return new Promise((resolve, reject) => {
    if (window.BMap && window.BMapGL) {
      BMap = window.BMap
      BMapGL = window.BMapGL
      resolve()
      return
    }

    const script = document.createElement('script')
    script.src = `https://api.map.baidu.com/api?type=webgl&v=1.0&ak=${import.meta.env.VITE_BAIDU_MAP_AK}&callback=baiduMapCallback`
    script.onerror = reject

    window.baiduMapCallback = () => {
      BMap = window.BMap
      BMapGL = window.BMapGL
      resolve()
    }

    document.head.appendChild(script)
  })
}

const initMap = async () => {
  try {
    await loadBaiduMap()

    if (!mapContainer.value) return

    map = new BMapGL.Map(mapContainer.value)

    const point = new BMapGL.Point(116.404, 39.915)
    map.centerAndZoom(point, 5)

    map.enableScrollWheelZoom(true)

    map.addControl(new BMapGL.ZoomControl())
    map.addControl(new BMapGL.ScaleControl())
    map.addControl(new BMapGL.NavigationControl3D())
    map.addControl(new BMapGL.MapTypeControl())

    changeMapStyle('normal')

    await loadInitialFlights()
    await initWebSocket()

    if (showAirports.value) {
      loadAirports()
    }

    window.addEventListener('resize', handleResize)

    mapReady.value = true
    if (focusedFlightNumber.value) {
      focusFlightOnMap(focusedFlightNumber.value)
    }

    ElMessage.success('地图加载成功')
  } catch (error) {
    console.error('地图加载失败:', error)
    ElMessage.error('地图加载失败，请检查API密钥')
  }
}

const loadInitialFlights = async (statusList) => {
  try {
    if (statusList) {
      selectedStatus.value = statusList
    }
    
    // 清除旧标记、标签和旧航线，防止叠加
    flightMarkers.forEach(({ marker, label }) => {
      map.removeOverlay(marker)
      if (label) map.removeOverlay(label)
    })
    flightMarkers.clear()
    flightPaths.forEach(polyline => map.removeOverlay(polyline))
    flightPaths.clear()
    
    // 加载所有航班信息（含无坐标的航班基础信息）
    const infoRes = await flightApi.getFlightList({ pageSize: 200 })
    const allFlights = infoRes.data?.records || []
    
    // 从 flight_status 表加载所有有坐标的状态记录
    // 通过 getActiveFlights 获取（数据库中含坐标的 IN_AIR/DEPARTED）
    const activeRes = await statusApi.getActiveFlights()
    const allStatusRecords = [...(activeRes.data || [])]
    
    // 尝试为所有航班获取实时状态
    const enrichedFlights = []
    for (const flight of allFlights) {
      const enriched = { ...flight }
      
      // 从活跃航班列表中找到对应记录（取最新一条，去重）
      const status = allStatusRecords
        .filter(s => (s.flightNumber || s.flight_number) === flight.flightNumber && (s.latitude || s.longitude))
        .sort((a, b) => new Date(b.lastUpdated || 0) - new Date(a.lastUpdated || 0))[0]
      
      if (status) {
        enriched.latitude = status.latitude ?? status.lat
        enriched.longitude = status.longitude ?? status.lng
        enriched.currentStatus = status.currentStatus || status.current_status || enriched.flightStatus
        enriched.currentSpeed = status.currentSpeed || status.current_speed
        enriched.currentAltitude = status.currentAltitude || status.current_altitude
        enriched.delayMinutes = status.delayMinutes || status.delay_minutes
        enriched.lastUpdated = status.lastUpdated || status.last_updated
      }
      
      // 尝试通过 statusApi.getRealTimeStatus 直接查询（能拿到 DELAYED/ARRIVED 等非活跃航班的坐标）
      if (!enriched.latitude) {
        try {
          const rtRes = await statusApi.getRealTimeStatus(flight.flightNumber)
          const rt = rtRes.data
          if (rt && (rt.latitude || rt.lat)) {
            enriched.latitude = rt.latitude ?? rt.lat
            enriched.longitude = rt.longitude ?? rt.lng
            enriched.currentStatus = rt.currentStatus || rt.current_status || enriched.flightStatus
            enriched.currentSpeed = rt.currentSpeed || rt.current_speed
            enriched.currentAltitude = rt.currentAltitude || rt.current_altitude
            enriched.delayMinutes = rt.delayMinutes || rt.delay_minutes
          }
        } catch (e) {
          // 跳过无实时状态的航班
        }
      }
      
      enrichedFlights.push(enriched)
    }
    
    // 按最后更新时间排序（最新的在前）
    let displayable = enrichedFlights
      .map(raw => normalizeFlightData(raw))
      .filter(f => f && f.latitude && f.longitude && shouldShowFlight(f))
      .sort((a, b) => {
        const ta = a.lastUpdated || a.plannedDepartureTime || ''
        const tb = b.lastUpdated || b.plannedDepartureTime || ''
        return tb.localeCompare(ta)
      })

    if (props.flightNumbers && props.flightNumbers.length > 0) {
      displayable = displayable.filter(f => isFlightAllowed(f.flightNumber))
    }
    
    // 如果设置了 limitFlights，只保留最新的 N 条
    if (props.limitFlights > 0) {
      displayable = displayable.slice(0, props.limitFlights)
    }
    
    displayable.forEach(flight => {
      addFlightMarker(flight)
    })
    
    // 统计加载成功数量
    const shown = enrichedFlights.filter(f => f.latitude && f.longitude).length
    console.log(`地图已加载 ${shown} 个有坐标的航班`)
  } catch (error) {
    console.error('加载航班数据失败:', error)
  }
}

const initWebSocket = async () => {
  try {
    await connectWebSocket()

    subscribeAllFlights(handleFlightUpdate)
    subscribeFlightUpdates(handleStatusUpdate)
  } catch (error) {
    console.error('WebSocket连接失败:', error)
  }
}

const handleFlightUpdate = (flightData) => {
  const normalized = normalizeFlightData(flightData)
  if (!normalized) return
  if (!isFlightAllowed(normalized.flightNumber)) {
    const existing = flightMarkers.get(normalized.flightNumber)
    if (existing) {
      map.removeOverlay(existing.marker)
      if (existing.label) map.removeOverlay(existing.label)
      flightMarkers.delete(normalized.flightNumber)
    }
    return
  }
  const entry = flightMarkers.get(normalized.flightNumber)

  if (entry) {
    const newPoint = new BMapGL.Point(
      normalized.longitude,
      normalized.latitude
    )

    entry.marker.setPosition(newPoint)
    updateMarkerInfo(entry, normalized)

    if (selectedFlight.value?.flightNumber === normalized.flightNumber) {
      selectedFlight.value = { ...selectedFlight.value, ...normalized }
    }
  } else {
    addFlightMarker(normalized)
  }
}

const handleStatusUpdate = (flightData) => {
  const normalized = normalizeFlightData(flightData)
  if (!normalized) return
  const marker = flightMarkers.get(normalized.flightNumber)
  if (marker) {
    updateMarkerStyle(marker, normalized.flightStatus)
  }
}

const addFlightMarker = (flightData, force = false) => {
  if (!force && !shouldShowFlight(flightData)) return
  if (!flightData.latitude || !flightData.longitude) return
  if (flightData.latitude === 0 && flightData.longitude === 0) return

  const normalizedNumber = String(flightData.flightNumber || '').toUpperCase()
  if (!normalizedNumber) return

  const existing = flightMarkers.get(normalizedNumber)
  if (existing) {
    map.removeOverlay(existing.marker)
    if (existing.label) map.removeOverlay(existing.label)
    flightMarkers.delete(normalizedNumber)
  }

  const point = new BMapGL.Point(
    flightData.longitude,
    flightData.latitude
  )

  // 使用紫色圆点图标（与红色图钉的机场标记区分）— 细版
  const size = 16
  const canvas = document.createElement('canvas')
  canvas.width = size
  canvas.height = size
  const ctx = canvas.getContext('2d')
  // 外圈紫色
  ctx.beginPath()
  ctx.arc(size / 2, size / 2, size / 2 - 0.5, 0, Math.PI * 2)
  ctx.fillStyle = '#722ed1'
  ctx.fill()
  ctx.strokeStyle = '#ffffff'
  ctx.lineWidth = 1.2
  ctx.stroke()
  // 中心白点
  ctx.beginPath()
  ctx.arc(size / 2, size / 2, size / 8, 0, Math.PI * 2)
  ctx.fillStyle = '#ffffff'
  ctx.fill()

  const icon = new BMapGL.Icon(canvas.toDataURL('image/png'), new BMapGL.Size(size, size), {
    anchor: new BMapGL.Size(size / 2, size / 2),
    imageSize: new BMapGL.Size(size, size)
  })

  const marker = new BMapGL.Marker(point, {
    icon: icon,
    rotation: 0,
    title: normalizedNumber
  })

  map.addOverlay(marker)

  // 添加彩色标签显示航班号
  const color = statusColors[flightData.flightStatus] || '#1890ff'
  const label = new BMapGL.Label(normalizedNumber, {
    position: point,
    offset: new BMapGL.Size(-30, 14)
  })
  label.setStyle({
    color: '#fff',
    fontSize: '11px',
    fontWeight: 'bold',
    backgroundColor: color,
    padding: '2px 6px',
    border: '1px solid #fff',
    borderRadius: '4px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.3)',
    whiteSpace: 'nowrap'
  })
  map.addOverlay(label)

  flightMarkers.set(normalizedNumber, {
    marker,
    label,
    data: { ...flightData, flightNumber: normalizedNumber }
  })

  marker.addEventListener('click', () => {
    handleMarkerClick(flightData)
  })

  if (showFlightPath.value && flightData.departureAirportCode && flightData.arrivalAirportCode) {
    addFlightPath(flightData)
  }

  return marker
}

const updateMarkerStyle = (markerData, status) => {
  const { label, data } = markerData
  if (label) {
    const color = statusColors[status] || '#1890ff'
    label.setStyle({
      color: '#fff',
      fontSize: '11px',
      fontWeight: 'bold',
      backgroundColor: color,
      padding: '2px 6px',
      border: '1px solid #fff',
      borderRadius: '4px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.3)',
      whiteSpace: 'nowrap'
    })
  }
  data.flightStatus = status
}

const updateMarkerInfo = (markerEntry, newData) => {
  const { marker: bmapMarker, label, data } = markerEntry
  Object.assign(data, newData)

  bmapMarker.setTitle(`${data.flightNumber} | 状态: ${getStatusText(data.flightStatus)} | 位置: ${data.latitude?.toFixed(4)}, ${data.longitude?.toFixed(4)}`)
  
  // 同时更新标签位置
  if (label && data.latitude && data.longitude) {
    label.setPosition(new BMapGL.Point(data.longitude, data.latitude))
  }
}

// 机场坐标映射（用于绘制真实航线）
const airportCoordinates = {
  'PEK': [116.6031, 40.0799], 'PVG': [121.8083, 31.1443],
  'SHA': [121.3363, 31.1979], 'CAN': [113.2988, 23.3924],
  'SZX': [113.8107, 22.6392], 'CTU': [103.9467, 30.5785],
  'CKG': [106.6417, 29.7192], 'XIY': [108.7516, 34.4471],
  'KMG': [102.9292, 25.1019], 'HGH': [120.4345, 30.2295],
  'NKG': [118.8620, 31.7420], 'HAK': [110.3493, 20.0253],
  'TFU': [104.4413, 30.3195], 'SYX': [109.4122, 18.3029],
  'JFK': [-73.7781, 40.6413], 'NRT': [140.3929, 35.7720],
  'LAX': [-118.4080, 33.9425]
}

const addFlightPath = (flightData) => {
  const depCode = flightData.departureAirportCode
  const arrCode = flightData.arrivalAirportCode
  
  // 从机场坐标映射中查询起降机场坐标
  const depCoords = airportCoordinates[depCode]
  const arrCoords = airportCoordinates[arrCode]
  
  let startPoint, endPoint
  
  if (depCoords && arrCoords) {
    // 有真实机场坐标：绘制实际航线
    startPoint = new BMapGL.Point(depCoords[0], depCoords[1])
    endPoint = new BMapGL.Point(arrCoords[0], arrCoords[1])
  } else if (depCoords) {
    // 只有出发机场：从出发机场到当前飞行位置
    startPoint = new BMapGL.Point(depCoords[0], depCoords[1])
    endPoint = new BMapGL.Point(flightData.longitude, flightData.latitude)
  } else if (arrCoords) {
    // 只有到达机场：从当前位置到到达机场
    startPoint = new BMapGL.Point(flightData.longitude, flightData.latitude)
    endPoint = new BMapGL.Point(arrCoords[0], arrCoords[1])
  } else {
    // 不知道机场坐标：不画假航线
    return
  }

  const polyline = new BMapGL.Polyline([startPoint, endPoint], {
    strokeColor: '#1890ff',
    strokeWeight: 2,
    strokeOpacity: 0.5
  })

  map.addOverlay(polyline)
  flightPaths.set(flightData.flightNumber, polyline)
}

const handleMarkerClick = (flightData) => {
  selectedFlight.value = flightData

  centerOnFlight(flightData)

  // 没有有效坐标时不弹出地图 InfoWindow（否则会定位到 0,0 几内亚湾）
  if (flightData.latitude && flightData.longitude && 
      flightData.latitude !== 0 && flightData.longitude !== 0) {
    const point = new BMapGL.Point(
      flightData.longitude,
      flightData.latitude
    )

    const infoWindow = new BMapGL.InfoWindow(`
      <div style="padding: 6px 8px; min-width: 180px;">
        <h4 style="margin: 0 0 6px 0; color: #1890ff; font-size: 13px;">${flightData.flightNumber}</h4>
        <p style="margin: 3px 0; font-size: 12px;"><strong>状态:</strong> ${getStatusText(flightData.flightStatus)}</p>
        <p style="margin: 3px 0; font-size: 12px;"><strong>出发:</strong> ${flightData.departureAirportName}</p>
        <p style="margin: 3px 0; font-size: 12px;"><strong>到达:</strong> ${flightData.arrivalAirportName}</p>
        <p style="margin: 3px 0; font-size: 12px;"><strong>机型:</strong> ${flightData.aircraftType || 'N/A'}</p>
        ${flightData.delayMinutes > 0 ? `<p style="margin: 3px 0; font-size: 12px; color: #faad14;"><strong>延误:</strong> ${flightData.delayMinutes}分钟</p>` : ''}
      </div>
    `, {
      width: 200,
      title: '',
      offset: new BMapGL.Size(0, -5)
    })

    map.openInfoWindow(infoWindow, point)
  }
}

const centerOnFlight = (flightData) => {
  if (!flightData.latitude || !flightData.longitude) return

  const point = new BMapGL.Point(
    flightData.longitude,
    flightData.latitude
  )

  map.centerAndZoom(point, 10)
}

const shouldShowFlight = (flight) => {
  if (focusedFlightNumber.value && flight.flightNumber === focusedFlightNumber.value) return true
  if (!isFlightAllowed(flight.flightNumber)) return false
  if (!flight.latitude || !flight.longitude) return false
  if (selectedStatus.value.length === 0) return true
  if (!flight.flightStatus) return false
  if (!selectedStatus.value.includes(flight.flightStatus)) return false
  return true
}

const filterFlights = () => {
  flightMarkers.forEach(({ marker }) => {
    map.removeOverlay(marker)
  })
  flightMarkers.clear()

  loadInitialFlights()
}

const toggleFlightPath = (show) => {
  showFlightPath.value = show  // 同步内部状态，影响后续 addFlightMarker 的判断
  if (show) {
    // 重新构建所有已加载航班的航线
    flightMarkers.forEach(({ data }) => {
      if (data.departureAirportCode && data.arrivalAirportCode && !flightPaths.has(data.flightNumber)) {
        addFlightPath(data)
      }
    })
    // 显示所有已有航线
    flightPaths.forEach((polyline) => {
      map.addOverlay(polyline)
    })
  } else {
    // 隐藏所有航线
    flightPaths.forEach((polyline) => {
      map.removeOverlay(polyline)
    })
  }
}

const loadAirports = () => {
  const airports = [
    { code: 'PEK', name: '北京首都国际机场', lat: 40.0799, lng: 116.6031 },
    { code: 'PVG', name: '上海浦东国际机场', lat: 31.1443, lng: 121.8083 },
    { code: 'CAN', name: '广州白云国际机场', lat: 23.3924, lng: 113.2988 },
    { code: 'SZX', name: '深圳宝安国际机场', lat: 22.6392, lng: 113.8107 },
    { code: 'CTU', name: '成都双流国际机场', lat: 30.5785, lng: 103.9467 },
    { code: 'CKG', name: '重庆江北国际机场', lat: 29.7192, lng: 106.6417 },
    { code: 'XIY', name: '西安咸阳国际机场', lat: 34.4471, lng: 108.7516 },
    { code: 'KMG', name: '昆明长水国际机场', lat: 25.1019, lng: 102.9292 },
    { code: 'HGH', name: '杭州萧山国际机场', lat: 30.2295, lng: 120.4345 },
    { code: 'NKG', name: '南京禄口国际机场', lat: 31.7420, lng: 118.8620 }
  ]

  airports.forEach(airport => {
    const point = new BMapGL.Point(airport.lng, airport.lat)

    // 使用默认 Marker，用紫色标签区分
    const marker = new BMapGL.Marker(point)

    const label = new BMapGL.Label(airport.code, {
      position: point,
      offset: new BMapGL.Size(15, 0)
    })
    label.setStyle({
      color: '#722ed1',
      fontSize: '12px',
      fontWeight: 'bold',
      backgroundColor: 'white',
      padding: '2px 6px',
      border: '1px solid #722ed1',
      borderRadius: '3px'
    })

    marker.addEventListener('click', () => {
      const infoWindow = new BMapGL.InfoWindow(`
        <div style="padding: 10px; min-width: 150px;">
          <h4 style="margin: 0 0 8px 0; color: #722ed1;">${airport.name}</h4>
          <p style="margin: 4px 0;"><strong>三字码:</strong> ${airport.code}</p>
          <p style="margin: 4px 0;"><strong>坐标:</strong> ${airport.lat.toFixed(4)}, ${airport.lng.toFixed(4)}</p>
        </div>
      `, {
        width: 200
      })

      map.openInfoWindow(infoWindow, point)
    })

    map.addOverlay(marker)
    map.addOverlay(label)

    airportMarkers.set(airport.code, { marker, label })
  })
}

const toggleAirports = (show) => {
  airportMarkers.forEach(({ marker, label }) => {
    if (show) {
      map.addOverlay(marker)
      map.addOverlay(label)
    } else {
      map.removeOverlay(marker)
      map.removeOverlay(label)
    }
  })
}

const toggleWeather = (show) => {
  if (show) {
    ElMessage.info('天气功能开发中')
  }
}

const toggleTraffic = (show) => {
  if (!map || !BMapGL) return
  if (!trafficLayer) {
    trafficLayer = new BMapGL.TrafficLayer()
  }

  if (show) {
    map.addTileLayer(trafficLayer)
  } else {
    map.removeTileLayer(trafficLayer)
  }
}

const changeMapStyle = (style) => {
  const styleMap = {
    normal: 'normal',
    light: 'light',
    dark: 'dark',
    satellite: 'satellite'
  }

  if (map && styleMap[style] !== undefined) {
    map.setMapType(styleMap[style])
  }
}

const focusFlightOnMap = (flightNumber) => {
  if (!flightNumber) return
  focusedFlightNumber.value = flightNumber.toUpperCase()

  if (!mapReady.value) {
    return
  }

  for (const { data } of flightMarkers.values()) {
    if (data.flightNumber.includes(focusedFlightNumber.value)) {
      handleMarkerClick(data)
      return
    }
  }

  searchFlightFromAPI(focusedFlightNumber.value)
}

const searchFlightOnMap = () => {
  if (!searchFlight.value.trim()) return

  for (const { data } of flightMarkers.values()) {
    if (data.flightNumber.includes(searchFlight.value.toUpperCase())) {
      handleMarkerClick(data)
      return
    }
  }

  searchFlightFromAPI(searchFlight.value)
}

const searchFlightFromAPI = async (keyword) => {
  try {
    const [flightRes, activeRes, statusRes] = await Promise.all([
      flightApi.searchFlights(keyword),
      statusApi.getActiveFlights(),
      // 同时尝试直接获取该航班的实时状态（包含 ARRIVED 等非活跃状态）
      statusApi.getRealTimeStatus(keyword).catch(() => null)
    ])
    const flights = flightRes.data || []
    const activeFlights = activeRes.data || []

    if (flights.length > 0) {
      const flight = flights[0]
      focusedFlightNumber.value = flight.flightNumber
      
      // 优先使用直接查询到的实时状态（含坐标和完整状态）
      if (statusRes?.data) {
        const s = statusRes.data
        flight.latitude = s.latitude ?? s.lat
        flight.longitude = s.longitude ?? s.lng
        flight.currentStatus = s.currentStatus || s.current_status || flight.flightStatus
        flight.currentSpeed = s.currentSpeed || s.current_speed
        flight.currentAltitude = s.currentAltitude || s.current_altitude
        flight.delayMinutes = s.delayMinutes || s.delay_minutes
      } else {
        // fallback: 从活跃航班列表中匹配（取最新一条，去重）
        const sortedFlights = [...activeFlights]
          .sort((a, b) => new Date(b.lastUpdated) - new Date(a.lastUpdated))
        const status = sortedFlights.find(s => 
          (s.flightNumber || s.flight_number) === flight.flightNumber
        )
        if (status) {
          flight.latitude = status.latitude ?? status.lat
          flight.longitude = status.longitude ?? status.lng
          flight.currentStatus = status.currentStatus || status.current_status
          flight.currentSpeed = status.currentSpeed || status.current_speed
          flight.currentAltitude = status.currentAltitude || status.current_altitude
          flight.delayMinutes = status.delayMinutes || status.delay_minutes
        }
      }
      
      // 有坐标才添加到地图标记
      addFlightMarker(flight, true)
      // 即使没有坐标也打开详情面板（但不弹地图 InfoWindow）
      handleMarkerClick(flight)
    } else {
      ElMessage.warning(`未找到航班: ${keyword}`)
    }
  } catch (error) {
    console.error('搜索航班失败:', error)
  }
}

const getStatusText = (status) => {
  return dateUtils.getFlightStatusText(status)
}

const getStatusColor = (status) => {
  return dateUtils.getFlightStatusColor(status)
}

const viewFlightDetail = () => {
  if (selectedFlight.value) {
    router.push({
      name: 'FlightDetail',
      params: { flightNumber: selectedFlight.value.flightNumber }
    })
  }
}

const showFlightTrack = async () => {
  if (!selectedFlight.value) return

  // 先清除已有的轨迹，防止重复叠加
  clearTrackOverlays()

  try {
    const res = await statusApi.getFlightTrack(
      selectedFlight.value.flightNumber,
      new Date(Date.now() - 24 * 60 * 60 * 1000),
      new Date()
    )

    const track = res.data || []

    if (track.length > 1) {
      const points = track.map(point =>
        new BMapGL.Point(point.longitude, point.latitude)
      )

      const polyline = new BMapGL.Polyline(points, {
        strokeColor: '#52c41a',
        strokeWeight: 3,
        strokeOpacity: 0.6
      })

      map.addOverlay(polyline)
      trackOverlays.push(polyline)

      track.forEach((point, index) => {
        if (index % 5 === 0) {
          const marker = new BMapGL.Marker(
            new BMapGL.Point(point.longitude, point.latitude)
          )

          const label = new BMapGL.Label(
            dateUtils.formatDate(point.timestamp, 'HH:mm'),
            { position: new BMapGL.Point(point.longitude, point.latitude) }
          )

          map.addOverlay(marker)
          map.addOverlay(label)
          trackOverlays.push(marker, label)
        }
      })

      currentTrackFlightNumber.value = selectedFlight.value.flightNumber
      ElMessage.success('已显示航班轨迹')
    } else {
      ElMessage.warning('无轨迹数据')
    }
  } catch (error) {
    console.error('获取航班轨迹失败:', error)
  }
}

const hideFlightTrack = () => {
  clearTrackOverlays()
  currentTrackFlightNumber.value = ''
  ElMessage.success('轨迹已隐藏')
}

const clearTrackOverlays = () => {
  while (trackOverlays.length > 0) {
    const overlay = trackOverlays.pop()
    if (overlay && map) {
      map.removeOverlay(overlay)
    }
  }
}

const closeInfoPanel = () => {
  hideFlightTrack()
  selectedFlight.value = null
}

const handleResize = () => {
  if (map) {
    map.checkResize()
  }
}

const refresh = () => {
  // 清除标记和标签
  flightMarkers.forEach(({ marker, label }) => {
    map.removeOverlay(marker)
    if (label) map.removeOverlay(label)
  })
  flightMarkers.clear()

  flightPaths.forEach(polyline => map.removeOverlay(polyline))
  flightPaths.clear()

  airportMarkers.forEach(({ marker, label }) => {
    map.removeOverlay(marker)
    map.removeOverlay(label)
  })
  airportMarkers.clear()

  // 清除 InfoWindow
  map.closeInfoWindow()

  loadInitialFlights()
  if (showAirports.value) {
    loadAirports()
  }

  if (focusedFlightNumber.value) {
    focusFlightOnMap(focusedFlightNumber.value)
  }

  ElMessage.success('地图已刷新')
}

const centerOnAirport = (airport) => {
  if (!airport || !map || !BMapGL) return
  const point = new BMapGL.Point(airport.lng, airport.lat)
  map.centerAndZoom(point, 8)
}

const setViewRange = (range) => {
  if (!map) return
  const zoomMap = { nationwide: 5, regional: 7, airport: 10 }
  map.setZoom(zoomMap[range] || 5)
}

const applySettings = (settings) => {
  if (settings?.mapType) {
    changeMapStyle(settings.mapType === 'terrain' ? 'normal' : settings.mapType)
  }
}

onMounted(() => {
  initMap()
})

watch(() => props.flightNumbers, () => {
  if (!map) return
  loadInitialFlights()
}, { deep: true })

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  flightMarkers.clear()
  flightPaths.clear()
  airportMarkers.clear()
})

defineExpose({
  refresh,
  centerOnAirport,
  centerOnFlight,
  focusFlightOnMap,
  toggleWeather,
  toggleTraffic,
  applySettings,
  setViewRange,
  filterFlights: (statusList) => {
    if (statusList) {
      selectedStatus.value = statusList
    }
    loadInitialFlights()
  },
  toggleFlightPath,
  toggleAirports,
  changeMapStyle,
  searchFlightOnMap: (keyword) => {
    const kw = keyword || searchFlight.value
    if (!kw || !kw.trim()) return
    const upper = kw.toUpperCase()
    for (const { data } of flightMarkers.values()) {
      if (data.flightNumber.includes(upper)) {
        handleMarkerClick(data)
        return
      }
    }
    searchFlightFromAPI(upper)
  },
  filterFlightsByStatus: (statusList) => {
    if (statusList) {
      selectedStatus.value = statusList
    }
    loadInitialFlights()
  }
})
</script>

<style lang="scss" scoped>
.real-time-map {
  position: relative;
  height: 100%;
  width: 100%;

  .map-container {
    width: 100%;
    height: 100%;
    border-radius: 4px;
  }

  .map-controls {
    position: absolute;
    top: 20px;
    left: 20px;
    width: 300px;
    z-index: 1000;

    .control-panel {
      .control-header {
        font-weight: bold;
        color: #333;
      }

      .control-content {
        max-height: 400px;
        overflow-y: auto;
      }

      .control-group {
        margin-bottom: 15px;
        padding-bottom: 15px;
        border-bottom: 1px solid #f0f0f0;

        &:last-child {
          border-bottom: none;
          margin-bottom: 0;
          padding-bottom: 0;
        }

        .control-label {
          font-weight: 500;
          margin-bottom: 8px;
          color: #666;
          font-size: 13px;
        }

        .legend {
          .legend-item {
            display: flex;
            align-items: center;
            margin-bottom: 6px;

            .legend-color {
              width: 12px;
              height: 12px;
              border-radius: 50%;
              margin-right: 8px;
              border: 1px solid #fff;

              &.normal {
                background-color: #1890ff;
              }

              &.delayed {
                background-color: #faad14;
              }

              &.cancelled {
                background-color: #ff4d4f;
              }

              &.airport {
                background-color: #722ed1;
              }
            }

            span {
              font-size: 12px;
              color: #666;
            }
          }
        }
      }
    }
  }

  .flight-info-panel {
    position: absolute;
    top: 10px;
    right: 10px;
    width: 340px;
    z-index: 1000;
    font-size: 12px;

    :deep(.el-card__header) {
      padding: 8px 12px;
    }
    :deep(.el-card__body) {
      padding: 10px 12px;
    }

    .info-card {
      .info-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        font-weight: bold;
        color: #333;
        font-size: 13px;
      }

      .flight-details {
        .info-section {
          margin-bottom: 10px;

          h4 {
            margin: 0 0 6px 0;
            color: #333;
            font-size: 12px;
            font-weight: 500;
          }

          :deep(.el-descriptions__title) {
            font-size: 12px;
          }
          :deep(.el-descriptions__label) {
            font-size: 11px;
            padding: 4px 8px;
          }
          :deep(.el-descriptions__content) {
            font-size: 11px;
            padding: 4px 8px;
          }

          .status-info {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            align-items: center;

            .delay-info,
            .speed-info,
            .altitude-info {
              display: flex;
              align-items: center;
              gap: 3px;
              font-size: 11px;
              color: #666;

              .el-icon {
                font-size: 12px;
              }
            }
          }

          .position-info {
            font-size: 11px;
            color: #666;
            line-height: 1.4;
          }
        }

        .action-buttons {
          display: flex;
          gap: 6px;
          justify-content: center;
          margin-top: 10px;

          :deep(.el-button) {
            font-size: 11px;
            padding: 4px 8px;
          }
        }
      }
    }
  }
}
</style>
