/**
 * ProductGrid.tsx — Responsive product grid with virtual scroll optimization
 * 3-4 column responsive grid for the POS center area
 */
import React, { useMemo, useRef, useCallback } from 'react';
import { useFinishedGoodsPOS } from '../production/hooks/useProductionPOS';
import ProductCard from './ProductCard';
import { Grid } from "react-window";
import { AutoSizer } from "react-virtualized-auto-sizer";
import type { Product } from './POSTypes';
import { getPOSCatalogCache } from './utils/posCatalogCache';

interface ProductGridProps {
  products: Product[];
  searchQuery: string;
  selectedCategory: string;
  onAddProduct: (product: Product) => void;
  isLoading?: boolean;
  locationId?: string;
}

// Map category IDs to product category names
// Supports both seed data names and normalized display names
const CATEGORY_MAP: Record<string, string[]> = {
  'all': [],
  'fresh-flowers': ['Fresh Flowers'],
  'arrangements': ['Arrangements', 'Bouquets & Arrangements'],
  'bouquets': ['Bouquets', 'Bouquets & Arrangements'],
  'plants': ['Plants', 'Plants & Succulents'],
  'greens': ['Greens & Foliage', 'Greens & Fillers'],
  'supplies': ['Supplies', 'Vases & Containers'],
  'add-ons': ['Add-Ons'],
  'gifts': ['Gift Items'],
};

const ProductGrid: React.FC<ProductGridProps> = ({
  products,
  searchQuery,
  selectedCategory,
  onAddProduct,
  isLoading = false,
  locationId,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  // Combine finished goods with products
  const { items: finishedGoods } = useFinishedGoodsPOS(locationId);
  const finishedGoodsAsProducts = finishedGoods.map(fg => ({
    id: fg.productId,
    name: fg.name,
    sku: fg.batchCode || '',
    barcode: fg.barcode || '',
    category: 'Bouquets & Arrangements', // Match POS filter
    availableStock: fg.quantityAvailable,
    sellingPrice: fg.sellingPrice,
    ...fg,
  }));
  const combinedProducts = [
    ...products.filter(p => p.availableStock && p.availableStock > 0),
    ...finishedGoodsAsProducts.filter(fg => fg.quantityAvailable > 0)
  ];
  // Filter combined products
  const filteredProducts = useMemo(() => {
    let result = combinedProducts;
    // Category filter
    if (selectedCategory !== "all") {
      result = result.filter(
        (p) =>
          p.category?.toLowerCase().replace(/\s/g, "-") === selectedCategory
      );
    }
    // Search filter
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.sku?.toLowerCase().includes(q) ||
          (p.barcode && p.barcode.toLowerCase().includes(q)) ||
          (p.internalBarcode && p.internalBarcode.toLowerCase().includes(q)) ||
          (p.recipeName && p.recipeName.toLowerCase().includes(q))
      );
    }
    return result;
  }, [combinedProducts, searchQuery, selectedCategory]);

  // Handle product add with optimistic feedback
  const handleAdd = useCallback((product: Product) => {
    onAddProduct(product);
  }, [onAddProduct]);

  if (isLoading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center">
          <div className="w-8 h-8 border-2 border-purple-600 border-t-transparent rounded-full animate-spin mx-auto mb-3" />
          <p className="text-sm text-gray-500">Loading products...</p>
        </div>
      </div>
    );
  }

  if (filteredProducts.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center py-12">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-100 rounded-full flex items-center justify-center text-gray-400">
            <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
          <p className="text-gray-500 text-sm">No products found</p>
          <p className="text-gray-400 text-xs mt-1">Try adjusting your search or category filter</p>
        </div>
      </div>
    );
  }
  // ...existing code...
  return (
    <div className="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3 sm:gap-4">
      {filteredProducts.map((product) => (
        <ProductCard
          key={product.id}
          product={product}
          onAdd={handleAdd}
        />
      ))}
    </div>
  );
};

export default ProductGrid;
