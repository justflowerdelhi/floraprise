"use client";

import VariantMatrixGenerator from "../Components/VariantMatrixGenerator";
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

/* ---------------- IMAGE ITEM ---------------- */

function SortableImage({ id, img, removeImage }: any) {
  const { attributes, listeners, setNodeRef, transform, transition } =
    useSortable({ id });

  return (
    <div
      ref={setNodeRef}
      style={{ transform: CSS.Transform.toString(transform), transition }}
      {...attributes}
      {...listeners}
      className="relative cursor-move"
    >
      <img src={img} className="w-full h-24 object-cover border rounded" />

      <button
        type="button"
        onClick={() => removeImage(id)}
        className="absolute top-1 right-1 bg-red-500 text-white px-2 text-xs rounded"
      >
        X
      </button>

      {id === img && (
        <div className="absolute top-1 left-1 bg-green-600 text-white text-xs px-1 rounded">
          COVER
        </div>
      )}
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

  const [variantOptions, setVariantOptions] = useState([{ name: "", values: "" }]);
  const [variantMatrix, setVariantMatrix] = useState<any[]>([]);
  const [baseSku, setBaseSku] = useState("");
  const [variants, setVariants] = useState<any[]>([]);

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

  /* ---------------- LOAD ---------------- */

  useEffect(() => {
    fetch("/api/admin/categories?includeSub=true")
      .then(res => res.json())
      .then(data => setCategories(data || []));
  }, []);

  const generateSlug = (text: string) =>
    text.toLowerCase().replace(/[^a-z0-9\s-]/g, "").trim().replace(/\s+/g, "-");

  const handleCategoryChange = (id: string) => {
    setSelectedCategoryId(id);
    const cat = categories.find(c => c.id === id);
    setSubCategories(cat?.subCategories || []);
    setProduct({ ...product, categoryId: id, subCategoryId: "" });
  };

  /* ---------------- IMAGE ---------------- */

  const handleImageUpload = (e: any) => {
    const files = Array.from(e.target.files) as File[];
    setImages((prev) => [...prev, ...files]);

    const urls = files.map((f: any) => URL.createObjectURL(f));
    setPreviews(prev => [...prev, ...urls]);
  };

  const removeImage = (id: string) => {
    const i = previews.indexOf(id);
    setImages(images.filter((_, idx) => idx !== i));
    setPreviews(previews.filter((_, idx) => idx !== i));
  };

  /* ---------------- SAVE ---------------- */

  const handleSubmit = async () => {

    // Client-side validation for required fields
    if (!product.name || !product.slug || !product.price || !product.stock || !product.categoryId) {
      alert("Please fill all required fields: Name, Slug, Price, Stock, and Category.");
      return;
    }

    const formData = new FormData();

    formData.append("name", product.name);
    formData.append("slug", product.slug);
    formData.append("description", product.description || "");
    formData.append("bulletPoints", product.bulletPoints || "");

    formData.append("price", product.price);
    formData.append("stock", product.stock);

    formData.append("categoryId", product.categoryId);
    if (product.subCategoryId) {
      formData.append("subCategoryId", product.subCategoryId);
    }
    formData.append("status", product.status || "draft");

    // VARIANTS SAFE
    const rawVariants =
      typeof window !== "undefined" &&
      (window as any).generatedVariants
        ? (window as any).generatedVariants
        : [];

    const formattedVariants = rawVariants.map((v: any, i: number) => ({
      name: v.sku || "Variant",
      price: v.price || 0,
      stock: v.stock || 0,
      imageIndex: i
    }));

    formData.append("variants", JSON.stringify(formattedVariants));


    // IMAGES (CORRECT)
    images.forEach((img) => {
      formData.append("images", img);
    });

    // VARIANT FILES
    variants.forEach((v: any) => {
      if (v.file) {
        formData.append("variantImages", v.file);
      }
    });

    const res = await fetch("/api/admin/products", {
      method: "POST",
      body: formData
    });

    const data = await res.json();

    if (!res.ok) {
      alert(data.error || "Save failed");
      return;
    }

    router.push("/admin/catalogue/products");
  };

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

    if (!ai) return;

    const newName =
      ai.product_name ||
      ai.title ||
      product.name;

    const newDescription =
      ai.long_description ||
      ai.product_description ||
      ai.description ||
      ai.short_description ||
      "";

    const bulletsArray =
      ai.key_features ||
      ai.features ||
      [];

    const newBullets = Array.isArray(bulletsArray)
      ? bulletsArray.join("\n")
      : "";

    const newSlug =
      ai.url_slug ||
      generateSlug(newName);

    const keywordsArray =
      ai.seo_keywords ||
      [];

    const keywords = Array.isArray(keywordsArray)
      ? keywordsArray.join(", ")
      : "";

    setProduct((prev) => ({
      ...prev,
      name: newName,
      slug: newSlug,
      description: newDescription,
      bulletPoints: newBullets,
      metaTitle: ai.meta_title || newName,
      metaDescription: ai.meta_description || newDescription.slice(0, 150),
      seoKeywords: keywords,
      tags: keywords
    }));
  };

  /* ---------------- UI ---------------- */

  return (
    <div className="max-w-6xl mx-auto space-y-6">

      <div className="flex justify-between">
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
        {["basic","pricing","inventory","variants","dimensions","category","images","seo","tags","status"]
          .map(tab => (
            <button
              key={tab}
              onClick={()=>setActiveTab(tab)}
              className={activeTab===tab ? "border-b-2 border-pink-600 text-pink-600":"text-gray-500"}
            >
              {tab.toUpperCase()}
            </button>
        ))}
      </div>

      <div className="bg-white p-6 border rounded">

        {/* BASIC */}
        {activeTab==="basic" && (
          <>
            <input value={product.name} placeholder="Name"
              onChange={e=>setProduct({...product,name:e.target.value,slug:generateSlug(e.target.value)})}
              className="w-full border p-2 mb-2"/>

            <input value={product.slug} placeholder="Slug"
              onChange={e=>setProduct({...product,slug:e.target.value})}
              className="w-full border p-2 mb-2"/>

            <textarea value={product.description}
              onChange={e=>setProduct({...product,description:e.target.value})}
              className="w-full border p-2 mb-2"/>

            <textarea value={product.bulletPoints}
              onChange={e=>setProduct({...product,bulletPoints:e.target.value})}
              className="w-full border p-2"/>
          </>
        )}

        {/* SEO */}
        {activeTab === "seo" && (
          <>
            <input
              value={product.metaTitle}
              placeholder="Meta Title"
              onChange={(e) =>
                setProduct({ ...product, metaTitle: e.target.value })
              }
              className="w-full border p-2 mb-2"
            />

            <textarea
              value={product.metaDescription}
              placeholder="Meta Description"
              onChange={(e) =>
                setProduct({ ...product, metaDescription: e.target.value })
              }
              className="w-full border p-2 mb-2"
            />

            <input
              value={product.seoKeywords}
              placeholder="SEO Keywords (comma separated)"
              onChange={(e) =>
                setProduct({ ...product, seoKeywords: e.target.value })
              }
              className="w-full border p-2"
            />
          </>
        )}

        {/* TAGS */}
        {activeTab === "tags" && (
          <input
            value={product.tags}
            placeholder="Tags (comma separated)"
            onChange={(e) =>
              setProduct({ ...product, tags: e.target.value })
            }
            className="w-full border p-2"
          />
        )}

        {/* STATUS */}
        {activeTab === "status" && (
          <select
            value={product.status}
            onChange={(e) =>
              setProduct({ ...product, status: e.target.value })
            }
            className="w-full border p-2"
          >
            <option value="draft">Draft</option>
            <option value="published">Published</option>
          </select>
        )}

        {/* PRICING */}
        {activeTab==="pricing" && (
          <input type="number"
            value={product.price}
            onChange={e=>setProduct({...product,price:e.target.value})}
            className="w-full border p-2"/>
        )}

        {/* INVENTORY */}
        {activeTab==="inventory" && (
          <input type="number"
            value={product.stock}
            onChange={e=>setProduct({...product,stock:e.target.value})}
            className="w-full border p-2"/>
        )}

        {/* VARIANTS */}
        {activeTab==="variants" && (
          <VariantMatrixGenerator
            options={variantOptions}
            setOptions={setVariantOptions}
            matrix={variantMatrix}
            setMatrix={setVariantMatrix}
            baseSku={baseSku}
            setBaseSku={setBaseSku}
            variants={variants}
            setVariants={setVariants}
          />
        )}

        {/* CATEGORY */}
        {activeTab==="category" && (
          <div className="space-y-3">
            <select
              value={product.categoryId}
              onChange={(e)=>handleCategoryChange(e.target.value)}
              className="w-full border p-2"
            >
              <option value="">Select Category</option>
              {categories.map((c)=>(
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>

            <select
              value={product.subCategoryId}
              onChange={(e)=>setProduct({...product,subCategoryId:e.target.value})}
              className="w-full border p-2"
            >
              <option value="">No Subcategory</option>
              {subCategories.map((s)=>(
                <option key={s.id} value={s.id}>{s.name}</option>
              ))}
            </select>
          </div>
        )}

        {/* IMAGES */}
        {activeTab==="images" && (
          <>
            <input type="file" multiple onChange={handleImageUpload} />

            {previews.length === 0 && (
              <div className="border p-4 mt-2">No images selected</div>
            )}

            {previews.length > 0 && (
              <DndContext
                collisionDetection={closestCenter}
                onDragEnd={(event) => {
                  const { active, over } = event;
                  if (!over || active.id === over.id) return;

                  const oldIndex = previews.indexOf(String(active.id));
                  const newIndex = previews.indexOf(String(over.id));

                  setPreviews(arrayMove(previews, oldIndex, newIndex));
                  setImages(arrayMove(images, oldIndex, newIndex));
                }}
              >
                <SortableContext items={previews} strategy={horizontalListSortingStrategy}>
                  <div className="grid grid-cols-4 gap-2 mt-2">
                    {previews.map((img) => (
                      <SortableImage key={img} id={img} img={img} removeImage={removeImage}/>
                    ))}
                  </div>
                </SortableContext>
              </DndContext>
            )}
          </>
        )}

      </div>

      <button onClick={handleSubmit} className="bg-pink-600 text-white px-6 py-3 rounded">
        Save Product
      </button>

    </div>
  );
}