<template>
  <div id="app">
    <el-container class="app-container">
      <el-aside :width="sidebarWidth" class="sidebar">
        <Sidebar />
      </el-aside>
      <el-container>
        <el-header height="60px" class="header">
          <Header />
        </el-header>
        <el-main class="main-content">
          <router-view v-slot="{ Component }">
            <transition name="fade" mode="out-in">
              <component :is="Component" />
            </transition>
          </router-view>
        </el-main>
        <el-footer height="40px" class="footer">
          <Footer />
        </el-footer>
      </el-container>
    </el-container>

    <!-- 移动端遮罩层 -->
    <div
      v-if="isMobile && !sidebarCollapsed"
      class="mobile-overlay"
      @click="appStore.toggleSidebar"
    />
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useAppStore } from '@/store'
import Sidebar from '@/components/layout/Sidebar.vue'
import Header from '@/components/layout/Header.vue'
import Footer from '@/components/layout/Footer.vue'

const appStore = useAppStore()
const sidebarCollapsed = computed(() => appStore.sidebarCollapsed)

const isMobile = computed(() => window.innerWidth < 768)
const sidebarWidth = computed(() => sidebarCollapsed.value ? '64px' : '200px')
</script>

<style lang="scss">
#app {
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Hiragino Sans GB',
    'Microsoft YaHei', '微软雅黑', Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  height: 100vh;
  overflow: hidden;
}

.app-container {
  height: 100vh;
}

.sidebar {
  background-color: var(--sidebar-bg) !important;
  color: #bfcbd9;
  box-shadow: 2px 0 6px rgba(0, 21, 41, 0.35);
  overflow: hidden;
  transition: width 0.3s ease;
}

.header {
  background-color: var(--header-bg);
  border-bottom: 1px solid var(--border-color);
  display: flex;
  align-items: center;
  padding: 0 24px;
  box-shadow: var(--shadow-sm);
}

.main-content {
  background-color: var(--bg-color);
  padding: 20px;
  overflow: auto;
}

.footer {
  background-color: var(--header-bg);
  border-top: 1px solid var(--border-color);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  font-size: 12px;
}

// 移动端遮罩
.mobile-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.4);
  z-index: 99;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

// 响应式：小屏幕移除内边距
@media (max-width: 768px) {
  .main-content {
    padding: 12px;
  }
  .header {
    padding: 0 12px;
  }
}
</style>
