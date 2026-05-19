<template>
  <el-menu
    :default-active="activeMenu"
    :collapse="isCollapse"
    class="sidebar-menu"
    background-color="#304156"
    text-color="#bfcbd9"
    active-text-color="#ffffff"
    router
  >
    <div class="logo">
      <h2 v-if="!isCollapse">航班跟踪平台</h2>
      <h3 v-else>FT</h3>
    </div>
    <template v-for="route in routes" :key="route.path">
      <!-- 有子菜单的菜单项 -->
      <el-sub-menu
        v-if="route.children && !route.meta?.hidden"
        :index="route.path"
      >
        <template #title>
          <el-icon v-if="route.meta?.icon">
            <component :is="route.meta.icon" />
          </el-icon>
          <span>{{ route.meta?.title }}</span>
        </template>
        <el-menu-item
          v-for="child in route.children"
          :key="child.path"
          :index="`${route.path}/${child.path}`"
          v-show="!child.meta?.hidden"
        >
          <template #title>{{ child.meta?.title }}</template>
        </el-menu-item>
      </el-sub-menu>

      <!-- 无子菜单的菜单项 -->
      <el-menu-item
        v-else-if="!route.meta?.hidden"
        :index="route.path"
        :route="route"
      >
        <el-icon v-if="route.meta?.icon">
          <component :is="route.meta.icon" />
        </el-icon>
        <template #title>{{ route.meta?.title }}</template>
      </el-menu-item>
    </template>

    <!-- 折叠/展开按钮 -->
    <div class="collapse-btn" @click="appStore.toggleSidebar">
      <el-icon :class="{ rotated: isCollapse }">
        <Fold v-if="!isCollapse" />
        <Expand v-else />
      </el-icon>
    </div>
  </el-menu>
</template>

<script setup>
import { computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { useAppStore } from '@/store'
import routes from '@/router/routes'
import { Fold, Expand } from '@element-plus/icons-vue'

const route = useRoute()
const appStore = useAppStore()

const activeMenu = computed(() => route.path)
const isCollapse = computed(() => appStore.sidebarCollapsed)

// 响应式：窗口宽度小于768px时自动折叠侧边栏
const handleResize = () => {
  if (window.innerWidth < 768) {
    if (!appStore.sidebarCollapsed) {
      appStore.sidebarCollapsed = true
    }
  }
}

onMounted(() => {
  window.addEventListener('resize', handleResize)
  handleResize()
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
})
</script>

<style lang="scss" scoped>
.sidebar-menu {
  border-right: none;
  height: 100%;
  display: flex;
  flex-direction: column;
  transition: width 0.3s;

  .logo {
    height: 60px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-bottom: 1px solid #2b3748;
    flex-shrink: 0;

    h2, h3 {
      margin: 0;
      color: #fff;
      font-weight: 600;
    }

    h2 {
      font-size: 18px;
    }

    h3 {
      font-size: 20px;
    }
  }

  .el-menu-item {
    height: 56px;
    line-height: 56px;

    &:hover {
      background-color: #263445 !important;
    }

    &.is-active {
      background-color: #1890ff !important;
    }
  }

  .el-icon {
    font-size: 18px;
    margin-right: 8px;
  }

  .collapse-btn {
    margin-top: auto;
    height: 48px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-top: 1px solid #2b3748;
    cursor: pointer;
    color: #bfcbd9;
    flex-shrink: 0;

    &:hover {
      background-color: #263445;
    }

    .el-icon {
      transition: transform 0.3s;
      margin-right: 0;

      &.rotated {
        transform: rotate(180deg);
      }
    }
  }
}
</style>
