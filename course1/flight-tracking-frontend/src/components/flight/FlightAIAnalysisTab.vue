<template>
  <div class="ai-analysis-tab">
    <AIPredictionCard
      :flight-number="flight?.flightNumber"
      :flight-details="flight"
    />
    <div class="summary-section">
      <AISummaryCard :summary="summary" />
      <AIRiskAlert />
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import AIPredictionCard from '@/components/ai/AIPredictionCard.vue'
import AISummaryCard from '@/components/ai/AISummaryCard.vue'
import AIRiskAlert from '@/components/ai/AIRiskAlert.vue'

defineProps({
  flight: {
    type: Object,
    default: () => ({})
  }
})

const summary = ref('')
</script>

<style scoped>
.summary-section {
  margin-top: 20px;
  display: grid;
  gap: 12px;
}
</style>

