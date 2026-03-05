"use client";

import type React from "react";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import {
  DndContext,
  closestCenter
} from "@dnd-kit/core";
import {
  SortableContext,
  horizontalListSortingStrategy,
  useSortable,
  arrayMove
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";

function SortableImage({id, img, removeImage}: {id: string, img: string, removeImage: (id: string) => void}) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition
  } = useSortable({id});

  const style = {
    transform: CSS.Transform.toString(transform),
    transition
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      className="relative cursor-move"
    >
      <img
        src={img}
        className="w-full h-24 object-cover rounded border"
      />
      <button
        onClick={() => removeImage(id)}
        className="absolute top-1 right-1 bg-red-500 text-white px-2 text-xs rounded"
      >
        X
      </button>
    </div>
  );
}
// ...existing code...

// ...existing code...

export default function AdvancedProductPage() {
      // ...existing code...
    const selectTag = (tag: any) => {
      if (!selectedTags.find(t => t.id === tag.id)) {
        setSelectedTags([...selectedTags, tag]);
      }
    };

    const removeTag = (id: string) => {
      setSelectedTags(selectedTags.filter(t => t.id !== id));
    };
  const router = useRouter();

  const [activeTab, setActiveTab] = useState("basic");
  const [categories, setCategories] = useState<any[]>([]);
  const [subCategories, setSubCategories] = useState<any[]>([]);
  const [tags, setTags] = useState<any[]>([]);
  const [images, setImages] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);
  const [selectedTags, setSelectedTags] = useState<any[]>([]);
  const [tagInput, setTagInput] = useState("");
  const addTag = async () => {
    if (!tagInput) return;

    const res = await fetch("/api/admin/tags", {
      method: "POST",
      headers: {"Content-Type":"application/json"},
      body: JSON.stringify({ name: tagInput }),
    });

    const newTag = await res.json();

    setSelectedTags([...selectedTags, newTag]);
    setTagInput("");
    fetchTags();
  };

  const [product, setProduct] = useState({
    name: "",
    slug: "",
    description: "",
    price: "",
    stock: "",
    categoryId: "",
    subCategoryId: "",
    status: "draft",
  });


  const [variantTypes, setVariantTypes] = useState([
    { name: "", values: [""] }
  ]);

  type VariantRow = { name: string; price: string; stock: string };
  const [variantRows, setVariantRows] = useState<VariantRow[]>([]);

  const generateVariants = () => {
    const combinations = variantTypes.reduce<string[][]>((acc, type) => {
      const values = type.values.filter(v => v);
      if (!values.length) return acc;
      if (acc.length === 0) {
        return values.map(v => [v]);
      }
      const result: string[][] = [];
      acc.forEach(a => {
        values.forEach(v => {
          result.push([...a, v]);
        });
      });
      return result;
    }, []);

    setVariantRows(
      combinations.map(c => ({
        name: c.join(" / "),
        price: "",
        stock: ""
      }))
    );
  };
  const [variants, setVariants] = useState([
    {
      name: "",
      options: [
        { value: "", price: "", stock: "" }
      ]
    }
  ]);

  useEffect(() => {
    fetchCategories();
    fetchTags();
  }, []);
  const fetchTags = async () => {
    const res = await fetch("/api/admin/tags");
    const data = await res.json();
    setTags(data);
  };

  const fetchCategories = async () => {
    const res = await fetch("/api/admin/categories");
    const data = await res.json();
    setCategories(data);
  };

  const handleCategoryChange = (categoryId: string) => {
    setProduct({ ...product, categoryId, subCategoryId: "" });

    const selected = categories.find((c) => c.id === categoryId);
    setSubCategories(selected ? selected.subCategories : []);
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);

    setImages((prev) => [...prev, ...files]);

    const newPreviews = files.map((file) => URL.createObjectURL(file));
    setPreviews((prev) => [...prev, ...newPreviews]);
  };

  const removeImage = (index: number) => {
    setImages(images.filter((_, i) => i !== index));
    setPreviews(previews.filter((_, i) => i !== index));
  };

  const handleSubmit = async () => {
    const formData = new FormData();

    formData.append("name", product.name);
    formData.append("slug", product.slug);
    formData.append("description", product.description);
    formData.append("price", product.price);
    formData.append("stock", product.stock);
    formData.append("categoryId", product.categoryId);
    formData.append("subCategoryId", product.subCategoryId);
    formData.append("status", product.status);

    images.forEach((img) => {
      formData.append("images", img);
    });

    formData.append("tagIds", JSON.stringify(selectedTags.map(tag => tag.id)));

    await fetch("/api/admin/products/create", {
      method: "POST",
      body: formData,
    });

    router.push("/admin/catalogue");
  };

  const generateSlug = (text: string) => {
    return text
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, "")
      .trim()
      .replace(/\s+/g, "-");
  };

  return (
    <div className="max-w-6xl mx-auto space-y-6">

      <h1 className="text-2xl font-bold">Create Product</h1>

      {/* Tabs */}
      <div className="flex gap-6 border-b">
        {["basic","pricing","inventory","category","images","variants","status","tags"].map(tab => (
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

        {activeTab === "basic" && (
          <div className="space-y-4">
            <input
              className="w-full border p-3 rounded"
              placeholder="Product Name"
              value={product.name}
              onChange={(e) => {
                const name = e.target.value;
                setProduct({
                  ...product,
                  name,
                  slug: generateSlug(name),
                });
              }}
            />
            {/* ...other basic tab content... */}
          </div>
        )}

        {activeTab === "pricing" && (
          <div className="space-y-4">{/* Pricing tab content */}</div>
        )}

        {activeTab === "inventory" && (
          <div className="space-y-4">{/* Inventory tab content */}</div>
        )}

        {activeTab === "category" && (
          <div className="space-y-4">
            <select
              className="w-full border p-3 rounded"
              value={product.categoryId}
              onChange={(e) => handleCategoryChange(e.target.value)}
            >
              <option value="">Select Category</option>
              {categories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>

            <select
              className="w-full border p-3 rounded mt-4"
              value={product.subCategoryId}
              onChange={(e) =>
                setProduct({
                  ...product,
                  subCategoryId: e.target.value
                })
              }
              disabled={!subCategories.length}
            >
              <option value="">Select Subcategory</option>
              {subCategories.map(sub => (
                <option key={sub.id} value={sub.id}>
                  {sub.name}
                </option>
              ))}
            </select>
          </div>
        )}

        {activeTab === "images" && (
          <div className="space-y-4">
            <input
              type="file"
              multiple
              onChange={handleImageUpload}
            />

            {/* Drag-and-drop Preview Grid */}
            <DndContext
              collisionDetection={closestCenter}
              onDragEnd={(event) => {
                const {active, over} = event;
                if (over && String(active.id) !== String(over.id)) {
                  const oldIndex = previews.indexOf(String(active.id));
                  const newIndex = previews.indexOf(String(over.id));
                  setPreviews(arrayMove(previews, oldIndex, newIndex));
                  setImages(arrayMove(images, oldIndex, newIndex));
                }
              }}
            >
              <SortableContext
                items={previews}
                strategy={horizontalListSortingStrategy}
              >
                <div className="grid grid-cols-4 gap-4">
                  {previews.map((img) => (
                    <SortableImage
                      key={img}
                      id={img}
                      img={img}
                      removeImage={(id)=>removeImage(previews.indexOf(id))}
                    />
                  ))}
                </div>
              </SortableContext>
            </DndContext>
          </div>
        )}

        {activeTab === "variants" && (
          <div className="space-y-6">
            {variantTypes.map((type, index) => (
              <div key={index} className="border p-4 rounded">
                <input
                  className="border p-2 w-full mb-3"
                  placeholder="Variant Name (Color / Size / Pack)"
                  value={type.name}
                  onChange={(e) => {
                    const updated = [...variantTypes];
                    updated[index].name = e.target.value;
                    setVariantTypes(updated);
                  }}
                />

                <div className="space-y-2">
                  {type.values.map((val, vIndex) => (
                    <input
                      key={vIndex}
                      className="border p-2 w-full"
                      placeholder="Value (Red / Blue / 100 pcs)"
                      value={val}
                      onChange={(e) => {
                        const updated = [...variantTypes];
                        updated[index].values[vIndex] = e.target.value;
                        setVariantTypes(updated);
                      }}
                    />
                  ))}
                </div>

                <button
                  className="text-blue-600 mt-2"
                  type="button"
                  onClick={() => {
                    const updated = [...variantTypes];
                    updated[index].values.push("");
                    setVariantTypes(updated);
                  }}
                >
                  + Add Value
                </button>
              </div>
            ))}

            <button
              className="bg-gray-800 text-white px-4 py-2 rounded"
              type="button"
              onClick={() => {
                setVariantTypes([...variantTypes, { name: "", values: [""] }]);
              }}
            >
              Add Variant Type
            </button>

            <button
              className="bg-green-600 text-white px-4 py-2 rounded"
              type="button"
              onClick={generateVariants}
            >
              Generate Variants
            </button>

            {variantRows.length > 0 && (
              <table className="w-full border mt-4">
                <thead>
                  <tr className="bg-gray-100">
                    <th className="p-2 border">Variant</th>
                    <th className="p-2 border">Price</th>
                    <th className="p-2 border">Stock</th>
                  </tr>
                </thead>
                <tbody>
                  {variantRows.map((row, index) => (
                    <tr key={index}>
                      <td className="border p-2">{row.name}</td>
                      <td className="border p-2">
                        <input
                          className="border p-1 w-full"
                          value={row.price}
                          onChange={e => {
                            const updated = [...variantRows];
                            updated[index].price = e.target.value;
                            setVariantRows(updated);
                          }}
                        />
                      </td>
                      <td className="border p-2">
                        <input
                          className="border p-1 w-full"
                          value={row.stock}
                          onChange={e => {
                            const updated = [...variantRows];
                            updated[index].stock = e.target.value;
                            setVariantRows(updated);
                          }}
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )}

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

        {activeTab === "tags" && (
          <div className="space-y-4">
            <input
              className="border p-2 rounded w-full"
              placeholder="Search or create tag"
              value={tagInput}
              onChange={(e)=>setTagInput(e.target.value)}
            />

            <button
              onClick={addTag}
              className="bg-blue-600 text-white px-4 py-2 rounded"
            >
              Add Tag
            </button>

            {/* Existing Tags */}
            <div className="flex flex-wrap gap-2">
              {tags.map(tag => (
                <button
                  key={tag.id}
                  onClick={()=>selectTag(tag)}
                  className="bg-gray-200 px-2 py-1 rounded text-sm"
                >
                  {tag.name}
                </button>
              ))}
            </div>

            {/* Selected Tags */}
            <div className="flex flex-wrap gap-2 mt-3">
              {selectedTags.map(tag => (
                <div
                  key={tag.id}
                  className="bg-pink-100 px-3 py-1 rounded flex items-center gap-2"
                >
                  {tag.name}

                  <button
                    onClick={()=>removeTag(tag.id)}
                    className="text-red-600"
                  >
                    x
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

      </div>
      <div className="bg-white p-6 rounded-xl shadow border">

        {activeTab === "basic" && (
          <div className="space-y-4">
            <input
              className="w-full border p-3 rounded"
              placeholder="Product Name"
              value={product.name}
              onChange={(e) => {
                const name = e.target.value;
                setProduct({
                  ...product,
                  name,
                  slug: generateSlug(name),
                });
              }}
            />

            <input
              className="w-full border p-3 rounded"
              placeholder="Slug"
              value={product.slug}
              onChange={(e) =>
                setProduct({
                  ...product,
                  slug: e.target.value,
                })
              }
            />
            <p className="text-sm text-gray-500">
              URL: /product/{product.slug}
            </p>

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

        {activeTab === "pricing" && (
          <input
            type="number"
            className="w-full border p-3 rounded"
            placeholder="Price (GST Inclusive)"
            value={product.price}
            onChange={(e) =>
              setProduct({ ...product, price: e.target.value })
            }
          />
        )}

        {activeTab === "inventory" && (
          <input
            type="number"
            className="w-full border p-3 rounded"
            placeholder="Stock Quantity"
            value={product.stock}
            onChange={(e) =>
              setProduct({ ...product, stock: e.target.value })
            }
          />
        )}

        {activeTab === "category" && (
          <div className="space-y-4">

            {/* Category Dropdown */}
            <select
              className="w-full border p-3 rounded"
              value={product.categoryId}
              onChange={(e) =>
                handleCategoryChange(e.target.value)
              }
            >
              <option value="">Select Category</option>
              {categories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>

            {/* Subcategory Dropdown */}
            <select
              className="w-full border p-3 rounded"
              value={product.subCategoryId}
              onChange={(e) =>
                setProduct({
                  ...product,
                  subCategoryId: e.target.value,
                })
              }
              disabled={!subCategories.length}
            >
              <option value="">Select Subcategory</option>
              {subCategories.map((sub) => (
                <option key={sub.id} value={sub.id}>
                  {sub.name}
                </option>
              ))}
            </select>

          </div>
        )}

        {activeTab === "images" && (
          <div className="space-y-4">

            <input
              type="file"
              multiple
              onChange={handleImageUpload}
            />

            {/* Preview Grid */}
            <div className="grid grid-cols-4 gap-4">
              {previews.map((img, index) => (
                <div key={index} className="relative">

                  <img
                    src={img}
                    className="w-full h-24 object-cover rounded"
                  />

                  <button
                    onClick={() => removeImage(index)}
                    className="absolute top-1 right-1 bg-red-500 text-white px-2 text-xs rounded"
                  >
                    X
                  </button>

                </div>
              ))}
            </div>

          </div>
        )}

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
        onClick={handleSubmit}
        className="bg-pink-600 text-white px-6 py-3 rounded font-semibold"
      >
        Save Product
      </button>

    </div>
  );
}