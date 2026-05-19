import { ref } from 'vue'
import { flightApi } from '@/api'

export const useFlightData = () => {
  const flights = ref([])
  const loading = ref(false)

  const loadFlights = async (params = {}) => {
    loading.value = true
    try {
      const res = await flightApi.getFlightList(params)
      flights.value = res.data?.records || []
    } finally {
      loading.value = false
    }
  }

  return {
    flights,
    loading,
    loadFlights
  }
}

