import { NextResponse } from "next/server";
import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

export async function POST(req: Request) {

  try {

    const { productName } = await req.json();

    if (!productName) {
      return NextResponse.json(
        { error: "Product name required" },
        { status: 400 }
      );
    }

    const prompt = `
You are an ecommerce SEO expert.

Generate optimized product listing content.

Product Name: ${productName}

Return STRICT JSON only in this format:

{
"title":"",
"description":"",
"bulletPoints":[],
"seoTitle":"",
"seoDescription":"",
"seoKeywords":[],
"tags":[],
"searchKeywords":[],
"suggestedCategory":""
}

Rules:

Title
• Optimized for ecommerce SEO
• Maximum 120 characters

Description
• 2-3 paragraphs
• Persuasive and informative

Bullet Points
• 5 selling points
• Short and clear

SEO Title
• Google optimized
• Under 60 characters

SEO Description
• Under 160 characters

SEO Keywords
• 8 keywords

Tags
• 6 ecommerce tags

Search Keywords
• 10 long-tail keywords

Suggested Category
• Ecommerce category suggestion
`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4.1-mini",
      messages: [
        {
          role: "user",
          content: prompt
        }
      ]
    });

    const result = completion.choices[0].message.content;

    return NextResponse.json({
      result
    });

  } catch (error) {

    console.error("AI GENERATION ERROR:", error);

    return NextResponse.json(
      { error: "AI generation failed" },
      { status: 500 }
    );

  }

}