const routes = [
  {
    path: '/',
    redirect: '/dashboard',
    meta: { hidden: true }
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('@/views/Dashboard.vue'),
    meta: {
      title: '仪表板',
      icon: 'Odometer',
      affix: true
    }
  },
  {
    path: '/flights',
    name: 'Flights',
    meta: {
      title: '航班管理',
      icon: 'Management'
    },
    children: [
      {
        path: 'list',
        name: 'FlightList',
        component: () => import('@/views/FlightList.vue'),
        meta: { title: '航班列表' }
      },
      {
        path: 'detail/:flightNumber',
        name: 'FlightDetail',
        component: () => import('@/views/FlightDetail.vue'),
        meta: { title: '航班详情', hidden: true }
      }
    ]
  },
  {
    path: '/tracking',
    name: 'Tracking',
    component: () => import('@/views/AirportMap.vue'),
    meta: {
      title: '实时跟踪',
      icon: 'MapLocation'
    }
  },
  {
    path: '/analysis',
    name: 'Analysis',
    component: () => import('@/views/AnalysisReport.vue'),
    meta: {
      title: '分析报告',
      icon: 'TrendCharts'
    }
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard',
    meta: { hidden: true }
  }
]

export default routes

