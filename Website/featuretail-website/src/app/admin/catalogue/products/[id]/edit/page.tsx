"use client";

import { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";

export default function ProductEditPage() {
  const router = useRouter();
  const params = useParams();
  const id = params.id as string;
  const [product, setProduct] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState<any>({});

  useEffect(() => {
    if (!id) return;
    fetch(`/api/admin/products/${id}`)
      .then((res) => res.json())
      .then((data) => {
        setProduct(data);
        setForm({
          name: data.name,
          price: data.price,
          stock: data.stock,
          status: data.status,
          description: data.description,
        });
        setLoading(false);
      });
  }, [id]);

  const handleChange = (e: any) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: any) => {
    e.preventDefault();
    await fetch(`/api/admin/products/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });
    router.push(`/admin/catalogue/products/${id}`);
  };

  if (loading) return <div className="p-8">Loading...</div>;
  if (!product) return <div className="p-8 text-red-600">Product not found.</div>;

  return (
    <div className="max-w-3xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-4">Edit Product</h1>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block mb-1">Name</label>
          <input name="name" value={form.name || ''} onChange={handleChange} className="border rounded px-2 py-1 w-full" />
        </div>
        <div>
          <label className="block mb-1">Price</label>
          <input name="price" type="number" value={form.price || ''} onChange={handleChange} className="border rounded px-2 py-1 w-full" />
        </div>
        <div>
          <label className="block mb-1">Stock</label>
          <input name="stock" type="number" value={form.stock || ''} onChange={handleChange} className="border rounded px-2 py-1 w-full" />
        </div>
        <div>
          <label className="block mb-1">Status</label>
          <select name="status" value={form.status || ''} onChange={handleChange} className="border rounded px-2 py-1 w-full">
            <option value="draft">Draft</option>
            <option value="published">Published</option>
          </select>
        </div>
        <div>
          <label className="block mb-1">Description</label>
          <textarea name="description" value={form.description || ''} onChange={handleChange} className="border rounded px-2 py-1 w-full" />
        </div>
        <button type="submit" className="bg-pink-600 text-white px-4 py-2 rounded">Save</button>
      </form>
    </div>
  );
}
