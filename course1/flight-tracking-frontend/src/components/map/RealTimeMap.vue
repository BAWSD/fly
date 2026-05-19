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
            <el-button @click="centerOnFlight">
              <el-icon><Aim /></el-icon>居中显示
            </el-button>
            <el-button @click="showFlightTrack">
              <el-icon><TrendCharts /></el-icon>查看轨迹
            </el-button>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
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
const selectedStatus = ref(['SCHEDULED', 'IN_AIR', 'DEPARTED'])
const selectedFlight = ref(null)
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
    const res = await flightApi.getFlightList({ pageSize: 50 })
    const flights = res.data?.records || []

    flights.forEach(flight => {
      if (shouldShowFlight(flight)) {
        addFlightMarker(flight)
      }
    })
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
  const entry = flightMarkers.get(flightData.flightNumber)

  if (entry) {
    const newPoint = new BMapGL.Point(
      flightData.longitude,
      flightData.latitude
    )

    entry.marker.setPosition(newPoint)
    updateMarkerInfo(entry, flightData)

    if (selectedFlight.value?.flightNumber === flightData.flightNumber) {
      selectedFlight.value = { ...selectedFlight.value, ...flightData }
    }
  } else {
    addFlightMarker(flightData)
  }
}

const handleStatusUpdate = (flightData) => {
  const marker = flightMarkers.get(flightData.flightNumber)
  if (marker) {
    updateMarkerStyle(marker, flightData.flightStatus)
  }
}

const addFlightMarker = (flightData) => {
  if (!flightData.latitude || !flightData.longitude) return

  const point = new BMapGL.Point(
    flightData.longitude,
    flightData.latitude
  )

  const icon = createFlightIcon(flightData.flightStatus)

  const marker = new BMapGL.Marker(point, {
    icon: icon,
    rotation: 0,
    title: flightData.flightNumber
  })

  map.addOverlay(marker)

  flightMarkers.set(flightData.flightNumber, {
    marker,
    data: flightData
  })

  marker.addEventListener('click', () => {
    handleMarkerClick(flightData)
  })

  if (showFlightPath.value && flightData.departureAirportCode && flightData.arrivalAirportCode) {
    addFlightPath(flightData)
  }

  return marker
}

