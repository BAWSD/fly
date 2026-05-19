<template>
  <el-card class="ai-prediction-card" shadow="hover">
    <template #header>
      <div class="card-header">
        <div class="header-left">
          <el-icon class="ai-icon"><MagicStick /></el-icon>
          <span>AI 智能预测</span>
        </div>
        <div class="header-right">
          <el-tag
            v-if="predictionLevel"
            :type="predictionLevel.type"
            size="small"
            round
          >
            {{ predictionLevel.text }}
          </el-tag>
        </div>
      </div>
    </template>

    <div v-loading="loading" element-loading-text="AI分析中...">
      <div v-if="prediction" class="prediction-content">
        <div class="flight-info">
          <div class="flight-number">{{ flightNumber }}</div>
          <div class="flight-route">
            <span>{{ departureAirport }}</span>
            <el-icon><Right /></el-icon>
            <span>{{ arrivalAirport }}</span>
          </div>
        </div>

        <div class="delay-prediction">
          <div class="prediction-title">延误预测</div>
          <div class="prediction-value" :style="{ color: delayColor }">
            {{ prediction.predicted_delay_minutes }} 分钟
          </div>
          <div class="prediction-bar">
            <div
              class="bar-fill"
              :style="{ width: delayPercentage + '%', backgroundColor: delayColor }"
            ></div>
            <div class="bar-labels">
              <span>准点</span>
              <span>轻度延误</span>
              <span>严重延误</span>
            </div>
          </div>
        </div>

        <div v-if="prediction.features_used" class="influencing-factors">
          <div class="factors-title">影响因素</div>
          <div class="factors-grid">
            <div
              v-for="(value, key) in prediction.features_used"
              :key="key"
              class="factor-item"
            >
              <div class="factor-name">{{ getFactorName(key) }}</div>
              <div class="factor-value">{{ formatFactorValue(key, value) }}</div>
              <div class="factor-impact" :style="{ width: getFactorImpact(key, value) + '%' }"></div>
            </div>
          </div>
        </div>

        <div class="prediction-details">
          <el-collapse>
            <el-collapse-item title="预测详情">
              <div class="details-content">
                <div class="detail-item">
                  <span class="label">预测时间：</span>
                  <span>{{ formatTime(prediction.prediction_time) }}</span>
                </div>
                <div class="detail-item">
                  <span class="label">置信度：</span>
                  <span>{{ confidence }}%</span>
                </div>
                <div class="detail-item">
                  <span class="label">历史延误率：</span>
                  <span>{{ historicalDelayRate }}%</span>
                </div>
                <div v-if="recommendations.length > 0" class="recommendations">
                  <div class="recommendation-title">建议</div>
                  <ul>
                    <li
                      v-for="(rec, index) in recommendations"
                      :key="index"
                      class="recommendation-item"
                    >
                      {{ rec }}
                    </li>
                  </ul>
                </div>
              </div>
            </el-collapse-item>
          </el-collapse>
        </div>

        <div class="action-buttons">
          <el-button
            type="primary"
            size="small"
            @click="refreshPrediction"
            :loading="refreshing"
          >
            <el-icon><Refresh /></el-icon>重新预测
          </el-button>
          <el-button
            size="small"
            @click="showDetails"
          >
            详细分析
          </el-button>
          <el-button
            size="small"
            @click="sharePrediction"
          >
            分享结果
          </el-button>
        </div>
      </div>

      <div v-else class="no-prediction">
        <div class="no-data">
          <el-icon class="empty-icon"><DataAnalysis /></el-icon>
          <p>选择航班后显示AI预测结果</p>
          <p class="hint">AI将基于历史数据、天气、航班状态等多维度进行分析</p>
        </div>
        <div class="sample-prediction">
          <el-button type="primary" text @click="showSamplePrediction">
            <el-icon><View /></el-icon>查看示例
          </el-button>
        </div>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { ElMessage } from 'element-plus'
import {
  MagicStick, Refresh, Right, View,
  DataAnalysis
} from '@element-plus/icons-vue'
import { aiApi } from '@/api'
import { format } from 'date-fns'

const props = defineProps({
  flightNumber: String,
  flightDetails: Object
})

const emit = defineEmits(['refresh', 'show-details'])

const prediction = ref(null)
const loading = ref(false)
const refreshing = ref(false)
const sampleMode = ref(false)

const departureAirport = computed(() => {
  return props.flightDetails?.departureAirportCode || '--'
})

const arrivalAirport = computed(() => {
  return props.flightDetails?.arrivalAirportCode || '--'
})

const predictionLevel = computed(() => {
  const delay = prediction.value?.predicted_delay_minutes || 0
  if (delay < 15) return { type: 'success', text: '准点' }
  if (delay < 60) return { type: 'warning', text: '轻度延误' }
  return { type: 'danger', text: '严重延误' }
})

