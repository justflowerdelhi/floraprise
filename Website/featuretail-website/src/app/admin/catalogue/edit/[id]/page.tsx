"use client";

import { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";

export default function EditProduct() {
  const router = useRouter();
  const params = useParams();
  const { id } = params;

  const [loading, setLoading] = useState(true);

  const [product, setProduct] = useState({
    name: "",
    slug: "",
    description: "",
    price: "",
    stock: "",
    category: "",
    tags: "",
    status: "draft",
  });

  useEffect(() => {
    fetchProduct();
  }, []);

  const fetchProduct = async () => {
    const res = await fetch(`/api/admin/products/${id}`);
    const data = await res.json();

    setProduct({
      ...data,
      price: data.price.toString(),
      stock: data.stock.toString(),
      tags: data.tags.join(", "),
    });

    setLoading(false);
  };

  const handleUpdate = async () => {
    await fetch(`/api/admin/products/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        ...product,
        price: parseFloat(product.price),
        stock: parseInt(product.stock),
        tags: product.tags.split(",").map((t) => t.trim()),
      }),
    });

    router.push("/admin/catalogue");
  };

  if (loading) return <p>Loading...</p>;

  return (
    <div className="max-w-5xl mx-auto space-y-6">

      <h1 className="text-2xl font-bold">Edit Product</h1>

      <input
        type="text"
        className="w-full border p-3 rounded"
        value={product.name}
        onChange={(e) =>
          setProduct({ ...product, name: e.target.value })
        }
      />

      <input
        type="text"
        className="w-full border p-3 rounded"
        value={product.slug}
        onChange={(e) =>
          setProduct({ ...product, slug: e.target.value })
        }
      />

      <textarea
        className="w-full border p-3 rounded h-32"
        value={product.description}
        onChange={(e) =>
          setProduct({ ...product, description: e.target.value })
        }
      />

      <div className="grid md:grid-cols-2 gap-6">

        <div className="bg-white p-6 rounded-xl shadow border space-y-4">
          <h2 className="font-semibold">General</h2>

          <input
            type="number"
            className="w-full border p-2 rounded"
            value={product.price}
            onChange={(e) =>
              setProduct({ ...product, price: e.target.value })
            }
          />
        </div>

        <div className="bg-white p-6 rounded-xl shadow border space-y-4">
          <h2 className="font-semibold">Inventory</h2>

          <input
            type="number"
            className="w-full border p-2 rounded"
            value={product.stock}
            onChange={(e) =>
              setProduct({ ...product, stock: e.target.value })
            }
          />
        </div>

      </div>

      <div className="bg-white p-6 rounded-xl shadow border space-y-4">
        <h2 className="font-semibold">Organization</h2>

        <input
          type="text"
          className="w-full border p-2 rounded"
          value={product.category}
          onChange={(e) =>
            setProduct({ ...product, category: e.target.value })
          }
        />

        <input
          type="text"
          className="w-full border p-2 rounded"
          value={product.tags}
          onChange={(e) =>
            setProduct({ ...product, tags: e.target.value })
          }
        />

        <select
          className="w-full border p-2 rounded"
          value={product.status}
          onChange={(e) =>
            setProduct({ ...product, status: e.target.value })
          }
        >
          <option value="draft">Draft</option>
          <option value="published">Published</option>
        </select>
      </div>

      <button
        onClick={handleUpdate}
        className="bg-green-600 text-white px-6 py-3 rounded font-semibold"
      >
        Update Product
      </button>

    </div>
  );
}