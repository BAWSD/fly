<template>
  <div class="flight-list-view">
    <el-card shadow="never" class="filter-card">
      <el-form :model="filterForm" label-width="80px">
        <el-row :gutter="20">
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="航班号">
              <el-input
                v-model="filterForm.flightNumber"
                placeholder="输入航班号"
                clearable
                @keyup.enter="handleSearch"
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="出发机场">
              <el-input
                v-model="filterForm.departureAirport"
                placeholder="三字码或名称"
                clearable
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="到达机场">
              <el-input
                v-model="filterForm.arrivalAirport"
                placeholder="三字码或名称"
                clearable
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="航班状态">
              <el-select
                v-model="filterForm.status"
                placeholder="选择状态"
                clearable
                multiple
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
        </el-row>
        <el-row :gutter="20">
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="开始时间">
              <el-date-picker
                v-model="filterForm.startTime"
                type="datetime"
                placeholder="选择开始时间"
                style="width: 100%"
                value-format="YYYY-MM-DDTHH:mm:ss"
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="结束时间">
              <el-date-picker
                v-model="filterForm.endTime"
                type="datetime"
                placeholder="选择结束时间"
                style="width: 100%"
                value-format="YYYY-MM-DDTHH:mm:ss"
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="航空公司">
              <el-input
                v-model="filterForm.airline"
                placeholder="输入航空公司"
                clearable
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item>
              <el-button type="primary" @click="handleSearch">
                <el-icon><Search /></el-icon>搜索
              </el-button>
              <el-button @click="handleReset">
                <el-icon><Refresh /></el-icon>重置
              </el-button>
              <el-button type="success" @click="handleAdd">
                <el-icon><Plus /></el-icon>添加航班
              </el-button>
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card shadow="never" class="table-card">
      <template #header>
        <div class="table-header">
          <span>航班列表</span>
          <div class="header-actions">
            <el-button @click="refreshData" :loading="loading">
              <el-icon><Refresh /></el-icon>刷新
            </el-button>
          </div>
        </div>
      </template>

      <el-table
        v-loading="loading"
        :data="tableData"
        style="width: 100%"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="flightNumber" label="航班号" width="120">
          <template #default="{ row }">
            <el-link type="primary" @click="viewDetail(row.flightNumber)" :underline="false">
              {{ row.flightNumber }}
            </el-link>
          </template>
        </el-table-column>
        <el-table-column prop="airlineName" label="航空公司" width="120" />
        <el-table-column prop="departureAirportName" label="出发机场" width="150" />
        <el-table-column prop="arrivalAirportName" label="到达机场" width="150" />
        <el-table-column prop="plannedDepartureTime" label="计划时间" width="180">
          <template #default="{ row }">
            <div class="time-cell">
              <div>起飞: {{ dateUtils.formatDate(row.plannedDepartureTime) }}</div>
              <div>到达: {{ dateUtils.formatDate(row.plannedArrivalTime) }}</div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="flightStatus" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="dateUtils.getFlightStatusColor(row.flightStatus)" effect="dark" size="small">
              {{ dateUtils.getFlightStatusText(row.flightStatus) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{ row }">
            <el-button type="text" size="small" @click="viewDetail(row.flightNumber)" style="color: #409EFF">
              详情
            </el-button>
            <el-button type="warning" link size="small" @click="handleEdit(row)">
              编辑
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-container">
        <el-pagination
          v-model:current-page="pagination.current"
          v-model:page-size="pagination.size"
          :page-sizes="[10, 20, 50, 100]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="600px"
      destroy-on-close
    >
      <FlightForm
        v-if="dialogVisible"
        ref="flightFormRef"
        :form-data="currentFlight"
        @success="handleFormSuccess"
      />
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit" :loading="submitting">
            确认
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Search, Refresh, Plus } from '@element-plus/icons-vue'
import { flightApi } from '@/api'
import { dateUtils } from '@/utils/date'
import FlightForm from '@/components/flight/FlightForm.vue'

const router = useRouter()

const loading = ref(false)
const dialogVisible = ref(false)
const submitting = ref(false)
const tableData = ref([])
const selectedRows = ref([])
const currentFlight = ref(null)
const flightFormRef = ref()

const pagination = reactive({
  current: 1,
  size: 20,
  total: 0
})

const filterForm = reactive({
  flightNumber: '',
  departureAirport: '',
  arrivalAirport: '',
  status: [],
  startTime: '',
  endTime: '',
  airline: ''
})

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

const dialogTitle = computed(() => {
  return currentFlight.value ? '编辑航班' : '添加航班'
})

const loadFlightData = async () => {
  loading.value = true
  try {
    const params = {
      pageNum: pagination.current,
      pageSize: pagination.size,
      ...filterForm
    }

    Object.keys(params).forEach(key => {
      if (params[key] === '' || params[key] === null || params[key] === undefined) {
        delete params[key]
      }
    })

    const res = await flightApi.getFlightList(params)

    if (res.data) {
      tableData.value = res.data.records || []
      pagination.total = res.data.total || 0
    }
  } catch (error) {
    console.error('加载航班数据失败:', error)
    ElMessage.error('加载航班数据失败')
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pagination.current = 1
  loadFlightData()
}

const handleReset = () => {
  Object.keys(filterForm).forEach(key => {
    if (Array.isArray(filterForm[key])) {
      filterForm[key] = []
    } else {
      filterForm[key] = ''
    }
  })
  pagination.current = 1
  loadFlightData()
}

const refreshData = () => {
  loadFlightData()
  ElMessage.success('数据已刷新')
}

const handleSizeChange = (size) => {
  pagination.size = size
  pagination.current = 1
  loadFlightData()
}

const handleCurrentChange = (page) => {
  pagination.current = page
  loadFlightData()
}

const handleSelectionChange = (selection) => {
  selectedRows.value = selection
}

const viewDetail = (flightNumber) => {
  router.push({ name: 'FlightDetail', params: { flightNumber } })
}

const handleAdd = () => {
  currentFlight.value = null
  dialogVisible.value = true
}

const handleEdit = (row) => {
  currentFlight.value = { ...row }
  dialogVisible.value = true
}

const handleSubmit = async () => {
  if (!flightFormRef.value) return

  submitting.value = true
  try {
    const payload = await flightFormRef.value.submit()
    if (!payload) return

    if (currentFlight.value?.flightNumber) {
      await flightApi.updateFlight(currentFlight.value.flightNumber, payload)
    } else {
      await flightApi.addFlight(payload)
    }

    dialogVisible.value = false
    loadFlightData()
    ElMessage.success('保存成功')
  } catch (error) {
    console.error('表单提交失败:', error)
    ElMessage.error('保存失败')
  } finally {
    submitting.value = false
  }
}

const handleFormSuccess = () => {
  dialogVisible.value = false
  loadFlightData()
}

onMounted(() => {
  loadFlightData()
})
</script>

<style lang="scss" scoped>
.flight-list-view {
  .filter-card {
    margin-bottom: 20px;
  }

  .table-card {
    .table-header {
      display: flex;
      justify-content: space-between;
      align-items: center;

      span {
        font-weight: bold;
        font-size: 16px;
      }

      .header-actions {
        display: flex;
        gap: 10px;
      }
    }

    .time-cell {
      font-size: 12px;
      line-height: 1.4;

      div {
        margin-bottom: 2px;
      }
    }

    .pagination-container {
      display: flex;
      justify-content: center;
      margin-top: 20px;
    }
  }
}
</style>
