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
