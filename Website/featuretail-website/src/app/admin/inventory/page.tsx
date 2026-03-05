"use client"

import { useEffect, useState } from "react"

export default function InventoryPage(){

  const [products,setProducts] = useState([])

  useEffect(()=>{
    fetch("/api/admin/products")
      .then(res=>res.json())
      .then(data=>setProducts(data))
  },[])

  return(

    <div className="max-w-6xl mx-auto">

      <h1 className="text-2xl font-bold mb-6">
        Inventory
      </h1>

      <div className="bg-white border rounded">

        <table className="w-full">

          <thead className="bg-gray-100">
            <tr>
              <th className="p-3 text-left">Product</th>
              <th className="p-3 text-left">Category</th>
              <th className="p-3 text-left">Price</th>
              <th className="p-3 text-left">Stock</th>
              <th className="p-3 text-left">Status</th>
            </tr>
          </thead>

          <tbody>

            {products.map((p:any)=>(
              <tr key={p.id} className="border-t">

                <td className="p-3">{p.name}</td>

                <td className="p-3">
                  {p.category?.name}
                </td>

                <td className="p-3">
                  ₹{p.price}
                </td>

                <td className="p-3">
                  {p.stock}
                </td>

                <td className="p-3">

                  {p.stock < 5 ? (
                    <span className="text-red-500">
                      Low Stock
                    </span>
                  ) : (
                    <span className="text-green-600">
                      In Stock
                    </span>
                  )}

                </td>

              </tr>
            ))}

          </tbody>

        </table>

      </div>

    </div>

  )
}