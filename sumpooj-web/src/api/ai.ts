export async function analyzeBouquet(image: File) {

  const formData = new FormData();
  formData.append("file", image);

  const response = await fetch("http://127.0.0.1:8001/analyze-bouquet", {
    method: "POST",
    body: formData
  });

  if (!response.ok) {
    throw new Error("AI analysis failed");
  }

  return await response.json();
}