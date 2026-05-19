import request from './request'

export const statusApi = {
  getRealTimeStatus(flightNumber) {
    return request({
      url: `/api/flight/status/${flightNumber}/realtime`,
      method: 'get'
    })
  },
  getFlightTrack(flightNumber, startTime, endTime) {
    return request({
      url: `/api/flight/status/${flightNumber}/track`,
      method: 'get',
      params: { startTime, endTime }
    })
  },
  getDelayStats(days = 7) {
    return request({
      url: '/api/flight/status/stats/delay',
      method: 'get',
      params: { days }
    })
  },
  getActiveFlights() {
    return request({
      url: '/api/flight/status/active',
      method: 'get'
    })
  }
}