const createFlightIcon = (status) => {
  const color = statusColors[status] || '#1890ff'
  const iconSize = new BMapGL.Size(24, 24)

  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
      <path d="M10.04 4.29L12 2.3l1.96 1.99L20 6.88l-2.5 3.13 3.5 2.63v3.75l-1.88.63-3.62 5.99L12 21.7l-3.5-2.69-3.62-5.99L2.5 16.4v-3.75l3.5-2.63L4 6.88l6.04-2.59z" fill="${color}" stroke="#fff" stroke-width="1"/>
    </svg>
  `

  return new BMapGL.Icon(svg, iconSize, {
    anchor: new BMapGL.Size(12, 12)
  })
}

const updateMarkerStyle = (marker, status) => {
  const { marker: bmapMarker, data } = marker
  const icon = createFlightIcon(status)
  bmapMarker.setIcon(icon)
  data.flightStatus = status
}

const updateMarkerInfo = (marker, newData) => {
  const { marker: bmapMarker, data } = marker
  Object.assign(data, newData)

  bmapMarker.setTitle(`
    ${data.flightNumber}
    状态: ${getStatusText(data.flightStatus)}
    位置: ${data.latitude?.toFixed(4)}, ${data.longitude?.toFixed(4)}
  `)
}

const addFlightPath = (flightData) => {
  const startPoint = new BMapGL.Point(
    flightData.longitude - 5 + Math.random() * 10,
    flightData.latitude - 5 + Math.random() * 10
  )
  const endPoint = new BMapGL.Point(
    flightData.longitude + 5 + Math.random() * 10,
    flightData.latitude + 5 + Math.random() * 10
  )

  const polyline = new BMapGL.Polyline([startPoint, endPoint], {
    strokeColor: statusColors[flightData.flightStatus] + '80',
    strokeWeight: 2,
    strokeOpacity: 0.5
  })

  map.addOverlay(polyline)
  flightPaths.set(flightData.flightNumber, polyline)
}

const handleMarkerClick = (flightData) => {
  selectedFlight.value = flightData

  centerOnFlight(flightData)

  const point = new BMapGL.Point(
    flightData.longitude,
    flightData.latitude
  )

  const infoWindow = new BMapGL.InfoWindow(`
    <div style="padding: 10px; min-width: 200px;">
      <h4 style="margin: 0 0 10px 0; color: #1890ff;">${flightData.flightNumber}</h4>
      <p style="margin: 5px 0;"><strong>状态:</strong> ${getStatusText(flightData.flightStatus)}</p>
      <p style="margin: 5px 0;"><strong>出发:</strong> ${flightData.departureAirportName}</p>
      <p style="margin: 5px 0;"><strong>到达:</strong> ${flightData.arrivalAirportName}</p>
      <p style="margin: 5px 0;"><strong>机型:</strong> ${flightData.aircraftType || 'N/A'}</p>
      ${flightData.delayMinutes > 0 ? `<p style="margin: 5px 0; color: #faad14;"><strong>延误:</strong> ${flightData.delayMinutes}分钟</p>` : ''}
    </div>
  `, {
    width: 250,
    offset: new BMapGL.Size(0, -30)
  })

  map.openInfoWindow(infoWindow, point)
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
  if (!flight.latitude || !flight.longitude) return false
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
  flightPaths.forEach((polyline) => {
    if (show) {
      map.addOverlay(polyline)
    } else {
      map.removeOverlay(polyline)
    }
  })
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

    const iconSize = new BMapGL.Size(20, 20)
    const svg = `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20">
        <circle cx="12" cy="12" r="8" fill="#722ed1" stroke="#fff" stroke-width="1"/>
        <circle cx="12" cy="12" r="4" fill="#fff"/>
      </svg>
    `

    const icon = new BMapGL.Icon(svg, iconSize, {
      anchor: new BMapGL.Size(10, 10)
    })

    const marker = new BMapGL.Marker(point, { icon })

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

const searchFlightOnMap = () => {
  if (!searchFlight.value.trim()) return

  for (const { data } of flightMarkers.values()) {
    if (data.flightNumber.includes(searchFlight.value.toUpperCase())) {
      handleMarkerClick(data)
      return
    }
  }

  searchFlightFromAPI()
}

const searchFlightFromAPI = async () => {
  try {
    const res = await flightApi.searchFlights(searchFlight.value)
    const flights = res.data || []

    if (flights.length > 0) {
      const flight = flights[0]
      handleMarkerClick(flight)
    } else {
      ElMessage.warning(`未找到航班: ${searchFlight.value}`)
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
        strokeColor: '#1890ff',
        strokeWeight: 3,
        strokeOpacity: 0.6
      })

      map.addOverlay(polyline)

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
        }
      })

      ElMessage.success('已显示航班轨迹')
    } else {
      ElMessage.warning('无轨迹数据')
    }
  } catch (error) {
    console.error('获取航班轨迹失败:', error)
  }
}

const closeInfoPanel = () => {
  selectedFlight.value = null
}

const handleResize = () => {
  if (map) {
    map.checkResize()
  }
}

const refresh = () => {
  flightMarkers.forEach(({ marker }) => map.removeOverlay(marker))
  flightMarkers.clear()

  flightPaths.forEach(polyline => map.removeOverlay(polyline))
  flightPaths.clear()

  airportMarkers.forEach(({ marker, label }) => {
    map.removeOverlay(marker)
    map.removeOverlay(label)
  })
  airportMarkers.clear()

  loadInitialFlights()
  if (showAirports.value) {
    loadAirports()
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
  toggleWeather,
  toggleTraffic,
  applySettings,
  setViewRange,
  filterFlights: loadInitialFlights,
  toggleFlightPath,
  toggleAirports,
  changeMapStyle,
  searchFlightOnMap: () => {
    if (!searchFlight.value.trim()) return
    for (const { data } of flightMarkers.values()) {
      if (data.flightNumber.includes(searchFlight.value.toUpperCase())) {
        handleMarkerClick(data)
        return
      }
    }
    searchFlightFromAPI()
  },
  toggle3D: (is3d) => {
    // BaiduMap GL doesn't have a simple "3D toggle", but we can adjust zoom/pitch
    if (map) {
      if (is3d) {
        map.setTilt(60)
        map.setHeading(45)
      } else {
        map.setTilt(0)
        map.setHeading(0)
      }
    }
  },
  filterFlightsByStatus: (statusList) => {
    selectedStatus.value = statusList
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
    top: 20px;
    right: 20px;
    width: 350px;
    z-index: 1000;

    .info-card {
      .info-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        font-weight: bold;
        color: #333;
      }

      .flight-details {
        .info-section {
          margin-bottom: 20px;

          h4 {
            margin: 0 0 10px 0;
            color: #333;
            font-size: 14px;
            font-weight: 500;
          }

          .status-info {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            align-items: center;

            .delay-info,
            .speed-info,
            .altitude-info {
              display: flex;
              align-items: center;
              gap: 4px;
              font-size: 12px;
              color: #666;

              .el-icon {
                font-size: 14px;
              }
            }
          }

          .position-info {
            font-size: 12px;
            color: #666;
            line-height: 1.5;
          }
        }

        .action-buttons {
          display: flex;
          gap: 10px;
          justify-content: center;
          margin-top: 20px;
        }
      }
    }
  }
}
</style>
