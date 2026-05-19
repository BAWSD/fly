let loadingPromise = null

export const loadBaiduMap = (ak) => {
  if (loadingPromise) {
    return loadingPromise
  }

  loadingPromise = new Promise((resolve, reject) => {
    if (window.BMap && window.BMapGL) {
      resolve({ BMap: window.BMap, BMapGL: window.BMapGL })
      return
    }

    const script = document.createElement('script')
    script.src = `https://api.map.baidu.com/api?type=webgl&v=1.0&ak=${ak}&callback=__baiduMapCallback`
    script.onerror = reject

    window.__baiduMapCallback = () => {
      resolve({ BMap: window.BMap, BMapGL: window.BMapGL })
    }

    document.head.appendChild(script)
  })

  return loadingPromise
}

