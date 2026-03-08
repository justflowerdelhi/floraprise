import React, { useEffect, useState } from "react"
import { Alert } from "@mui/material"
import { getOfflineSales } from "../utils/offlineSalesQueue"

const OfflineBanner = () => {

  const [pending, setPending] = useState(0)
  const [offline, setOffline] = useState(!navigator.onLine)

  useEffect(() => {

    const updateStatus = () => {

      setOffline(!navigator.onLine)

      const sales = getOfflineSales()

      setPending(sales.length)

    }

    updateStatus()

    window.addEventListener("online", updateStatus)
    window.addEventListener("offline", updateStatus)

    return () => {

      window.removeEventListener("online", updateStatus)
      window.removeEventListener("offline", updateStatus)

    }

  }, [])

  if (!offline && pending === 0) return null

  return (
    <Alert severity="warning">
      Offline Mode — {pending} sales pending sync
    </Alert>
  )
}

export default OfflineBanner
