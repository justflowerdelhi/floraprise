/*
  Warnings:

  - You are about to drop the column `featured` on the `Product` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Product" DROP COLUMN "featured",
ADD COLUMN     "comparePrice" DOUBLE PRECISION,
ADD COLUMN     "sku" TEXT,
ALTER COLUMN "description" DROP NOT NULL,
ALTER COLUMN "stock" SET DEFAULT 0;
