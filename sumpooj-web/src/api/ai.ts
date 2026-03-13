import api from './axios';

export async function analyzeBouquet(image: File) {
  const formData = new FormData();
  formData.append("file", image);

  const response = await api.post("/ai/analyze-bouquet", formData, {
    headers: { "Content-Type": "multipart/form-data" },
  });

  return response.data;
}