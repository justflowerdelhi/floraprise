from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from openai import OpenAI
from dotenv import load_dotenv
import os
import base64
import json
import re

load_dotenv()

# ---------------------------------------------------
# FastAPI App
# ---------------------------------------------------

app = FastAPI()

# ---------------------------------------------------
# OpenAI Client
# ---------------------------------------------------

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# ---------------------------------------------------
# CORS
# ---------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------
# Temporary Storage (until database added)
# ---------------------------------------------------

bouquet_recipes = []
products = []

# ---------------------------------------------------
# AI Bouquet Analyzer
# ---------------------------------------------------

@app.post("/analyze-bouquet")
async def analyze_bouquet(file: UploadFile = File(...)):

    image_bytes = await file.read()
    image_base64 = base64.b64encode(image_bytes).decode("utf-8")

    response = client.responses.create(
        model="gpt-4o-mini",
        input=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": """
You are a professional florist.

Analyze the bouquet image and identify:

1. Flowers and stem counts
2. Bouquet style (hand tied, arrangement, basket etc)
3. Shape (round, heart, oval, one sided, cascade etc)
4. Height style (compact, medium, tall)

Return ONLY JSON in this format:

{
 "style":"Floral Arrangement",
 "shape":"Heart",
 "height":"Compact",
 "flowers":[
   {"flower":"Rose","color":"Red","stem_count":50}
 ]
}
"""
                    },
                    {
                        "type": "input_image",
                        "image_url": f"data:image/jpeg;base64,{image_base64}"
                    }
                ]
            }
        ]
    )

    text = response.output[0].content[0].text

    # Clean markdown
    text = text.replace("```json", "").replace("```", "")

    match = re.search(r"\{.*\}", text, re.DOTALL)

    if match:
        try:
            result = json.loads(match.group())
        except:
            result = {"flowers": []}
    else:
        result = {"flowers": []}

    return result

# ---------------------------------------------------
# Save Bouquet Recipe
# ---------------------------------------------------

@app.post("/api/bouquet-recipes")
async def save_bouquet_recipe(data: dict):

    recipe = {
        "name": data.get("name"),
        "components": data.get("components"),
        "style": data.get("style"),
        "shape": data.get("shape"),
        "height": data.get("height")
    }

    bouquet_recipes.append(recipe)

    return {
        "status": "saved",
        "recipe": recipe
    }

# ---------------------------------------------------
# Get Bouquet Recipes
# ---------------------------------------------------

@app.get("/api/bouquet-recipes")
async def get_bouquet_recipes():

    return {
        "recipes": bouquet_recipes
    }

# ---------------------------------------------------
# Create Catalog Product (AI → Catalog)
# ---------------------------------------------------

@app.post("/api/ai-create-product")
async def create_ai_product(data: dict):

    product = {
        "name": data.get("name"),
        "price": data.get("price"),
        "cost": data.get("cost"),
        "components": data.get("components"),
        "image": data.get("image"),
        "category": "Bouquets",
        "source": "AI Scanner"
    }

    products.append(product)

    return {
        "status": "created",
        "product": product
    }

# ---------------------------------------------------
# Get AI Created Products
# ---------------------------------------------------

@app.get("/api/products")
async def get_products():

    return {
        "products": products
    }