<template>
  <div class="airport-view">
    <el-input v-model="keyword" placeholder="搜索机场" clearable class="search" />
    <div class="airport-list">
      <div
        v-for="airport in filteredAirports"
        :key="airport.code"
        class="airport-item"
        @click="handleSelect(airport)"
      >
        <div class="name">{{ airport.name }}</div>
        <div class="meta">{{ airport.code }} · {{ airport.flights || 0 }} 班</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'

const props = defineProps({
  airports: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['select-airport'])

const keyword = ref('')

const filteredAirports = computed(() => {
  if (!keyword.value) return props.airports
  const kw = keyword.value.toLowerCase()
  return props.airports.filter(item =>
    item.name.toLowerCase().includes(kw) ||
    item.code.toLowerCase().includes(kw)
  )
})

const handleSelect = (airport) => {
  emit('select-airport', airport)
}
</script>

<style scoped lang="scss">
.airport-view {
  .search {
    margin-bottom: 12px;
  }

  .airport-list {
    max-height: 500px;
    overflow-y: auto;

    .airport-item {
      padding: 10px;
      border-bottom: 1px solid #f0f0f0;
      cursor: pointer;

      &:hover {
        background-color: #f5f7fa;
      }

      .name {
        font-weight: 600;
        color: #333;
      }

      .meta {
        font-size: 12px;
        color: #888;
        margin-top: 4px;
      }
    }
  }
}
</style>

