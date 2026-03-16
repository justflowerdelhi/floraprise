"use client";

import React, { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";

export default function EditProduct() {

  const router = useRouter();
  const params = useParams();
  const id = params?.id as string;

  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("basic");

  const [categories, setCategories] = useState<any[]>([]);
  const [subCategories, setSubCategories] = useState<any[]>([]);
  const [images, setImages] = useState<any[]>([]);
  const [variants, setVariants] = useState<any[]>([]);

  const [product, setProduct] = useState({
    name: "",
    slug: "",
    description: "",
    price: "",
    stock: "",
    categoryId: "",
    subCategoryId: "",
    status: "draft"
  });

  /* ---------------- FETCH PRODUCT ---------------- */

  const fetchProduct = async () => {

    try {

      const res = await fetch(`/api/admin/products/${id}`);

      if (!res.ok) {
        console.error("Product fetch failed");
        return;
      }

      const data = await res.json();

      const categoryId = data.category?.id || "";
      const subCategoryId = data.subCategory?.id || "";

      setProduct({
        name: data.name || "",
        slug: data.slug || "",
        description: data.description || "",
        price: data.price?.toString() || "",
        stock: data.stock?.toString() || "",
        categoryId,
        subCategoryId,
        status: data.status || "draft"
      });

      setImages(data.images || []);
      setVariants(data.variants || []);

    } catch (error) {

      console.error("Fetch product error:", error);

    }

  };

  /* ---------------- FETCH CATEGORIES ---------------- */

  const fetchCategories = async () => {

    try {

      const res = await fetch("/api/admin/categories");

      if (!res.ok) {
        console.error("Categories fetch failed");
        return;
      }

      const data = await res.json();

      setCategories(data || []);

    } catch (error) {

      console.error("Category fetch error:", error);

    }

  };

  /* ---------------- CATEGORY CHANGE ---------------- */

  const handleCategoryChange = (categoryId: string) => {

    const category = categories.find(
      (c: any) => String(c.id) === String(categoryId)
    );

    setSubCategories(category?.subCategories || []);

    setProduct((prev) => ({
      ...prev,
      categoryId,
      subCategoryId: ""
    }));

  };

  /* ---------------- UPDATE PRODUCT ---------------- */

  const handleUpdate = async () => {

    try {

      const res = await fetch(`/api/admin/products/${id}`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          ...product,
          price: Number(product.price),
          stock: Number(product.stock)
        })
      });

      if (!res.ok) {

        const err = await res.json();
        console.log("UPDATE ERROR:", err);

        alert("Update failed");
        return;

      }

      router.push("/admin/catalogue");

    } catch (error) {

      console.error("Update error:", error);
      alert("Update failed");

    }

  };

  /* ---------------- LOAD DATA ---------------- */

  useEffect(() => {

    const load = async () => {

      if (!id) return;

      await fetchCategories();
      await fetchProduct();

      setLoading(false);

    };

    load();

  }, [id]);

  /* ---------------- POPULATE SUBCATEGORIES ---------------- */

  useEffect(() => {

    if (!product.categoryId) return;

    const category = categories.find(
      (c: any) => String(c.id) === String(product.categoryId)
    );

    if (category) {
      setSubCategories(category.subCategories || []);
    }

  }, [categories, product.categoryId]);

  if (loading) {
    return (
      <div className="p-10 text-center text-gray-500">
        Loading product...
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto space-y-6">

      <h1 className="text-2xl font-bold">Edit Product</h1>

      {/* TABS */}

      <div className="flex gap-6 border-b">

        {[
          "basic",
          "pricing",
          "inventory",
          "category",
          "images",
          "variants",
          "status"
        ].map((tab) => (

          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`pb-2 ${
              activeTab === tab
                ? "border-b-2 border-pink-600 text-pink-600"
                : "text-gray-500"
            }`}
          >
            {tab.toUpperCase()}
          </button>

        ))}

      </div>

      <div className="bg-white p-6 rounded-xl shadow border">

        {/* BASIC */}

        {activeTab === "basic" && (

          <div className="space-y-4">

            <input
              className="w-full border p-3 rounded"
              placeholder="Product Name"
              value={product.name}
              onChange={(e) =>
                setProduct({ ...product, name: e.target.value })
              }
            />

            <input
              className="w-full border p-3 rounded"
              placeholder="Slug"
              value={product.slug}
              onChange={(e) =>
                setProduct({ ...product, slug: e.target.value })
              }
            />

            <textarea
              className="w-full border p-3 rounded h-32"
              placeholder="Description"
              value={product.description}
              onChange={(e) =>
                setProduct({ ...product, description: e.target.value })
              }
            />

          </div>

        )}

        {/* PRICING */}

        {activeTab === "pricing" && (

          <input
            type="number"
            className="w-full border p-3 rounded"
            placeholder="Price"
            value={product.price}
            onChange={(e) =>
              setProduct({ ...product, price: e.target.value })
            }
          />

        )}

        {/* INVENTORY */}

        {activeTab === "inventory" && (

          <input
            type="number"
            className="w-full border p-3 rounded"
            placeholder="Stock"
            value={product.stock}
            onChange={(e) =>
              setProduct({ ...product, stock: e.target.value })
            }
          />

        )}

        {/* CATEGORY */}

        {activeTab === "category" && (

          <div className="space-y-4">

            <select
              className="w-full border p-2 rounded"
              value={product.categoryId}
              onChange={(e) => handleCategoryChange(e.target.value)}
            >

              <option value="">Select Category</option>

              {categories.map((cat: any) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}

            </select>

            <select
              className="w-full border p-2 rounded"
              value={product.subCategoryId}
              onChange={(e) =>
                setProduct({ ...product, subCategoryId: e.target.value })
              }
            >

              <option value="">Select Subcategory</option>

              {subCategories.map((sub: any) => (
                <option key={sub.id} value={sub.id}>
                  {sub.name}
                </option>
              ))}

            </select>

          </div>

        )}

        {/* IMAGES */}

        {activeTab === "images" && (

          <div className="grid grid-cols-5 gap-4">

            {images.length === 0 && <p>No images</p>}

            {images.map((img: any) => (

              <img
                key={img.id}
                src={img.url}
                className="h-24 object-cover border rounded"
              />

            ))}

          </div>

        )}

        {/* VARIANTS */}

        {activeTab === "variants" && (

          <div className="space-y-3">

            {variants.length === 0 && <p>No variants</p>}

            {variants.map((variant: any) => (

              <div key={variant.id} className="border p-3 rounded">

                <strong>{variant.name}</strong>

              </div>

            ))}

          </div>

        )}

        {/* STATUS */}

        {activeTab === "status" && (

          <select
            className="w-full border p-3 rounded"
            value={product.status}
            onChange={(e) =>
              setProduct({ ...product, status: e.target.value })
            }
          >

            <option value="draft">Draft</option>
            <option value="published">Published</option>

          </select>

        )}

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