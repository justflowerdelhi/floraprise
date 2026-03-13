import { useState } from "react";
import api from "../../api/axios";

export default function BouquetScanner() {

  const stemPrices: any = {
    rose: 1.2,
    chrysanthemum: 0.8,
    anthurium: 2.5,
    carnation: 0.7,
    lily: 2.0
  };
  const [style, setStyle] = useState("");
  const [shape, setShape] = useState("");
  const [height, setHeight] = useState("");
  const [image, setImage] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [flowers, setFlowers] = useState<any[]>([]);
  const [recipe, setRecipe] = useState<any | null>(null);
  const [loading, setLoading] = useState(false);
  const [saved, setSaved] = useState(false);

  const flowerList = Array.isArray(flowers) ? flowers : [];

  const totalStems = flowerList.reduce(
    (sum, f) => sum + (f.stem_count || 0),
    0
  );

  const calculatePrice = () => {

    let flowerCost = 0;

    flowerList.forEach((f) => {
      const name = (f.flower || f.type || "").toLowerCase();
      let price = 1;

      Object.keys(stemPrices).forEach((key) => {
        if (name.includes(key)) {
          price = stemPrices[key];
        }
      });

      flowerCost += price * (f.stem_count || 0);
    });

    const laborCost = 5;
    const totalCost = flowerCost + laborCost;
    const markup = 2.2;

    return {
      flowerCost,
      laborCost,
      totalCost,
      sellingPrice: totalCost * markup
    };
  };

  const price = calculatePrice();
  const profit = price.sellingPrice - price.totalCost;

  const handleFile = (e: any) => {

    const file = e.target.files[0];
    if (!file) return;

    setImage(file);
    setPreview(URL.createObjectURL(file));
    setFlowers([]);
    setRecipe(null);
    setSaved(false);
  };

  const analyze = async () => {

    if (!image) return;

    setLoading(true);

    const formData = new FormData();
    formData.append("file", image);

    try {
      const res = await api.post("/ai/analyze-bouquet", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      const data = res.data;

      setFlowers(data.flowers || []);
      setStyle(data.style || "");
      setShape(data.shape || "");
      setHeight(data.height || "");
    } catch (err) {
      console.error("Bouquet analysis failed:", err);
      setFlowers([]);
    } finally {
      setLoading(false);
    }
  };

  const generateRecipe = () => {

    if (!flowerList.length) return;

    const components = flowerList.map((f) => ({
      flower: f.flower || f.type,
      color: f.color,
      stems: f.stem_count
    }));

    setRecipe({
      name: "Designer Bouquet",
      components
    });
  };

  const saveRecipe = async () => {

    if (!recipe) return;

    try {
      await api.post("/ai/bouquet-recipes", recipe);
      setSaved(true);
    } catch (err) {
      console.error("Failed to save recipe:", err);
    }
  };

  const createCatalogProduct = async () => {

    if (!recipe) return;

    const product = {
      name: recipe.name || "AI Designer Bouquet",
      price: price.sellingPrice,
      cost: price.totalCost,
      components: recipe.components,
      image: preview
    };

    try {
      await api.post("/ai/bouquet-recipes", {
        ...product,
        name: product.name,
      });
      alert("Product created in catalog!");
    } catch (err) {
      console.error("Failed to create product:", err);
    }
  };

  return (

    <div style={{ padding: 30, maxWidth: 700 }}>

      <h1>🌸 Floraprise Smart AI</h1>

      <p>
        Upload a bouquet photo and Floraprise AI will detect flowers and estimate stem counts.
      </p>

      {/* Upload */}

      <label
        style={{
          background: "#1976d2",
          color: "white",
          padding: "10px 18px",
          borderRadius: 6,
          cursor: "pointer"
        }}
      >
        📷 Browse Photo
        <input
          type="file"
          onChange={handleFile}
          style={{ display: "none" }}
        />
      </label>


      {/* Preview */}

      {preview && (
        <div style={{ marginTop: 20 }}>
          <img
            src={preview}
            width={250}
            style={{ borderRadius: 8 }}
          />
        </div>
      )}


      {/* Analyze */}

      {image && (
        <button
          onClick={analyze}
          style={{
            marginTop: 15,
            background: "#2e7d32",
            color: "white",
            border: "none",
            padding: "10px 18px",
            borderRadius: 6
          }}
        >
          🔍 Analyze Bouquet
        </button>
      )}

      {loading && <p>Analyzing bouquet...</p>}


      {/* Detected Flowers */}

      {flowerList.length > 0 && (

        <div
          style={{
            marginTop: 20,
            background: "#f8f9fa",
            padding: 15,
            borderRadius: 8,
            width: 350
          }}
        >

          <h3>Detected Flowers</h3>

          <p>
            <strong>Total Stems:</strong> {totalStems}
          </p>

          {flowerList.map((f, i) => (

            <div key={i}>
              🌸 <b>{f.flower || f.type}</b> ({f.color}) — {f.stem_count} stems
            </div>

          ))}


          {style && (
            <div style={{ marginTop: 10 }}>
              <b>Style:</b> {style}
            </div>
          )}
          {shape && (
            <div>
              <b>Shape:</b> {shape}
            </div>
          )}
          {height && (
            <div>
              <b>Height:</b> {height}
            </div>
          )}
        </div>
      )}


      {/* Create Recipe */}

      {flowerList.length > 0 && !recipe && (

        <button
          onClick={generateRecipe}
          style={{
            marginTop: 15,
            background: "#f39c12",
            color: "white",
            border: "none",
            padding: "10px 18px",
            borderRadius: 6
          }}
        >
          ✨ Create Bouquet Recipe
        </button>

      )}


      {/* Recipe */}

      {recipe && (

        <div
          style={{
            marginTop: 20,
            background: "#f5e9d3",
            padding: 15,
            borderRadius: 8,
            width: 350
          }}
        >

          <h3>Generated Bouquet Recipe</h3>

          {recipe.components.map((c: any, i: number) => (
            <div key={i}>
              🌸 {c.stems} {c.color} {c.flower}
            </div>
          ))}

          <button
            onClick={saveRecipe}
            style={{
              marginTop: 10,
              background: "#1976d2",
              color: "white",
              border: "none",
              padding: "8px 14px",
              borderRadius: 6
            }}
          >
            💾 Save Recipe to Catalog
          </button>

          {saved && (
            <div
              style={{
                marginTop: 10,
                background: "#e8f5e9",
                padding: 10,
                borderRadius: 6,
                color: "#2e7d32"
              }}
            >
              ✅ Recipe saved to catalog
            </div>
          )}

        </div>

      )}


      {/* Price Estimate */}

      {flowerList.length > 0 && (

        <div
          style={{
            marginTop: 20,
            background: "#eef7ff",
            padding: 15,
            borderRadius: 8,
            width: 350
          }}
        >

          <h3>💰 Bouquet Price Estimate</h3>

          <div>Flower Cost: ${price.flowerCost.toFixed(2)}</div>
          <div>Labor Cost: ${price.laborCost.toFixed(2)}</div>

          <hr />

          <b>Total Cost: ${price.totalCost.toFixed(2)}</b>
          <div>Profit: ${profit.toFixed(2)}</div>

          <div style={{ marginTop: 5 }}>
            Retail Price:
            <b style={{ color: "#2e7d32" }}>
              ${price.sellingPrice.toFixed(2)}
            </b>
          </div>

          <button
            onClick={createCatalogProduct}
            style={{
              marginTop: 12,
              background: "#2e7d32",
              color: "white",
              border: "none",
              padding: "10px 16px",
              borderRadius: 6,
              cursor: "pointer"
            }}
          >
            🌸 Create Catalog Product
          </button>

        </div>

      )}

    </div>
  );
}