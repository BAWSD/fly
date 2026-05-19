import axios from 'axios'

// Use API gateway as default so frontend calls go through `VITE_API_BASE_URL`.
// Gateway routes /api/ai/** to the AI service and strips the prefix.
const aiService = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 30000
})

export const aiApi = {
  predictDelay(flightNumber, features) {
    return aiService({
      url: '/api/ai/predict_delay',
      method: 'post',
      data: {
        flight_number: flightNumber,
        features: features
      }
    })
  },
  summarizeStatus(text) {
    return aiService({
      url: '/api/ai/summarize_status',
      method: 'post',
      data: { text }
    })
  },
  generateImprovement(data) {
    return aiService({
      url: '/api/ai/generate_improvement',
      method: 'post',
      data
    })
  },
  analyzeWeatherImpact(airportCode, date) {
    return aiService({
      url: '/api/ai/weather_impact',
      method: 'post',
      data: {
        airport_code: airportCode,
        date: date
      }
    })
  }
}

