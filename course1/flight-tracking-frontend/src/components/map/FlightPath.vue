<template>
  <div class="flight-path">
    <slot />
  </div>
</template>

<script setup>
defineProps({
  path: {
    type: Array,
    default: () => []
  }
})
</script>

<style scoped>
.flight-path {
  width: 100%;
  height: 100%;
}
</style>

