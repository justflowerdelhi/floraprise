import { PrismaClient } from "@prisma/client";
import { NextResponse } from "next/server";
import fs from "fs";
import path from "path";

const prisma = new PrismaClient();

export async function POST(req: Request) {

	const formData = await req.formData();

	const name = formData.get("name") as string;
	const slug = formData.get("slug") as string;
	const description = formData.get("description") as string;
	const price = parseFloat(formData.get("price") as string);
	const stock = parseInt(formData.get("stock") as string);
	const categoryId = formData.get("categoryId") as string;
	const subCategoryId = formData.get("subCategoryId") as string;
	const status = formData.get("status") as string;

	const files = formData.getAll("images") as File[];

	const uploadedImages: string[] = [];

	for (const file of files) {

		const bytes = await file.arrayBuffer();
		const buffer = Buffer.from(bytes);

		const fileName = Date.now() + "-" + file.name;
		const filePath = path.join(process.cwd(), "public/uploads", fileName);

		fs.writeFileSync(filePath, buffer);

		uploadedImages.push("/uploads/" + fileName);
	}

	let tagIds: string[] = [];
	try {
		tagIds = JSON.parse(formData.get("tagIds") as string);
	} catch {}

	const product = await prisma.product.create({
		data: {
			name,
			slug,
			description,
			price,
			stock,
			status,
			categoryId,
			subCategoryId,
			images: {
				create: uploadedImages.map((url) => ({ url })),
			},
			tags: tagIds.length
				? {
						create: tagIds.map((tagId) => ({ tagId })),
					}
				: undefined,
		},
	});

	return NextResponse.json(product);
}
