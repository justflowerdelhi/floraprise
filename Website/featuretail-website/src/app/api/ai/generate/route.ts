import { NextResponse } from "next/server";
import OpenAI from "openai";

export async function POST(req: Request) {
  try {
    console.log("AI route hit");
    let body;
    try {
      body = await req.json();
    } catch {
      return NextResponse.json(
        { error: "Invalid request body" },
        { status: 400 }
      );
    }
    const productName = body.productName;
    console.log("Product:", productName);
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });
    if (!process.env.OPENAI_API_KEY) {
      throw new Error("OPENAI_API_KEY missing");
    }
    const completion = await openai.chat.completions.create({
      model: "gpt-4.1-mini",
      messages: [
        {
          role: "user",
          content: `Generate SEO product content for ${productName} and return JSON`
        }
      ]
    });
    let result = completion.choices[0].message.content || "";
    result = result.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(result);
    return NextResponse.json(parsed);
  } catch (error:any) {
    console.error("AI ROUTE ERROR:", error);
    return NextResponse.json(
      {
        error: "AI generation failed",
        details: error.message
      },
      { status: 500 }
    );
  }
}
