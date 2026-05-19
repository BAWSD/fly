<template>
  <div class="flight-detail-drawer">
    <el-descriptions :column="1" border>
      <el-descriptions-item label="航班号">{{ flight.flightNumber }}</el-descriptions-item>
      <el-descriptions-item label="航空公司">{{ flight.airlineName }}</el-descriptions-item>
      <el-descriptions-item label="出发机场">{{ flight.departureAirportName }}</el-descriptions-item>
      <el-descriptions-item label="到达机场">{{ flight.arrivalAirportName }}</el-descriptions-item>
      <el-descriptions-item label="状态">{{ flight.flightStatus }}</el-descriptions-item>
    </el-descriptions>
  </div>
</template>

<script setup>
defineProps({
  flight: {
    type: Object,
    default: () => ({})
  }
})
</script>

