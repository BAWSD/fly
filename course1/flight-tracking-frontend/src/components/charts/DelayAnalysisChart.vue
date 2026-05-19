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
  }
})

const chartRef = ref(null)
let chartInstance = null

const initChart = () => {
  if (!chartRef.value) return
  chartInstance = echarts.init(chartRef.value)
  updateChart()
  window.addEventListener('resize', handleResize)
}

const updateChart = () => {
  if (!chartInstance) return

  const stats = props.stats || {}
  const dailyCount = stats.dailyDelayCount || {}
  const dailyAvg = stats.dailyAvgDelay || {}
  const labels = Object.keys(dailyCount)
  const countValues = Object.values(dailyCount)
  const avgValues = labels.map(k => dailyAvg[k] || 0)

  if (labels.length === 0) return

  const shortLabels = labels.map(l => l.substring(5))

  const option = {
    tooltip: {
      trigger: 'axis',
      formatter: (params) => {
        let result = params[0].axisValue + '<br/>'
        params.forEach(p => {
          result += p.marker + ' ' + p.seriesName + ': ' + p.value + (p.seriesName === '延误次数' ? '次' : '分钟') + '<br/>'
        })
        return result
      }
    },
    legend: {
      data: ['延误次数', '平均延误时间'],
      top: 0
    },
    grid: {
      left: 50,
      right: 50,
      top: 40,
      bottom: 50
    },
    dataZoom: [
      { type: 'inside', start: 0, end: 100 },
      { type: 'slider', start: 0, end: 100, height: 20, bottom: 5 }
    ],
    xAxis: {
      type: 'category',
      data: shortLabels,
      axisLabel: { rotate: shortLabels.length > 7 ? 30 : 0, fontSize: 11 }
    },
    yAxis: [
      {
        type: 'value',
        name: '延误次数',
        position: 'left',
        axisLine: { show: true },
        splitLine: { show: true, lineStyle: { type: 'dashed' } }
      },
      {
        type: 'value',
        name: '平均延误(分钟)',
        position: 'right',
        axisLine: { show: true },
        splitLine: { show: false }
      }
    ],
    visualMap: {
      show: false,
      pieces: [
        { lte: 10, color: '#67C23A' },
        { gt: 10, lte: 20, color: '#E6A23C' },
        { gt: 20, color: '#F56C6C' }
      ],
      seriesIndex: 0
    },
    series: [
      {
        name: '延误次数',
        data: countValues,
        type: 'bar',
        barWidth: '40%',
        itemStyle: { borderRadius: [4, 4, 0, 0] },
        markLine: {
          silent: true,
          lineStyle: { type: 'dashed' },
          data: [
            { yAxis: 10, label: { formatter: '轻度', position: 'end' }, lineStyle: { color: '#67C23A' } },
            { yAxis: 20, label: { formatter: '严重', position: 'end' }, lineStyle: { color: '#F56C6C' } }
          ]
        }
      },
      {
        name: '平均延误时间',
        data: avgValues,
        type: 'line',
        yAxisIndex: 1,
        smooth: true,
        lineStyle: { width: 2, color: '#409EFF' },
        areaStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: 'rgba(64,158,255,0.3)' }, { offset: 1, color: 'rgba(64,158,255,0.05)' }] } },
        symbol: 'circle',
        symbolSize: 6
      }
    ]
  }

  chartInstance.setOption(option, true)
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
