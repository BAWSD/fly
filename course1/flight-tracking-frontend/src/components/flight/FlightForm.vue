<template>
  <el-form
    ref="formRef"
    :model="formData"
    :rules="rules"
    label-width="100px"
    :disabled="submitting"
  >
    <el-tabs v-model="activeTab">
      <el-tab-pane label="基础信息" name="basic">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="航班号" prop="flightNumber">
              <el-input
                v-model="formData.flightNumber"
                placeholder="如: CA1234"
                maxlength="20"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="航空公司" prop="airlineName">
              <el-input
                v-model="formData.airlineName"
                placeholder="航空公司名称"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="出发机场" prop="departureAirportCode">
              <el-select
                v-model="formData.departureAirportCode"
                placeholder="选择出发机场"
                style="width: 100%"
                @change="handleDepartureAirportChange"
              >
                <el-option
                  v-for="airport in airports"
                  :key="airport.code"
                  :label="`${airport.code} - ${airport.name}`"
                  :value="airport.code"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="到达机场" prop="arrivalAirportCode">
              <el-select
                v-model="formData.arrivalAirportCode"
                placeholder="选择到达机场"
                style="width: 100%"
                @change="handleArrivalAirportChange"
              >
                <el-option
                  v-for="airport in airports"
                  :key="airport.code"
                  :label="`${airport.code} - ${airport.name}`"
                  :value="airport.code"
                />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="计划起飞" prop="plannedDepartureTime">
              <el-date-picker
                v-model="formData.plannedDepartureTime"
                type="datetime"
                placeholder="选择计划起飞时间"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="计划到达" prop="plannedArrivalTime">
              <el-date-picker
                v-model="formData.plannedArrivalTime"
                type="datetime"
                placeholder="选择计划到达时间"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="实际起飞" prop="actualDepartureTime">
              <el-date-picker
                v-model="formData.actualDepartureTime"
                type="datetime"
                placeholder="选择实际起飞时间"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="实际到达" prop="actualArrivalTime">
              <el-date-picker
                v-model="formData.actualArrivalTime"
                type="datetime"
                placeholder="选择实际到达时间"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
        </el-row>
      </el-tab-pane>

      <el-tab-pane label="航班详情" name="details">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="航班状态" prop="flightStatus">
              <el-select
                v-model="formData.flightStatus"
                placeholder="选择航班状态"
                style="width: 100%"
              >
                <el-option
                  v-for="status in statusOptions"
                  :key="status.value"
                  :label="status.label"
                  :value="status.value"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="机型" prop="aircraftType">
              <el-input
                v-model="formData.aircraftType"
                placeholder="如: A320, B737"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="登机口" prop="gate">
              <el-input
                v-model="formData.gate"
                placeholder="登机口号"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="航站楼" prop="terminal">
              <el-input
                v-model="formData.terminal"
                placeholder="航站楼"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="经度" prop="longitude">
              <el-input-number
                v-model="formData.longitude"
                :min="-180"
                :max="180"
                :step="0.0001"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="纬度" prop="latitude">
              <el-input-number
                v-model="formData.latitude"
                :min="-90"
                :max="90"
                :step="0.0001"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="速度(节)" prop="currentSpeed">
              <el-input-number
                v-model="formData.currentSpeed"
                :min="0"
                :max="1000"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="高度(英尺)" prop="currentAltitude">
              <el-input-number
                v-model="formData.currentAltitude"
                :min="0"
                :max="50000"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
        </el-row>
      </el-tab-pane>

      <el-tab-pane label="AI分析" name="ai" v-if="props.formData?.flightNumber">
        <div class="ai-analysis">
          <AIPredictionCard
            :flight-number="props.formData.flightNumber"
            :flight-details="formData"
            class="ai-card"
          />

          <el-divider>AI摘要生成</el-divider>

          <el-form-item label="航班描述" prop="description">
            <el-input
              v-model="descriptionText"
              type="textarea"
              :rows="4"
              placeholder="输入航班描述信息，AI将自动生成摘要"
              @input="debouncedSummarize"
            />
          </el-form-item>

          <div v-if="aiSummary" class="ai-summary">
            <h4>AI摘要:</h4>
            <p>{{ aiSummary }}</p>
            <el-button
              type="primary"
              size="small"
              @click="applySummary"
              :loading="summarizing"
            >
              应用摘要
            </el-button>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>
  </el-form>
</template>

