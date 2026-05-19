<template>
  <el-form :model="model" label-width="80px">
    <el-form-item label="航班号">
      <el-input v-model="model.flightNumber" placeholder="输入航班号" clearable />
    </el-form-item>
    <el-form-item>
      <el-button type="primary" @click="$emit('search')">搜索</el-button>
      <el-button @click="$emit('reset')">重置</el-button>
    </el-form-item>
  </el-form>
</template>

<script setup>
defineProps({
  model: {
    type: Object,
    default: () => ({})
  }
})
</script>

