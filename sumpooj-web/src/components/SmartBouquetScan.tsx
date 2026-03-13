import React, { useState } from "react";
import api from "../api/axios";

export default function SmartBouquetScan() {

  const [flowers, setFlowers] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [imagePreview, setImagePreview] = useState<string | null>(null);

  async function handleUpload(e: React.ChangeEvent<HTMLInputElement>) {

    const file = e.target.files?.[0];
    if (!file) return;

    setImagePreview(URL.createObjectURL(file));

    const formData = new FormData();
    formData.append("file", file);

    setLoading(true);

    try {

      const response = await api.post("/ai/analyze-bouquet", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      setFlowers(response.data.flowers || []);

    } catch (err) {

      console.error(err);
      alert("AI scan failed");

    }

    setLoading(false);
  }

  return (
    <div style={{ padding: 20 }}>

      <input type="file" accept="image/*" onChange={handleUpload} />

      {imagePreview && (
        <div style={{ marginTop: 20 }}>
          <img src={imagePreview} width="300" />
        </div>
      )}

      {loading && <p>Analyzing bouquet...</p>}

      {flowers.length > 0 && (
        <div style={{ marginTop: 20 }}>

          <h3>Detected Flowers</h3>

          {flowers.map((f, i) => (
            <div key={i} style={{
              padding: 10,
              border: "1px solid #ddd",
              borderRadius: 8,
              marginBottom: 8
            }}>
              🌸 {f.type} ({f.color}) — {f.stem_count} stems
            </div>
          ))}

        </div>
      )}

    </div>
  );
}