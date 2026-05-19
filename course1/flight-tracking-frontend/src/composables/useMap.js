import { ref } from 'vue'

export const useMap = () => {
  const mapReady = ref(false)

  const setMapReady = (ready) => {
    mapReady.value = ready
  }

  return {
    mapReady,
    setMapReady
  }
}

