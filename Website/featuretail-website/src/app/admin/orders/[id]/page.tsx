"use client"

import { useEffect, useState } from "react"
import { useParams } from "next/navigation"

export default function OrderDetailPage(){

  const { id } = useParams()

  const [order,setOrder] = useState<any>(null)

  useEffect(()=>{
    fetch(`/api/admin/orders/${id}`)
      .then(res => res.json())
      .then(data => setOrder(data))
  },[id])

  if(!order){
    return <div className="p-10">Loading order...</div>
  }

  return(
    <div className="max-w-6xl mx-auto space-y-6">

      <h1 className="text-2xl font-bold">
        Order {order.orderNumber}
      </h1>
      <a
        href={`/api/admin/orders/${order.id}/invoice`}
        target="_blank"
        className="bg-blue-600 text-white px-4 py-2 rounded"
      >
        Download Invoice
      </a>

      {/* Order Summary */}
      <div className="bg-white p-6 border rounded grid grid-cols-3 gap-6">

        <div>
          <p className="text-sm text-gray-500">Customer</p>
          <p className="font-semibold">{order.shippingName}</p>
        </div>

        <div>
          <p className="text-sm text-gray-500">Phone</p>
          <p>{order.shippingPhone}</p>
        </div>

        <div>
          <p className="text-sm text-gray-500">Email</p>
          <p>{order.shippingEmail}</p>
        </div>

        <div>
          <p className="text-sm text-gray-500">Order Status</p>
          <p className="font-semibold">{order.orderStatus}</p>
        </div>

        <div>
          <p className="text-sm text-gray-500">Payment</p>
          <p>{order.paymentMethod}</p>
        </div>

        <div>
          <p className="text-sm text-gray-500">Total</p>
          <p className="font-bold text-lg">₹{order.total}</p>
        </div>

      </div>

      {/* Address */}
      <div className="bg-white p-6 border rounded">
        <h2 className="font-semibold mb-3">Shipping Address</h2>

        <p>{order.shippingAddress}</p>
        <p>{order.shippingCity}, {order.shippingState}</p>
        <p>{order.shippingPincode}</p>
      </div>

      {/* Items */}
      <div className="bg-white p-6 border rounded">

        <h2 className="font-semibold mb-4">Items</h2>

        <table className="w-full border">

          <thead className="bg-gray-100">
            <tr>
              <th className="p-2 border text-left">Product</th>
              <th className="p-2 border">Price</th>
              <th className="p-2 border">Qty</th>
              <th className="p-2 border">Total</th>
            </tr>
          </thead>

          <tbody>

            {order.items?.map((item:any)=>(
              <tr key={item.id}>
                <td className="p-2 border">{item.name}</td>
                <td className="p-2 border text-center">₹{item.price}</td>
                <td className="p-2 border text-center">{item.quantity}</td>
                <td className="p-2 border text-center">
                  ₹{item.price * item.quantity}
                </td>
              </tr>
            ))}

          </tbody>

        </table>

      </div>

      {/* Order Totals */}
      <div className="bg-white p-6 border rounded">

        <h2 className="font-semibold mb-4">Order Totals</h2>

        <div className="space-y-2">

          <p>Subtotal: ₹{order.subtotal}</p>
          <p>Shipping: ₹{order.shipping}</p>
          <p>Discount: ₹{order.discount}</p>

          <p className="font-bold text-lg">
            Total: ₹{order.total}
          </p>

        </div>

      </div>

      {/* Admin Actions */}
      <div className="bg-white p-6 border rounded flex gap-4">

        <button className="bg-blue-600 text-white px-4 py-2 rounded">
          Update Status
        </button>

        <button className="bg-green-600 text-white px-4 py-2 rounded">
          Create Shipment
        </button>

        <button className="bg-gray-800 text-white px-4 py-2 rounded">
          Print Invoice
        </button>

      </div>

    </div>
  )
}