"use client";


import { useEffect, useState } from "react";

const slugify = (text: string) =>
  text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .trim()
    .replace(/\s+/g, "-");

export default function CategoriesPage() {
  const [categories, setCategories] = useState<any[]>([]);
  const [newCategory, setNewCategory] = useState("");
  const [newSlug, setNewSlug] = useState("");
  const [slugEdited, setSlugEdited] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState("");
  const [subName, setSubName] = useState("");
  const [subSlug, setSubSlug] = useState("");

  const openSubCategoryForm = (categoryId: string) => {
    setSelectedCategory(categoryId);
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const fetchCategories = async () => {
    try {
      const res = await fetch("/api/admin/categories?includeSub=true");
      if (!res.ok) {
        console.error("API error: ", res.status, await res.text());
        setCategories([]);
        return;
      }
      let data;
      try {
        data = await res.json();
      } catch (jsonErr) {
        console.error("Failed to parse categories JSON:", jsonErr);
        setCategories([]);
        return;
      }
      setCategories(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error("Failed to load categories", error);
      setCategories([]);
    }
  };

  const addCategory = async () => {
    if (!newCategory) return;
    try {
      const res = await fetch("/api/admin/categories", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: newCategory,
          slug: newSlug,
        }),
      });
      if (!res.ok) {
        console.error("API error on addCategory:", res.status, await res.text());
      }
    } catch (error) {
      console.error("Failed to add category:", error);
    }
    setNewCategory("");
    setNewSlug("");
    fetchCategories();
  };

  const deleteCategory = async (id: string) => {
    if (!confirm("Delete category?")) return;

    await fetch(`/api/admin/categories?id=${id}`, {
      method: "DELETE",
    });

    fetchCategories();
  };

  const addSubCategory = async () => {
    await fetch("/api/admin/subcategories", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name: subName,
        slug: subSlug,
        categoryId: selectedCategory,
      }),
    });
    setSubName("");
    setSubSlug("");
    setSelectedCategory("");
    fetchCategories();
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">

      <h1 className="text-2xl font-bold">Categories</h1>

      {/* Add Category */}
      <div className="bg-white p-6 rounded-xl shadow border space-y-4">
        <input
          type="text"
          placeholder="Category Name"
          className="w-full border p-2 rounded"
          value={newCategory}
          onChange={(e) => {
            const name = e.target.value;
            setNewCategory(name);
            if (!slugEdited) {
              setNewSlug(slugify(name));
            }
          }}
        />

        <input
          type="text"
          placeholder="Slug"
          className="w-full border p-2 rounded"
          value={newSlug}
          onChange={(e) => {
            setSlugEdited(true);
            setNewSlug(slugify(e.target.value));
          }}
        />

        <button
          onClick={addCategory}
          className="bg-pink-600 text-white px-4 py-2 rounded"
        >
          Add Category
        </button>
      </div>

      {/* Category List */}
      <div className="bg-white rounded-xl shadow border">
        {categories.map((cat) => (
          <div key={cat.id} className="border-b p-4">
            <div className="flex justify-between items-center">
              <div>
                <h2 className="font-semibold">{cat.name}</h2>
                <p className="text-sm text-gray-500">{cat.slug}</p>
                {cat.subCategories?.map((sub: any) => (
                  <div key={sub.id} className="ml-6 text-sm text-gray-600">
                    └ {sub.name}
                  </div>
                ))}
              </div>
              <div className="flex gap-4">
                <button
                  className="text-blue-600 text-sm"
                  onClick={() => openSubCategoryForm(cat.id)}
                >
                  + Add Subcategory
                </button>
                <button
                  onClick={() => deleteCategory(cat.id)}
                  className="text-red-600"
                >
                  Delete
                </button>
              </div>
            </div>
            {selectedCategory === cat.id && (
              <div className="mt-4 bg-gray-50 p-4 rounded">
                <input
                  type="text"
                  placeholder="Subcategory Name"
                  className="border p-2 rounded w-full mb-2"
                  value={subName}
                  onChange={(e) => setSubName(e.target.value)}
                />
                <input
                  type="text"
                  placeholder="Slug"
                  className="border p-2 rounded w-full mb-2"
                  value={subSlug}
                  onChange={(e) => setSubSlug(e.target.value)}
                />
                <button
                  onClick={addSubCategory}
                  className="bg-pink-600 text-white px-4 py-2 rounded"
                >
                  Add Subcategory
                </button>
              </div>
            )}
          </div>
        ))}
      </div>

    </div>
  );
}