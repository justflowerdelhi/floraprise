import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkOrphanedProducts() {
  // Find products with missing categories
  const productsWithInvalidCategory = await prisma.product.findMany({
    where: {
      category: null,
    },
  });

  // Find products with no images
  const productsWithNoImages = await prisma.product.findMany({
    where: {
      images: { none: {} },
    },
  });

  // Find products with no variants
  const productsWithNoVariants = await prisma.product.findMany({
    where: {
      variants: { none: {} },
    },
  });

  console.log('Products with invalid category:', productsWithInvalidCategory);
  console.log('Products with no images:', productsWithNoImages);
  console.log('Products with no variants:', productsWithNoVariants);
}

checkOrphanedProducts().finally(() => prisma.$disconnect());
