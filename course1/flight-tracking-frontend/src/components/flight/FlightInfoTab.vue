<template>
  <el-descriptions :column="2" border>
    <el-descriptions-item label="航班号">{{ flight.flightNumber || '--' }}</el-descriptions-item>
    <el-descriptions-item label="航空公司">{{ flight.airlineName || '--' }}</el-descriptions-item>
    <el-descriptions-item label="出发机场">{{ flight.departureAirportName || flight.departureAirportCode || '--' }}</el-descriptions-item>
    <el-descriptions-item label="到达机场">{{ flight.arrivalAirportName || flight.arrivalAirportCode || '--' }}</el-descriptions-item>
    <el-descriptions-item label="计划起飞">{{ formatTime(flight.plannedDepartureTime) }}</el-descriptions-item>
    <el-descriptions-item label="计划到达">{{ formatTime(flight.plannedArrivalTime) }}</el-descriptions-item>
    <el-descriptions-item label="实际起飞">{{ formatTime(flight.actualDepartureTime) }}</el-descriptions-item>
    <el-descriptions-item label="实际到达">{{ formatTime(flight.actualArrivalTime) }}</el-descriptions-item>
    <el-descriptions-item label="机型">{{ flight.aircraftType || '--' }}</el-descriptions-item>
    <el-descriptions-item label="登机口">{{ flight.gate || '--' }}</el-descriptions-item>
    <el-descriptions-item label="航站楼">{{ flight.terminal || '--' }}</el-descriptions-item>
    <el-descriptions-item label="航班状态">
      <el-tag :type="getStatusColor(flight.flightStatus)" size="small">
        {{ getStatusText(flight.flightStatus) }}
      </el-tag>
    </el-descriptions-item>
    <el-descriptions-item label="备注" :span="2">{{ flight.description || '--' }}</el-descriptions-item>
  </el-descriptions>
</template>

<script setup>
defineProps({
  flight: {
    type: Object,
    default: () => ({})
  }
})

const formatTime = (time) => {
  if (!time) return '--'
  try {
    return new Date(time).toLocaleString('zh-CN', {
      year: 'numeric', month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit'
    })
  } catch {
    return time
  }
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
    SCHEDULED: 'info', DELAYED: 'warning', BOARDING: '',
    DEPARTED: '', IN_AIR: 'success', LANDED: 'success',
    ARRIVED: 'success', CANCELLED: 'danger', ON_TIME: 'success'
  }
  return map[status] || 'info'
}
</script>

