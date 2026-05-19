import { defineStore } from 'pinia'

export const useAppStore = defineStore('app', {
  state: () => ({
    sidebarCollapsed: JSON.parse(localStorage.getItem('sidebarCollapsed') || 'false'),
    theme: localStorage.getItem('theme') || 'light',
    userInfo: JSON.parse(localStorage.getItem('userInfo') || 'null'),
    flightStats: null,
    notifications: JSON.parse(localStorage.getItem('notifications') || '[]')
  }),
  actions: {
    toggleSidebar() {
      this.sidebarCollapsed = !this.sidebarCollapsed
      localStorage.setItem('sidebarCollapsed', JSON.stringify(this.sidebarCollapsed))
    },
    setTheme(theme) {
      this.theme = theme
      localStorage.setItem('theme', theme)
      document.documentElement.setAttribute('data-theme', theme)
    },
    setUserInfo(userInfo) {
      this.userInfo = userInfo
      localStorage.setItem('userInfo', JSON.stringify(userInfo))
    },
    addNotification(notification) {
      this.notifications.unshift(notification)
      if (this.notifications.length > 10) {
        this.notifications.pop()
      }
      localStorage.setItem('notifications', JSON.stringify(this.notifications))
    },
    clearNotifications() {
      this.notifications = []
      localStorage.setItem('notifications', '[]')
    }
  }
})
