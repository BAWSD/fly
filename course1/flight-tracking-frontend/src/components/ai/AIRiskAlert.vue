<template>
  <el-alert
    :title="title"
    :type="type"
    :description="description"
    show-icon
    :closable="false"
  />
</template>

<script setup>
defineProps({
  title: {
    type: String,
    default: '风险提示'
  },
  description: {
    type: String,
    default: '暂无高风险提示'
  },
  type: {
    type: String,
    default: 'info'
  }
})
</script>

