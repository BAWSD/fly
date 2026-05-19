import request from './request'

export const flightApi = {
  getFlightList(params) {
    return request({
      url: '/api/flight/info/list',
      method: 'get',
      params
    })
  },
  getFlightDetail(flightNumber) {
    return request({
      url: `/api/flight/info/${flightNumber}`,
      method: 'get'
    })
  },
  addFlight(data) {
    return request({
      url: '/api/flight/info',
      method: 'post',
      data
    })
  },
  updateFlight(flightNumber, data) {
    return request({
      url: `/api/flight/info/${flightNumber}`,
      method: 'put',
      data
    })
  },
  deleteFlight(flightNumber) {
    return request({
      url: `/api/flight/info/${flightNumber}`,
      method: 'delete'
    })
  },
  updateFlightStatus(flightNumber, status) {
    return request({
      url: `/api/flight/info/${flightNumber}/status`,
      method: 'put',
      params: { status }
    })
  },
  batchUpdateStatus(flightNumbers, status) {
    return request({
      url: '/api/flight/info/batch/status',
      method: 'put',
      params: { status },
      data: flightNumbers
    })
  },
  getFlightStats() {
    return request({
      url: '/api/flight/info/stats/count-by-status',
      method: 'get'
    })
  },
  searchFlights(keyword) {
    return request({
      url: '/api/flight/info/search',
      method: 'get',
      params: { keyword }
    })
  },
  getAirportFlights(airportCode, startTime, endTime) {
    return request({
      url: `/api/flight/info/airport/${airportCode}`,
      method: 'get',
      params: { startTime, endTime }
    })
  }
}

