"use client";

import VariantMatrixGenerator from "../components/VariantMatrixGenerator";
import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import { DndContext, closestCenter } from "@dnd-kit/core";
import {
  SortableContext,
  horizontalListSortingStrategy,
  useSortable,
  arrayMove
} from "@dnd-kit/sortable";

import { CSS } from "@dnd-kit/utilities";

/* ---------------- IMAGE COMPONENT ---------------- */

function SortableImage({
  id,
  img,
  removeImage
}: {
  id: string;
  img: string;
  removeImage: (id: string) => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition } =
    useSortable({ id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition
  };

  return (
    <div ref={setNodeRef} style={style} {...attributes} {...listeners} className="relative">
      <img src={img} className="w-full h-24 object-cover border rounded" />

      <button
        type="button"
        onClick={() => removeImage(id)}
        className="absolute top-1 right-1 bg-red-500 text-white px-2 text-xs rounded"
      >
        X
      </button>
    </div>
  );
}

/* ---------------- PAGE ---------------- */

export default function CreateProductPage() {

  const router = useRouter();

  const [activeTab, setActiveTab] = useState("basic");

  const [categories, setCategories] = useState<any[]>([]);
  const [subCategories, setSubCategories] = useState<any[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState("");

  const [images, setImages] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);

  const [product, setProduct] = useState({
    name: "",
    slug: "",
    description: "",
    bulletPoints: "",
    price: "",
    stock: "",
    weight: "",
    length: "",
    width: "",
    height: "",
    metaTitle: "",
    metaDescription: "",
    seoKeywords: "",
    tags: "",
    categoryId: "",
    subCategoryId: "",
    status: "draft"
  });

  /* ---------------- LOAD CATEGORIES ---------------- */

  useEffect(() => {
    fetchCategories();
  }, []);

  const fetchCategories = async () => {
    const res = await fetch("/api/admin/categories?includeSub=true");
    const data = await res.json();
    setCategories(data || []);
  };

  /* ---------------- SLUG ---------------- */

  const generateSlug = (text: string) =>
    text
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, "")
      .trim()
      .replace(/\s+/g, "-");

  /* ---------------- CATEGORY ---------------- */

  const handleCategoryChange = (categoryId: string) => {

    setSelectedCategoryId(categoryId);

    const category = categories.find((c) => c.id === categoryId);

    setSubCategories(category?.subCategories || []);

    setProduct((prev) => ({
      ...prev,
      categoryId,
      subCategoryId: ""
    }));
  };

  /* ---------------- IMAGE UPLOAD ---------------- */

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {

    const files = Array.from(e.target.files || []);

    setImages((prev) => [...prev, ...files]);

    const newPreviews = files.map((file) => URL.createObjectURL(file));

    setPreviews((prev) => [...prev, ...newPreviews]);
  };

  const removeImage = (id: string) => {

    const index = previews.indexOf(id);

    setImages(images.filter((_, i) => i !== index));
    setPreviews(previews.filter((_, i) => i !== index));
  };

  /* ---------------- SAVE PRODUCT ---------------- */

  const handleSubmit = async () => {

    const formData = new FormData();

    Object.entries(product).forEach(([key, value]) => {
      formData.append(key, String(value));
    });

    formData.append("variants", JSON.stringify((window as any).generatedVariants || []));

    images.forEach((img) => formData.append("images", img));

    const res = await fetch("/api/admin/products", {
      method: "POST",
      body: formData
    });

    if (!res.ok) {
      alert("Product creation failed");
      return;
    }

    router.push("/admin/catalogue/products");
  };

  /* ---------------- AI GENERATOR ---------------- */

  const handleAIGenerate = async () => {

    const res = await fetch("/api/ai/generate", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        productName: product.name
      })
    });

    const ai = await res.json();

    console.log("AI DATA:", ai);

    const name = ai.product_name || product.name;

    const description =
      ai.long_description ||
      ai.product_description ||
      "";

    const bullets = (ai.key_features || [])
      .map((b: string) => `• ${b}`)
      .join("\n");

    const slug =
      ai.url_slug ||
      generateSlug(name);

    const keywords =
      (ai.seo_keywords || []).join(", ");

    setProduct((prev) => ({
      ...prev,
      name,
      slug,
      description,
      bulletPoints: bullets,
      metaTitle: ai.meta_title || `${name} | Premium Craft Supplies`,
      metaDescription:
        ai.meta_description ||
        description.substring(0, 155),
      seoKeywords: keywords,
      tags: keywords
    }));
  };

  /* ---------------- UI ---------------- */

  return (

    <div className="max-w-6xl mx-auto space-y-6">

      <div className="flex justify-between items-center">

        <h1 className="text-2xl font-bold">Create Product</h1>

        <button
          onClick={handleAIGenerate}
          className="bg-blue-600 text-white px-4 py-2 rounded"
        >
          Generate with AI
        </button>

      </div>

      {/* TABS */}

      <div className="flex gap-6 border-b">

        {[
          "basic",
          "pricing",
          "inventory",
          "variants",
          "dimensions",
          "category",
          "images",
          "seo",
          "tags",
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
              onChange={(e) => {

                const value = e.target.value;

                setProduct({
                  ...product,
                  name: value,
                  slug: generateSlug(value)
                });

              }}
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
              className="w-full border p-3 rounded h-24"
              placeholder="Description"
              value={product.description}
              onChange={(e) =>
                setProduct({ ...product, description: e.target.value })
              }
            />

            <textarea
              className="w-full border p-3 rounded h-24"
              placeholder="Bullet Points"
              value={product.bulletPoints}
              onChange={(e) =>
                setProduct({ ...product, bulletPoints: e.target.value })
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

        {activeTab === "variants" && <VariantMatrixGenerator />}

        {/* SEO */}

        {activeTab === "seo" && (

          <div className="space-y-4">

            <input
              className="w-full border p-3 rounded"
              placeholder="Meta Title"
              value={product.metaTitle}
              onChange={(e) =>
                setProduct({ ...product, metaTitle: e.target.value })
              }
            />

            <textarea
              className="w-full border p-3 rounded h-24"
              placeholder="Meta Description"
              value={product.metaDescription}
              onChange={(e) =>
                setProduct({ ...product, metaDescription: e.target.value })
              }
            />

            <input
              className="w-full border p-3 rounded"
              placeholder="SEO Keywords"
              value={product.seoKeywords}
              onChange={(e) =>
                setProduct({ ...product, seoKeywords: e.target.value })
              }
            />

          </div>

        )}

      </div>

      <button
        onClick={handleSubmit}
        className="bg-pink-600 text-white px-6 py-3 rounded font-semibold"
      >
        Save Product
      </button>

    </div>

  );

}