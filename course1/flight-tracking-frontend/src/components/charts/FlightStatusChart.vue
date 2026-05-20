<template>
  <div ref="chartRef" style="width: 100%; height: 100%;"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import * as echarts from 'echarts'

const props = defineProps({
  stats: {
    type: Object,
    default: () => ({})
  },
  title: {
    type: String,
    default: '航班状态分布'
  }
})

const chartRef = ref(null)
let chartInstance = null

const statusColors = {
  SCHEDULED: '#1890ff',
  DELAYED: '#faad14',
  BOARDING: '#13c2c2',
  DEPARTED: '#52c41a',
  IN_AIR: '#52c41a',
  LANDED: '#52c41a',
  ARRIVED: '#d9d9d9',
  CANCELLED: '#ff4d4f',
  DIVERTED: '#eb2f96',
  UNKNOWN: '#722ed1'
}

const statusLabels = {
  SCHEDULED: '计划中',
  DELAYED: '延误',
  BOARDING: '登机中',
  DEPARTED: '已起飞',
  IN_AIR: '飞行中',
  LANDED: '已降落',
  ARRIVED: '已到达',
  CANCELLED: '已取消',
  DIVERTED: '已改航',
  UNKNOWN: '状态未知'
}

const initChart = () => {
  if (!chartRef.value) return

  chartInstance = echarts.init(chartRef.value)
  updateChart()

  window.addEventListener('resize', handleResize)
}

const updateChart = () => {
  if (!chartInstance || !props.stats) return

  const data = []
  const colors = []

  Object.entries(props.stats).forEach(([status, count]) => {
    if (count > 0) {
      data.push({
        name: statusLabels[status] || status,
        value: count
      })
      colors.push(statusColors[status] || '#1890ff')
    }
  })

  const totalCount = data.reduce((sum, item) => sum + item.value, 0)
  const option = {
    tooltip: {
      trigger: 'item',
      formatter: '{a} <br/>{b}: {c} ({d}%)'
    },
    legend: {
      type: 'scroll',
      orient: 'vertical',
      right: 10,
      top: 'middle',
      itemGap: 10,
      data: data.map(item => item.name)
    },
    series: [
      {
        name: '航班状态',
        type: 'pie',
        radius: ['44%', '74%'],
        center: ['38%', '50%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: false,
          position: 'center',
          formatter: '{b}\n{c}'
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 16,
            fontWeight: 'bold'
          },
          itemStyle: {
            shadowBlur: 10,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        },
        labelLine: {
          show: false
        },
        data: data,
        color: colors
      }
    ],
  }

  chartInstance.setOption(option)
}

const handleResize = () => {
  if (chartInstance) {
    chartInstance.resize()
  }
}

const refresh = () => {
  updateChart()
}

watch(() => props.stats, () => {
  updateChart()
}, { deep: true })

onMounted(() => {
  initChart()
})

onUnmounted(() => {
  if (chartInstance) {
    chartInstance.dispose()
  }
  window.removeEventListener('resize', handleResize)
})

defineExpose({
  refresh
})
</script>
