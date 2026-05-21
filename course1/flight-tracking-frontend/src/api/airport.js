import request from './request'

export const airportApi = {
  getAirportList(params) {
    return request({
      url: '/api/airport/list',
      method: 'get',
      params
    })
  },
  getAirportDetail(airportCode) {
    return request({
      url: `/api/airport/${airportCode}`,
      method: 'get'
    })
  }
}

