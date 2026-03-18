"use client"

import { useEffect, useState } from "react"
import { generateSKU } from "../../../../lib/utils/generateSKU"
import { generateVariantMatrix } from "../../../../lib/utils/generateVariantMatrix"

type Option = {
  name: string
  values: string
}

interface VariantMatrixGeneratorProps {
  options: Option[];
  setOptions: (opts: Option[]) => void;
  matrix: any[];
  setMatrix: (matrix: any[]) => void;
  baseSku: string;
  setBaseSku: (sku: string) => void;
  variants: any[];
  setVariants: (variants: any[]) => void;
}

export default function VariantMatrixGenerator({
  options,
  setOptions,
  matrix,
  setMatrix,
  baseSku,
  setBaseSku,
  variants,
  setVariants,
}: VariantMatrixGeneratorProps) {

  // expose variants to product form
  useEffect(() => {
    ;(window as any).generatedVariants = variants;
  }, [variants]);

  const updateOption = (index: number, field: string, value: string) => {
    const newOptions = [...options];
    (newOptions as any)[index][field] = value;
    setOptions(newOptions);
  };

  const addOption = () => {
    setOptions([...options, { name: "", values: "" }]);
  };

  const generateMatrix = () => {
    const formatted = options
      .filter((o) => o.name && o.values)
      .map((o) => ({
        name: o.name,
        values: o.values.split(",").map((v) => v.trim()),
      }));

    const result = generateVariantMatrix(formatted);
    setMatrix(result);

    // create variant objects
    const variantObjects = result.map((row: any) => {
      const values = row.options.map((o: any) => o.value);
      return {
        options: row.options,
        sku: baseSku ? generateSKU(baseSku, values) : "",
        price: "",
        stock: "",
      };
    });
    setVariants(variantObjects);
  };

  return (
    <div className="border p-4 rounded-xl space-y-4">

      <div className="mb-3">
        <label className="text-sm font-medium">
          Base SKU
        </label>

        <input
          className="border p-2 rounded w-full"
          placeholder="Example: TSHIRT"
          value={baseSku}
          onChange={(e) => setBaseSku(e.target.value)}
        />
      </div>

      <h2 className="text-lg font-semibold">
        Variant Generator
      </h2>

      {options.map((option, i) => (
        <div key={i} className="flex gap-3">

          <input
            placeholder="Option Name (Size)"
            className="border p-2 rounded w-40"
            value={option.name}
            onChange={(e) =>
              updateOption(i, "name", e.target.value)
            }
          />

          <input
            placeholder="Values (S,M,L)"
            className="border p-2 rounded flex-1"
            value={option.values}
            onChange={(e) =>
              updateOption(i, "values", e.target.value)
            }
          />

        </div>
      ))}

      <div className="flex gap-3">

        <button
          onClick={addOption}
          className="bg-gray-200 px-3 py-2 rounded"
        >
          Add Option
        </button>

        <button
          onClick={generateMatrix}
          className="bg-black text-white px-4 py-2 rounded"
        >
          Generate Variants
        </button>

      </div>

      {matrix.length > 0 && (
        <div className="border rounded p-4 mt-4">

          <h3 className="font-medium mb-3">
            Variant List
          </h3>

          <table className="w-full border text-sm">
            <thead className="bg-gray-100">
              <tr>
                <th className="p-2 border">Variant</th>
                <th className="p-2 border">SKU</th>
                <th className="p-2 border">Price</th>
                <th className="p-2 border">Stock</th>
              </tr>
            </thead>

            <tbody>
              {matrix.map((row, i) => (
                <tr key={i}>
                  <td className="p-2 border">
                    {row.options.map((o: any) => o.value).join(" / ")}
                  </td>
                  <td className="p-2 border">
                    <input
                      className="border p-1 w-full"
                      value={variants[i]?.sku || ""}
                      onChange={(e) => {
                        const newVariants = [...variants]
                        newVariants[i].sku = e.target.value
                        setVariants(newVariants)
                      }}
                    />
                  </td>
                  <td className="p-2 border">
                    <input
                      className="border p-1 w-full"
                      value={variants[i]?.price || ""}
                      onChange={(e) => {
                        const newVariants = [...variants]
                        newVariants[i].price = e.target.value
                        setVariants(newVariants)
                      }}
                    />
                  </td>
                  <td className="p-2 border">
                    <input
                      className="border p-1 w-full"
                      value={variants[i]?.stock || ""}
                      onChange={(e) => {
                        const newVariants = [...variants]
                        newVariants[i].stock = e.target.value
                        setVariants(newVariants)
                      }}
                    />
                    {/* Image upload per variant */}
                    <input
                      type="file"
                      className="mt-1"
                      onChange={(e) => {
                        const file = e.target.files?.[0];
                        if (!file) return;
                        const updated = [...variants];
                        updated[i].file = file;
                        updated[i].preview = URL.createObjectURL(file);
                        setVariants(updated);
                      }}
                    />
                    {variants[i]?.preview && (
                      <img src={variants[i].preview} className="w-12 h-12 mt-1" />
                    )}
                  </td>
                </tr>
              ))}
            </tbody>

          </table>

        </div>
      )}

    </div>
  )
}