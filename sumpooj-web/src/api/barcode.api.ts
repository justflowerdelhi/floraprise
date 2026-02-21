/**
 * Barcode API
 * API endpoints for barcode generation, validation, and search
 * Florist POS + ERP SaaS Platform
 */

import axios from './axios';
import type {
  BarcodeFormat,
  BarcodeSearchResult,
  BarcodeSourceType,
} from '../components/barcode/BarcodeTypes';

// ============================================
// TYPES
// ============================================

export interface GenerateBarcodeRequest {
  /** Source type for the barcode */
  sourceType: BarcodeSourceType;
  /** Reference ID (product, batch, or production) */
  referenceId: string;
  /** Optional prefix for barcode */
  prefix?: string;
  /** Barcode format */
  format?: BarcodeFormat;
}

export interface GenerateBarcodeResponse {
  barcode: string;
  format: BarcodeFormat;
  sourceType: BarcodeSourceType;
  createdAt: string;
}

export interface ValidateBarcodeRequest {
  barcode: string;
  format?: BarcodeFormat;
}

export interface ValidateBarcodeResponse {
  isValid: boolean;
  isDuplicate: boolean;
  format: BarcodeFormat;
  existingProduct?: {
    id: string;
    name: string;
    sku: string;
  };
}

export interface SearchBarcodeRequest {
  barcode: string;
  locationId?: string;
  includeOutOfStock?: boolean;
}

export interface ProductBarcodeInfo {
  productId: string;
  productName: string;
  sku: string;
  unit: string;
  unitPrice: number;
  stockLevel: number;
  externalBarcode?: string;
  internalBarcode?: string;
  batchBarcode?: string;
  finishedBarcode?: string;
  foundByType: BarcodeSourceType;
  imageUrl?: string;
}

export interface SearchBarcodeResponse {
  found: boolean;
  product?: ProductBarcodeInfo;
  searchedTypes: BarcodeSourceType[];
}

export interface SetExternalBarcodeRequest {
  productId: string;
  barcode: string;
}

export interface GenerateInternalBarcodeRequest {
  productId: string;
  prefix?: string;
}

export interface BatchBarcodeRequest {
  batchId: string;
  productId: string;
  expiryDate?: string;
}

export interface FinishedBarcodeRequest {
  productionId: string;
  productId: string;
  batchNumber: string;
}

// ============================================
// API FUNCTIONS
// ============================================

/**
 * Generate a new barcode for a product, batch, or finished item
 */
export const generateBarcode = async (
  request: GenerateBarcodeRequest
): Promise<GenerateBarcodeResponse> => {
  const response = await axios.post<GenerateBarcodeResponse>('/barcodes/generate', request);
  return response.data;
};

/**
 * Validate a barcode (check format and uniqueness)
 */
export const validateBarcode = async (
  request: ValidateBarcodeRequest
): Promise<ValidateBarcodeResponse> => {
  const response = await axios.post<ValidateBarcodeResponse>('/barcodes/validate', request);
  return response.data;
};

/**
 * Search for a product by barcode across all barcode types
 * Search order: externalBarcode → internalBarcode → batchBarcode → finishedBarcode
 */
export const searchByBarcode = async (
  request: SearchBarcodeRequest
): Promise<SearchBarcodeResponse> => {
  const response = await axios.post<SearchBarcodeResponse>('/barcodes/search', request);
  return response.data;
};

/**
 * Set external (manufacturer) barcode for a product
 */
export const setExternalBarcode = async (
  request: SetExternalBarcodeRequest
): Promise<{ success: boolean; barcode: string }> => {
  const response = await axios.post(`/products/${request.productId}/barcode/external`, {
    barcode: request.barcode,
  });
  return response.data;
};

/**
 * Generate internal barcode for a product
 */
export const generateInternalBarcode = async (
  request: GenerateInternalBarcodeRequest
): Promise<GenerateBarcodeResponse> => {
  const response = await axios.post<GenerateBarcodeResponse>(
    `/products/${request.productId}/barcode/internal`,
    { prefix: request.prefix }
  );
  return response.data;
};

/**
 * Generate barcode for a batch
 */
export const generateBatchBarcode = async (
  request: BatchBarcodeRequest
): Promise<GenerateBarcodeResponse> => {
  const response = await axios.post<GenerateBarcodeResponse>(
    `/batches/${request.batchId}/barcode`,
    request
  );
  return response.data;
};

/**
 * Generate barcode for finished production item
 */
export const generateFinishedBarcode = async (
  request: FinishedBarcodeRequest
): Promise<GenerateBarcodeResponse> => {
  const response = await axios.post<GenerateBarcodeResponse>(
    `/production/${request.productionId}/barcode`,
    request
  );
  return response.data;
};

/**
 * Get all barcodes for a product
 */
export const getProductBarcodes = async (
  productId: string
): Promise<{
  externalBarcode?: string;
  internalBarcode?: string;
  batchBarcodes: Array<{ batchId: string; barcode: string; expiryDate?: string }>;
  finishedBarcodes: Array<{ productionId: string; barcode: string; batchNumber: string }>;
}> => {
  const response = await axios.get(`/products/${productId}/barcodes`);
  return response.data;
};

/**
 * Delete a barcode from a product
 */
export const deleteBarcode = async (
  productId: string,
  barcodeType: 'external' | 'internal'
): Promise<{ success: boolean }> => {
  const response = await axios.delete(`/products/${productId}/barcode/${barcodeType}`);
  return response.data;
};

/**
 * Quick barcode search (returns minimal product info for POS)
 * Optimized for fast scanner input
 */
export const quickBarcodeSearch = async (
  barcode: string,
  locationId?: string
): Promise<BarcodeSearchResult | null> => {
  try {
    const response = await axios.get<BarcodeSearchResult>('/barcodes/quick-search', {
      params: { barcode, locationId },
    });
    return response.data;
  } catch {
    return null;
  }
};

/**
 * Bulk barcode validation (for imports)
 */
export const bulkValidateBarcodes = async (
  barcodes: string[]
): Promise<
  Array<{
    barcode: string;
    isValid: boolean;
    isDuplicate: boolean;
    error?: string;
  }>
> => {
  const response = await axios.post('/barcodes/bulk-validate', { barcodes });
  return response.data;
};

// Export default object for convenience
const barcodeApi = {
  generateBarcode,
  validateBarcode,
  searchByBarcode,
  setExternalBarcode,
  generateInternalBarcode,
  generateBatchBarcode,
  generateFinishedBarcode,
  getProductBarcodes,
  deleteBarcode,
  quickBarcodeSearch,
  bulkValidateBarcodes,
};

export default barcodeApi;