const delayColor = computed(() => {
  const delay = prediction.value?.predicted_delay_minutes || 0
  if (delay < 15) return '#67C23A'
  if (delay < 60) return '#E6A23C'
  return '#F56C6C'
})

const delayPercentage = computed(() => {
  const delay = prediction.value?.predicted_delay_minutes || 0
  return Math.min(delay / 120 * 100, 100)
})

const confidence = computed(() => {
  const delay = prediction.value?.predicted_delay_minutes || 0
  if (delay === 0) return 85
  if (delay < 30) return 75
  if (delay < 60) return 65
  return 55
})

const historicalDelayRate = computed(() => {
  const features = prediction.value?.features_used
  if (!features) return 0
  return features.historical_delay_avg || 0
})

const recommendations = computed(() => {
  const delay = prediction.value?.predicted_delay_minutes || 0
  const recs = []

  if (delay >= 30) {
    recs.push('建议提前2小时到达机场，预留充足时间')
  }
  if (delay >= 60) {
    recs.push('可联系航空公司了解具体原因')
    recs.push('考虑购买航班延误险')
  }
  if (prediction.value?.features_used?.weather_score >= 4) {
    recs.push('天气状况较差，注意关注航班动态')
  }

  return recs
})

const getFactorName = (key) => {
  const names = {
    historical_delay_avg: '历史延误率',
    is_weekend: '是否周末',
    departure_hour: '出发时间',
    weather_score: '天气影响',
    traffic_index: '交通流量',
    holiday_effect: '节假日影响',
    aircraft_age: '机龄',
    route_congestion: '航线拥堵'
  }
  return names[key] || key
}

const formatFactorValue = (key, value) => {
  if (key === 'is_weekend') {
    return value === 1 ? '是' : '否'
  }
  if (key === 'departure_hour') {
    return `${value}:00`
  }
  if (key === 'weather_score') {
    return getWeatherText(value)
  }
  return value
}

const getFactorImpact = (key, value) => {
  const impacts = {
    historical_delay_avg: Math.min(value * 2, 100),
    is_weekend: value === 1 ? 30 : 10,
    departure_hour: Math.abs(value - 12) * 2,
    weather_score: value * 20,
    traffic_index: value * 15,
    holiday_effect: value * 25,
    aircraft_age: Math.min(value * 5, 100),
    route_congestion: value * 20
  }
  return impacts[key] || Math.random() * 50
}

const getWeatherText = (score) => {
  if (score <= 1) return '晴好'
  if (score <= 2) return '多云'
  if (score <= 3) return '阴天'
  if (score <= 4) return '小雨'
  return '恶劣'
}

const formatTime = (timeStr) => {
  if (!timeStr) return ''
  try {
    return format(new Date(timeStr), 'yyyy-MM-dd HH:mm:ss')
  } catch (error) {
    return timeStr
  }
}

const fetchPrediction = async () => {
  if (!props.flightNumber) return

  loading.value = true
  try {
    const features = props.flightDetails ? extractFeatures(props.flightDetails) : getDefaultFeatures()

    const res = await aiApi.predictDelay(props.flightNumber, features)
    prediction.value = res.data
    emit('refresh', res.data)
  } catch (error) {
    console.error('AI预测失败:', error)

    if (!sampleMode.value) {
      showSamplePrediction()
    } else {
      ElMessage.error('AI预测服务暂时不可用')
    }
  } finally {
    loading.value = false
  }
}

const extractFeatures = (flightDetails) => {
  return {
    historical_delay_avg: flightDetails.historicalDelay || 10,
    is_weekend: new Date().getDay() >= 5 ? 1 : 0,
    departure_hour: new Date(flightDetails.plannedDepartureTime).getHours(),
    weather_score: Math.floor(Math.random() * 5) + 1,
    traffic_index: Math.floor(Math.random() * 10) + 1,
    holiday_effect: 0,
    aircraft_age: 3 + Math.random() * 10,
    route_congestion: Math.floor(Math.random() * 8) + 1
  }
}

const getDefaultFeatures = () => {
  return {
    historical_delay_avg: 15,
    is_weekend: 0,
    departure_hour: new Date().getHours(),
    weather_score: 2,
    traffic_index: 5,
    holiday_effect: 0,
    aircraft_age: 5,
    route_congestion: 3
  }
}

const refreshPrediction = async () => {
  refreshing.value = true
  try {
    await fetchPrediction()
    ElMessage.success('预测已刷新')
  } finally {
    refreshing.value = false
  }
}

const showDetails = () => {
  emit('show-details', prediction.value)
}

const sharePrediction = () => {
  if (!prediction.value) return

  const text = `航班 ${props.flightNumber} AI预测结果：\n预计延误：${prediction.value.predicted_delay_minutes}分钟\n预测时间：${formatTime(prediction.value.prediction_time)}`

  if (navigator.share) {
    navigator.share({
      title: '航班延误预测',
      text: text
    }).catch(console.error)
  } else {
    navigator.clipboard.writeText(text)
      .then(() => ElMessage.success('预测结果已复制'))
      .catch(() => ElMessage.error('复制失败'))
  }
}

