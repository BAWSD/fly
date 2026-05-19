<template>
  <el-card shadow="hover">
    <template #header>
      <div class="header">AI 摘要</div>
    </template>
    <div class="content">
      <p v-if="summary">{{ summary }}</p>
      <el-empty v-else description="暂无摘要" />
    </div>
  </el-card>
</template>

<script setup>
defineProps({
  summary: {
    type: String,
    default: ''
  }
})
</script>

<style scoped>
.header {
  font-weight: 600;
}
</style>

