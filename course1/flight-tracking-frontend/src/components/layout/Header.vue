<template>
  <div class="header-bar">
    <div class="left">
      <el-button text @click="toggleSidebar" class="menu-btn">
        <el-icon :size="20"><Fold /></el-icon>
      </el-button>
      <span class="title">航班信息跟踪平台</span>
    </div>
    <div class="right">
      <div class="header-time">
        <el-icon :size="16"><Clock /></el-icon>
        <span>{{ currentTime }}</span>
      </div>
      <el-tag size="small" type="success" effect="dark" class="status-tag">
        <el-icon :size="12"><Monitor /></el-icon>
        系统在线
      </el-tag>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { Fold, Clock, Monitor } from '@element-plus/icons-vue'
import { useAppStore } from '@/store'

const appStore = useAppStore()
const currentTime = ref('')

let timer = null

const updateTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('zh-CN', { hour12: false })
}

const toggleSidebar = () => {
  appStore.toggleSidebar()
}

onMounted(() => {
  updateTime()
  timer = setInterval(updateTime, 1000)
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>

<style lang="scss" scoped>
.header-bar {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;

  .left {
    display: flex;
    align-items: center;
    gap: 12px;

    .menu-btn {
      &:hover {
        background: rgba(67, 97, 238, 0.08) !important;
      }
    }

    .title {
      font-size: 18px;
      font-weight: 700;
      background: linear-gradient(135deg, #4361ee, #6c83f7);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
  }

  .right {
    display: flex;
    align-items: center;
    gap: 16px;

    .header-time {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 14px;
      color: #6b7280;
      font-variant-numeric: tabular-nums;
    }

    .status-tag {
      display: flex;
      align-items: center;
      gap: 4px;
      padding: 2px 10px !important;
    }
  }
}
</style>
