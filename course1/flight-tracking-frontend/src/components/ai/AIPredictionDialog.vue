<template>
  <el-dialog v-model="visible" title="AI 预测分析" width="800px">
    <AIPredictionCard
      :flight-number="flight?.flightNumber"
      :flight-details="flight"
      @refresh="handleRefresh"
    />
    <template #footer>
      <el-button @click="visible = false">关闭</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { computed } from 'vue'
import AIPredictionCard from './AIPredictionCard.vue'

const props = defineProps({
  modelValue: Boolean,
  flight: {
    type: Object,
    default: () => ({})
  }
})

const emit = defineEmits(['update:modelValue', 'update'])

const visible = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val)
})

const handleRefresh = (data) => {
  emit('update', data)
}
</script>

