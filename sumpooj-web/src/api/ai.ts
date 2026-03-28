import api from './axios';

export async function analyzeBouquet(image: File) {
  const formData = new FormData();
  formData.append("file", image);

  const response = await api.post("/ai/analyze-bouquet", formData);

  return response.data;
}