/**
 * product.api.ts — Products API Service
 *
 * Endpoints:
 *   GET  /products/search
 *   GET  /products/:id
 *   PUT  /products/:id
 *   POST /products
 *   GET  /products/validate-sku
 *   PUT  /products/:id/deactivate
 *   PUT  /products/:id/activate
 *   GET  /products/low-stock
 *   GET  /products/reorder
 */
import api from './axios';
import type { Product } from '../pages/orders/OrderTypes';

// ─── Types ──────────────────────────────────────────────────

export interface ProductSearchParams {
  Query?: string;
  ProductType?: string;
  Category?: string;
  IsActive?: boolean;
  IsPerishable?: boolean;
  LowStockOnly?: boolean;
  Page?: number;
  PageSize?: number;
}

export interface FlowerAttributesRequest {
  color?: string | null;
  variety?: string | null;
  grade?: string | null;
  countryOfOrigin?: string | null;
  seasonality?: string[];
}

export interface SupplierInfoRequest {
  supplierId?: string | null;
  leadTimeDays?: number | null;
}

export interface AccountingInfoRequest {
  incomeAccount?: string;
  expenseAccount?: string;
}

export interface ProductSettingsRequest {
  status: string;
  allowAsRawMaterial: boolean;
  availableOnline: boolean;
  commissionEligible: boolean;
}

export interface CreateProductRequest {
  productName: string;
  sku: string;
  barcode?: string | null;
  productType: string;
  category?: string | null;
  brand?: string | null;
  description?: string | null;
  tags?: string[];
  unitOfMeasure: string;
  retailPrice: number;
  costPrice: number;
  wholesalePrice?: number | null;
  weddingEventPrice?: number | null;
  taxCategory: string;
  trackInventory: boolean;
  trackBatch: boolean;
  openingStock?: number | null;
  reorderLevel?: number | null;
  shelfLifeDays?: number | null;
  expiryAlertDays?: number | null;
  temperatureNotes?: string | null;
  isMultiUnit?: boolean;
  avgUnitsPerStem?: number;
  flowerAttributes?: FlowerAttributesRequest | null;
  supplier?: SupplierInfoRequest | null;
  accounting: AccountingInfoRequest;
  settings: ProductSettingsRequest;
}

export interface UpdateProductRequest {
  productName?: string | null;
  barcode?: string | null;
  brand?: string | null;
  description?: string | null;
  tags?: string[] | null;
  retailPrice?: number | null;
  costPrice?: number | null;
  wholesalePrice?: number | null;
  weddingEventPrice?: number | null;
  taxCategory?: string | null;
  trackInventory?: boolean | null;
  trackBatch?: boolean | null;
  reorderLevel?: number | null;
  shelfLifeDays?: number | null;
  expiryAlertDays?: number | null;
  temperatureNotes?: string | null;
  isMultiUnit?: boolean | null;
  avgUnitsPerStem?: number | null;
  flowerAttributes?: FlowerAttributesRequest | null;
  supplier?: SupplierInfoRequest | null;
  accounting?: AccountingInfoRequest | null;
  settings?: ProductSettingsRequest | null;
}

// ─── API Functions ──────────────────────────────────────────

export const searchProducts = async (params: ProductSearchParams = {}) => {
  const res = await api.get('/products/search', { params });
  return res.data;
};

export const getProductById = async (id: string) => {
  const res = await api.get(`/products/${id}`);
  return res.data;
};

export const updateProduct = async (id: string, data: UpdateProductRequest) => {
  const res = await api.put(`/products/${id}`, data);
  return res.data;
};

export const createProduct = async (data: CreateProductRequest) => {
  const res = await api.post('/products', data);
  return res.data;
};

export const validateSku = async (sku: string, excludeProductId?: string) => {
  const res = await api.get('/products/validate-sku', { params: { sku, excludeProductId } });
  return res.data;
};

export const deactivateProduct = async (id: string) => {
  const res = await api.put(`/products/${id}/deactivate`);
  return res.data;
};

export const activateProduct = async (id: string) => {
  const res = await api.put(`/products/${id}/activate`);
  return res.data;
};

export const getLowStockProducts = async () => {
  const res = await api.get('/products/low-stock');
  return res.data;
};

export const getReorderProducts = async () => {
  const res = await api.get('/products/reorder');
  return res.data;
};
// ─── Product Normalization ──────────────────────────────────
// Maps API response fields to Product interface
// Handles field name mismatches (e.g., retailPrice → sellingPrice)

// Map ProductCategory enum → POS sidebar category names
// API returns enum names: "Roses", "Lilies", "MixedFlowers", etc.
const CATEGORY_ENUM_TO_DISPLAY: Record<string, string> = {
  'Roses': 'Fresh Flowers',
  'Lilies': 'Fresh Flowers',
  'Tulips': 'Fresh Flowers',
  'Orchids': 'Fresh Flowers',
  'Carnations': 'Fresh Flowers',
  'MixedFlowers': 'Fresh Flowers',
  'Seasonal': 'Fresh Flowers',
  'Exotic': 'Fresh Flowers',
  'WeddingFlowers': 'Arrangements',
  'SymPathyFlowers': 'Arrangements',
  'CelebrationFlowers': 'Bouquets',
  'IndoorPlants': 'Plants',
  'OutdoorPlants': 'Plants',
  'Vases': 'Gift Items',
  'Ribbons': 'Supplies',
  'Cards': 'Add-Ons',
  'ChocolatesAndGifts': 'Gift Items',
  'Other': 'Add-Ons',
};

export const normalizeProduct = (apiData: any): Product => {
  const sellingPrice = apiData.sellingPrice ?? apiData.retailPrice ?? 0;
  const costPrice = apiData.costPrice ?? 0;

  // Use raw enum category for reliable mapping to POS sidebar names
  const category =
    CATEGORY_ENUM_TO_DISPLAY[apiData.category] ||
    apiData.category ||
    'Fresh Flowers';

  return {
    id: apiData.id || '',
    name: apiData.name || apiData.productName || '',
    sku: apiData.sku || '',
    barcode: apiData.barcode,
    internalBarcode: apiData.internalBarcode,
    batchBarcode: apiData.batchBarcode,
    finishedBarcode: apiData.finishedBarcode,
    category,
    sellingPrice: Number(sellingPrice) || 0,
    costPrice: Number(costPrice) || 0,
    taxRate: Number(apiData.taxRate) || 0,
    taxRuleId: apiData.taxRuleId,
    taxRuleName: apiData.taxRuleName,
    taxIsInclusive: apiData.taxIsInclusive ?? false,
    availableStock: Number(apiData.availableStock ?? apiData.stockQuantity ?? apiData.currentStock ?? apiData.stockOnHand ?? apiData.quantityOnHand ?? apiData.openingStock) || 0,
    isPerishable: apiData.isPerishable ?? false,
    trackBatch: apiData.trackBatch ?? false,
    imageUrl: apiData.imageUrl,
    batches: Array.isArray(apiData.batches) ? apiData.batches : [],
  };
};

export const normalizeProducts = (apiData: any): Product[] => {
  const arr = Array.isArray(apiData) ? apiData : [];
  return arr.map(normalizeProduct);
};