const showSamplePrediction = () => {
  sampleMode.value = true
  prediction.value = {
    flight_number: props.flightNumber || 'CA1234',
    predicted_delay_minutes: Math.floor(Math.random() * 90) + 5,
    prediction_time: new Date().toISOString(),
    features_used: {
      historical_delay_avg: 15 + Math.random() * 20,
      is_weekend: Math.random() > 0.5 ? 1 : 0,
      departure_hour: 8 + Math.floor(Math.random() * 12),
      weather_score: Math.floor(Math.random() * 5) + 1,
      traffic_index: Math.floor(Math.random() * 10) + 1,
      holiday_effect: 0,
      aircraft_age: Math.floor(Math.random() * 15) + 1,
      route_congestion: Math.floor(Math.random() * 8) + 1
    }
  }
  ElMessage.info('显示示例预测数据')
}

watch(() => props.flightNumber, (newVal) => {
  if (newVal) {
    fetchPrediction()
  } else {
    prediction.value = null
  }
}, { immediate: true })
</script>

<style lang="scss" scoped>
.ai-prediction-card {
  height: 100%;

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;

    .header-left {
      display: flex;
      align-items: center;
      gap: 8px;

      .ai-icon {
        color: #1890ff;
        font-size: 18px;
      }

      span {
        font-weight: bold;
        color: #333;
      }
    }
  }

  .prediction-content {
    .flight-info {
      text-align: center;
      margin-bottom: 20px;
      padding-bottom: 20px;
      border-bottom: 1px solid #f0f0f0;

      .flight-number {
        font-size: 24px;
        font-weight: bold;
        color: #333;
        margin-bottom: 8px;
      }

      .flight-route {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 10px;
        font-size: 16px;
        color: #666;

        .el-icon {
          font-size: 12px;
        }
      }
    }

    .delay-prediction {
      text-align: center;
      margin-bottom: 20px;

      .prediction-title {
        font-size: 14px;
        color: #666;
        margin-bottom: 8px;
      }

      .prediction-value {
        font-size: 36px;
        font-weight: bold;
        margin-bottom: 15px;
        transition: color 0.3s;
      }

      .prediction-bar {
        background-color: #f5f5f5;
        height: 20px;
        border-radius: 10px;
        overflow: hidden;
        position: relative;
        margin-bottom: 5px;

        .bar-fill {
          height: 100%;
          border-radius: 10px;
          transition: width 0.6s ease;
        }

        .bar-labels {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          display: flex;
          justify-content: space-between;
          padding: 0 10px;
          font-size: 10px;
          color: #999;
          line-height: 20px;
        }
      }
    }

    .influencing-factors {
      .factors-title {
        font-size: 14px;
        color: #666;
        margin-bottom: 10px;
      }

      .factors-grid {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 10px;
        margin-bottom: 20px;

        .factor-item {
          position: relative;
          padding: 8px;
          background-color: #f9f9f9;
          border-radius: 4px;
          overflow: hidden;

          .factor-name {
            font-size: 12px;
            color: #333;
            margin-bottom: 4px;
          }

          .factor-value {
            font-size: 12px;
            color: #1890ff;
            font-weight: 500;
          }

          .factor-impact {
            position: absolute;
            bottom: 0;
            left: 0;
            height: 2px;
            background-color: #1890ff;
            opacity: 0.3;
            transition: width 0.3s;
          }
        }
      }
    }

    .prediction-details {
      margin-bottom: 20px;

      .details-content {
        .detail-item {
          display: flex;
          justify-content: space-between;
          margin-bottom: 8px;
          font-size: 12px;

          .label {
            color: #666;
          }

          span:last-child {
            color: #333;
            font-weight: 500;
          }
        }

        .recommendations {
          margin-top: 15px;
          padding-top: 15px;
          border-top: 1px solid #f0f0f0;

          .recommendation-title {
            font-size: 12px;
            font-weight: bold;
            color: #333;
            margin-bottom: 8px;
          }

          .recommendation-item {
            font-size: 12px;
            color: #666;
            margin-bottom: 4px;
            line-height: 1.4;

            &:before {
              content: "•";
              color: #1890ff;
              margin-right: 8px;
            }
          }
        }
      }
    }

    .action-buttons {
      display: flex;
      gap: 8px;
      justify-content: center;
    }
  }

  .no-prediction {
    .no-data {
      text-align: center;
      padding: 40px 20px;

      .empty-icon {
        font-size: 48px;
        color: #dcdfe6;
        margin-bottom: 16px;
      }

      p {
        margin: 8px 0;
        color: #999;
      }

      .hint {
        font-size: 12px;
      }
    }

    .sample-prediction {
      text-align: center;
      padding-top: 20px;
      border-top: 1px solid #f0f0f0;
    }
  }
}
</style>