<script setup>
import { ref, reactive, watch, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { debounce } from 'lodash'
import { aiApi } from '@/api'
import AIPredictionCard from '@/components/ai/AIPredictionCard.vue'

const props = defineProps({
  formData: {
    type: Object,
    default: () => ({})
  }
})

const emit = defineEmits(['success', 'cancel'])

const formRef = ref()
const activeTab = ref('basic')
const submitting = ref(false)
const summarizing = ref(false)

const formData = reactive({
  flightNumber: '',
  airlineCode: '',
  airlineName: '',
  departureAirportCode: '',
  departureAirportName: '',
  arrivalAirportCode: '',
  arrivalAirportName: '',
  plannedDepartureTime: '',
  plannedArrivalTime: '',
  actualDepartureTime: '',
  actualArrivalTime: '',
  flightStatus: 'SCHEDULED',
  aircraftType: '',
  gate: '',
  terminal: '',
  latitude: null,
  longitude: null,
  currentSpeed: null,
  currentAltitude: null
})

const descriptionText = ref('')
const aiSummary = ref('')

const airports = [
  { code: 'PEK', name: '北京首都国际机场' },
  { code: 'PVG', name: '上海浦东国际机场' },
  { code: 'CAN', name: '广州白云国际机场' },
  { code: 'SZX', name: '深圳宝安国际机场' },
  { code: 'CTU', name: '成都双流国际机场' },
  { code: 'CKG', name: '重庆江北国际机场' },
  { code: 'XIY', name: '西安咸阳国际机场' },
  { code: 'KMG', name: '昆明长水国际机场' },
  { code: 'HGH', name: '杭州萧山国际机场' },
  { code: 'NKG', name: '南京禄口国际机场' }
]

const statusOptions = [
  { value: 'SCHEDULED', label: '计划中' },
  { value: 'DELAYED', label: '延误' },
  { value: 'BOARDING', label: '登机中' },
  { value: 'DEPARTED', label: '已起飞' },
  { value: 'IN_AIR', label: '飞行中' },
  { value: 'LANDED', label: '已降落' },
  { value: 'ARRIVED', label: '已到达' },
  { value: 'CANCELLED', label: '已取消' }
]

const rules = {
  flightNumber: [
    { required: true, message: '请输入航班号', trigger: 'blur' },
    { pattern: /^[A-Z0-9]{2,6}$/, message: '航班号格式不正确', trigger: 'blur' }
  ],
  airlineName: [
    { required: true, message: '请输入航空公司', trigger: 'blur' }
  ],
  departureAirportCode: [
    { required: true, message: '请选择出发机场', trigger: 'change' }
  ],
  arrivalAirportCode: [
    { required: true, message: '请选择到达机场', trigger: 'change' }
  ],
  plannedDepartureTime: [
    { required: true, message: '请选择计划起飞时间', trigger: 'change' }
  ],
  plannedArrivalTime: [
    { required: true, message: '请选择计划到达时间', trigger: 'change' }
  ],
  flightStatus: [
    { required: true, message: '请选择航班状态', trigger: 'change' }
  ]
}

const debouncedSummarize = debounce(async () => {
  if (descriptionText.value.length < 10) {
    aiSummary.value = ''
    return
  }

  summarizing.value = true
  try {
    const res = await aiApi.summarizeStatus({ text: descriptionText.value })
    if (res.data) {
      aiSummary.value = res.data.ai_summary
    }
  } catch (error) {
    console.error('AI摘要生成失败:', error)
    ElMessage.error('摘要生成失败')
  } finally {
    summarizing.value = false
  }
}, 1000)

const handleDepartureAirportChange = (code) => {
  const airport = airports.find(a => a.code === code)
  if (airport) {
    formData.departureAirportName = airport.name
  }
}

const handleArrivalAirportChange = (code) => {
  const airport = airports.find(a => a.code === code)
  if (airport) {
    formData.arrivalAirportName = airport.name
  }
}

const applySummary = () => {
  if (aiSummary.value) {
    ElMessage.success('AI摘要已应用')
  }
}

const submit = async () => {
  if (!formRef.value) return false

  try {
    await formRef.value.validate()

    submitting.value = true

    const formattedData = { ...formData }
    const timeFields = [
      'plannedDepartureTime',
      'plannedArrivalTime',
      'actualDepartureTime',
      'actualArrivalTime'
    ]

    timeFields.forEach(field => {
      if (formattedData[field] && formattedData[field] instanceof Date) {
        formattedData[field] = formattedData[field].toISOString()
      }
    })

    emit('success', formattedData)
    return formattedData
  } catch (error) {
    console.error('表单验证失败:', error)
    if (error instanceof Error) {
      ElMessage.error('表单验证失败')
    }
    return false
  } finally {
    submitting.value = false
  }
}

const resetForm = () => {
  if (formRef.value) {
    formRef.value.resetFields()
  }
  Object.keys(formData).forEach(key => {
    formData[key] = props.formData?.[key] || ''
  })
  aiSummary.value = ''
  descriptionText.value = ''
}

watch(() => props.formData, (newData) => {
  if (newData) {
    Object.keys(formData).forEach(key => {
      formData[key] = newData[key] || ''
    })
  }
}, { immediate: true })

onMounted(() => {
  resetForm()
})

defineExpose({
  submit,
  resetForm
})
</script>

<style lang="scss" scoped>
.ai-analysis {
  .ai-card {
    margin-bottom: 20px;
  }

  .ai-summary {
    margin-top: 20px;
    padding: 15px;
    background-color: #f5f7fa;
    border-radius: 4px;
    border: 1px solid #e4e7ed;

    h4 {
      margin: 0 0 10px 0;
      color: #333;
    }

    p {
      margin: 0 0 10px 0;
      color: #666;
      line-height: 1.5;
    }
  }
}
</style>

