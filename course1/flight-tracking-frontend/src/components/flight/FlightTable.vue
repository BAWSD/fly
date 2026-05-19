<template>
  <el-table :data="data" style="width: 100%">
    <el-table-column prop="flightNumber" label="航班号" />
    <el-table-column prop="airlineName" label="航空公司" />
    <el-table-column prop="departureAirportName" label="出发机场" />
    <el-table-column prop="arrivalAirportName" label="到达机场" />
  </el-table>
</template>

<script setup>
defineProps({
  data: {
    type: Array,
    default: () => []
  }
})
</script>

