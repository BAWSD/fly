<template>
  <div class="flight-list-view">
    <el-card shadow="never" class="filter-card">
      <el-form :model="filterForm" label-width="80px">
        <el-row :gutter="20">
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="航班号">
              <el-input
                v-model.trim="filterForm.flightNumber"
                placeholder="输入航班号"
                clearable
                @keyup.enter="handleSearch"
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="出发机场">
              <el-input
                v-model.trim="filterForm.departureAirport"
                placeholder="三字码或名称"
                clearable
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="到达机场">
              <el-input
                v-model.trim="filterForm.arrivalAirport"
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
                v-model.trim="filterForm.airline"
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
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card shadow="never" class="table-card">
      <template #header>
        <div class="table-header">
          <div class="header-left">
            <span>航班列表</span>
            <div class="header-hint">支持筛选、查看详情和快速新建航班</div>
          </div>
          <div class="header-actions">
            <el-button type="primary" @click="handleAdd">
              <el-icon><Plus /></el-icon>新建航班
            </el-button>
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
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <div class="action-buttons">
              <el-button type="primary" link size="small" @click="viewDetail(row.flightNumber)">
                详情
              </el-button>
              <el-divider direction="vertical" />
              <el-button type="warning" link size="small" @click="handleEdit(row)">
                编辑
              </el-button>
            </div>
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
      width="860px"
      destroy-on-close
      align-center
    >
      <div class="create-panel">
        <div class="create-panel__form">
          <FlightForm
            v-if="dialogVisible"
            ref="flightFormRef"
            :form-data="currentFlight"
            @success="handleFormSuccess"
          />
        </div>
        <div class="create-panel__side">
          <el-card shadow="never" class="create-tip-card">
            <template #header>
              <span>新建提示</span>
            </template>
            <ul>
              <li>航班号会自动转大写，并从前两位提取航空公司代码。</li>
              <li>保存前会先检查航班号是否重复，避免无效提交。</li>
              <li>保存成功后会同步写入实时状态，详情页可直接查看。</li>
            </ul>
          </el-card>

          <el-card shadow="never" class="create-tip-card">
            <template #header>
              <span>推荐流程</span>
            </template>
            <ol>
              <li>填写基础信息</li>
              <li>选择状态与时间</li>
              <li>点击“确认”完成创建</li>
            </ol>
          </el-card>
        </div>
      </div>
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
import { flightApi, statusApi } from '@/api'
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
    const normalizedStatus = Array.isArray(filterForm.status) && filterForm.status.length > 0
      ? filterForm.status.join(',')
      : undefined
    const params = {
      pageNum: pagination.current,
      pageSize: pagination.size,
      flightNumber: filterForm.flightNumber?.trim(),
      departureAirport: filterForm.departureAirport?.trim(),
      arrivalAirport: filterForm.arrivalAirport?.trim(),
      airline: filterForm.airline?.trim(),
      startTime: filterForm.startTime,
      endTime: filterForm.endTime,
      status: normalizedStatus
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

    const existingFlights = await flightApi.searchFlights(payload.flightNumber)
    const duplicate = (existingFlights.data || []).find(item => item.flightNumber === payload.flightNumber)
    if (!currentFlight.value?.flightNumber && duplicate) {
      ElMessage.warning('该航班号已存在，请修改后再保存')
      return
    }

    if (currentFlight.value?.flightNumber) {
      await flightApi.updateFlight(currentFlight.value.flightNumber, payload)
    } else {
      await flightApi.addFlight(payload)
    }

    try {
      const detail = await flightApi.getFlightDetail(payload.flightNumber)
      const flightInfoId = detail.data?.id
      await statusApi.saveOrUpdateStatus({
        flightInfoId,
        flightNumber: payload.flightNumber,
        currentStatus: payload.flightStatus,
        delayMinutes: payload.delayMinutes,
        currentAltitude: payload.currentAltitude,
        currentSpeed: payload.currentSpeed,
        latitude: payload.latitude,
        longitude: payload.longitude,
        description: payload.description,
        lastUpdated: new Date().toISOString()
      })
    } catch (error) {
      console.error('同步实时状态失败:', error)
      ElMessage.warning('航班已保存，但实时状态同步失败')
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
      align-items: flex-start;

      .header-left {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 6px;

        .header-hint {
          font-size: 12px;
          color: #8c8c8c;
          font-weight: 400;
        }
      }

      span {
        font-weight: bold;
        font-size: 16px;
      }

      .header-actions {
        display: flex;
        gap: 10px;
        margin-top: 2px;
      }
    }

    .time-cell {
      font-size: 12px;
      line-height: 1.4;

      div {
        margin-bottom: 2px;
      }
    }

    .action-buttons {
      display: flex;
      align-items: center;
      gap: 0;
      white-space: nowrap;

      .el-button {
        padding: 0 4px;
        font-size: 13px;
      }
    }

    .pagination-container {
      display: flex;
      justify-content: center;
      margin-top: 20px;
    }
  }

  .create-panel {
    display: grid;
    grid-template-columns: minmax(0, 1.6fr) minmax(280px, 0.8fr);
    gap: 16px;
    align-items: start;

    .create-panel__form {
      min-width: 0;
    }

    .create-panel__side {
      display: grid;
      gap: 16px;
    }

    .create-tip-card {
      ul, ol {
        margin: 0;
        padding-left: 18px;
        color: #666;
        line-height: 1.8;
      }

      li + li {
        margin-top: 4px;
      }
    }
  }

  @media (max-width: 960px) {
    .create-panel {
      grid-template-columns: 1fr;
    }
  }
}
</style>
