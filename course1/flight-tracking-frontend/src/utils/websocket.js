import SockJS from 'sockjs-client'
import Client from 'webstomp-client'

class WebSocketService {
  constructor() {
    this.stompClient = null
    this.subscriptions = new Map()
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = 5
  }

  connect() {
    return new Promise((resolve, reject) => {
      try {
        const socket = new SockJS(`${import.meta.env.VITE_WS_BASE_URL}/ws-flight`)
        this.stompClient = Client.over(socket)

        this.stompClient.connect(
          {},
          () => {
            console.log('WebSocket connected successfully')
            this.reconnectAttempts = 0
            resolve(this.stompClient)
          },
          (error) => {
            console.error('WebSocket connection error:', error)
            this.handleDisconnect()
            reject(error)
          }
        )

        socket.onclose = () => {
          this.handleDisconnect()
        }
      } catch (error) {
        console.error('WebSocket connection failed:', error)
        reject(error)
      }
    })
  }

  handleDisconnect() {
    console.log('WebSocket disconnected, attempting to reconnect...')
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++
      setTimeout(() => {
        this.connect().catch(() => {
          console.error('Reconnection attempt failed:', this.reconnectAttempts)
        })
      }, 3000 * this.reconnectAttempts)
    }
  }

  subscribe(destination, callback) {
    if (!this.stompClient || !this.stompClient.connected) {
      console.error('WebSocket not connected')
      return null
    }

    const subscription = this.stompClient.subscribe(destination, (message) => {
      try {
        const data = JSON.parse(message.body)
        callback(data)
      } catch (error) {
        console.error('Failed to parse WebSocket message:', error)
      }
    })

    this.subscriptions.set(destination, subscription)
    return subscription
  }

  unsubscribe(destination) {
    const subscription = this.subscriptions.get(destination)
    if (subscription) {
      subscription.unsubscribe()
      this.subscriptions.delete(destination)
    }
  }

  send(destination, body) {
    if (!this.stompClient || !this.stompClient.connected) {
      console.error('WebSocket not connected')
      return false
    }

    this.stompClient.send(destination, {}, JSON.stringify(body))
    return true
  }

  disconnect() {
    if (this.stompClient) {
      this.subscriptions.forEach((subscription) => {
        subscription.unsubscribe()
      })
      this.subscriptions.clear()

      this.stompClient.disconnect(() => {
        console.log('WebSocket disconnected')
      })
      this.stompClient = null
    }
  }

  isConnected() {
    return this.stompClient && this.stompClient.connected
  }
}

const webSocketService = new WebSocketService()

export default webSocketService

export const useWebSocket = () => {
  const connectWebSocket = async () => {
    if (!webSocketService.isConnected()) {
      await webSocketService.connect()
    }
    return webSocketService
  }

  const subscribeFlight = (flightNumber, callback) => {
    return webSocketService.subscribe(`/topic/flight.position.${flightNumber}`, callback)
  }

  const subscribeAllFlights = (callback) => {
    return webSocketService.subscribe('/topic/flight.positions.all', callback)
  }

  const subscribeFlightUpdates = (callback) => {
    return webSocketService.subscribe('/topic/flight.updates', callback)
  }

  return {
    connectWebSocket,
    subscribeFlight,
    subscribeAllFlights,
    subscribeFlightUpdates,
    webSocketService
  }
}
