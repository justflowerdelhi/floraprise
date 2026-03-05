"use client"

import { useEffect, useState } from "react"
import { useParams } from "next/navigation"

export default function OrderDetailPage(){

  const params = useParams()
  const id = params?.id as string

  const [order,setOrder] = useState<any>(null)

  useEffect(()=>{

    if(!id) return

    const loadOrder = async () => {

      const res = await fetch(`/api/admin/orders/${id}`)

      if(!res.ok){
        console.error("API error")
        return
      }

      const data = await res.json()

      console.log("ORDER DATA:",data)

      setOrder(data)

    }

    loadOrder()

  },[id])

  if(!order){
    return <div className="p-6">Loading order...</div>
  }

  return(
    <div className="max-w-5xl mx-auto space-y-6">

      <h1 className="text-2xl font-bold">
        Order {order.orderNumber}
      </h1>

      <div className="bg-white p-6 border rounded">
        <p><b>Customer:</b> {order.shippingName}</p>
        <p><b>Phone:</b> {order.shippingPhone}</p>
        <p><b>Email:</b> {order.shippingEmail}</p>
        <p><b>Address:</b> {order.shippingAddress}</p>
        <p><b>Total:</b> ₹{order.total}</p>
        <p><b>Status:</b> {order.orderStatus}</p>
      </div>

      <div className="bg-white p-6 border rounded">

        <h2 className="font-semibold mb-4">Items</h2>

        {order.items?.length === 0 && (
          <p className="text-gray-500">No items found</p>
        )}

        {order.items?.map((item:any)=>(
          <div key={item.id} className="flex justify-between border-b py-2">
            <div>{item.name}</div>
            <div>Qty: {item.quantity}</div>
            <div>₹{item.price}</div>
          </div>
        ))}

      </div>

    </div>
  )
}