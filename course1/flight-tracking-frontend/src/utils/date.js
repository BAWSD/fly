import { format, formatDistance, formatRelative, parseISO, differenceInMinutes } from 'date-fns'
import { zhCN } from 'date-fns/locale'

export const dateUtils = {
  formatDate(date, formatStr = 'yyyy-MM-dd HH:mm:ss') {
    if (!date) return ''
    return format(typeof date === 'string' ? parseISO(date) : date, formatStr)
  },
  formatRelativeTime(date, baseDate = new Date()) {
    if (!date) return ''
    return formatRelative(typeof date === 'string' ? parseISO(date) : date, baseDate, { locale: zhCN })
  },
  formatTimeAgo(date) {
    if (!date) return ''
    return formatDistance(typeof date === 'string' ? parseISO(date) : date, new Date(), {
      addSuffix: true,
      locale: zhCN
    })
  },
  getMinutesDifference(startDate, endDate) {
    if (!startDate || !endDate) return 0
    const start = typeof startDate === 'string' ? parseISO(startDate) : startDate
    const end = typeof endDate === 'string' ? parseISO(endDate) : endDate
    return differenceInMinutes(end, start)
  },
  getFlightStatusText(status) {
    const statusMap = {
      SCHEDULED: '计划中',
      ON_TIME: '准点',
      DELAYED: '延误',
      BOARDING: '登机中',
      DEPARTED: '已起飞',
      IN_AIR: '飞行中',
      LANDED: '已降落',
      ARRIVED: '已到达',
      CANCELLED: '已取消',
      DIVERTED: '已改航',
      UNKNOWN: '状态未知'
    }
    return statusMap[status] || status || '--'
  },
  getFlightStatusColor(status) {
    const colorMap = {
      SCHEDULED: 'info',
      ON_TIME: 'success',
      DELAYED: 'warning',
      BOARDING: 'primary',
      DEPARTED: 'success',
      IN_AIR: 'success',
      LANDED: 'success',
      ARRIVED: 'success',
      CANCELLED: 'danger',
      DIVERTED: 'warning',
      UNKNOWN: 'info'
    }
    return colorMap[status] || 'info'
  },
  calculateDelay(plannedTime, actualTime) {
    if (!plannedTime || !actualTime) return 0
    const planned = typeof plannedTime === 'string' ? parseISO(plannedTime) : plannedTime
    const actual = typeof actualTime === 'string' ? parseISO(actualTime) : actualTime
    return differenceInMinutes(actual, planned)
  }
}

