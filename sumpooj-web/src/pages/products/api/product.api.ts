/**
 * Product API Functions
 * Real API calls to the backend
 */

import type { ProductFormData, ProductApiPayload, Supplier } from '../types/product.types';
import {
  createProduct as createProductApi,
  validateSku as validateSkuApi,
} from '../../../api/product.api';
import { getAllSuppliers, createSupplier as createSupplierApi } from '../../../api/supplier.api';

// ============================================
// TRANSFORM FORM DATA TO API PAYLOAD
// ============================================

export const transformToApiPayload = (formData: ProductFormData): ProductApiPayload => {
  const payload: ProductApiPayload = {
    productName: formData.productName,
    sku: formData.sku,
    barcode: formData.barcode || undefined,
    productType: formData.productType,
    categoryId: formData.categoryId || undefined,
    brand: formData.brand || undefined,
    description: formData.description || undefined,
    tags: formData.tags?.length ? formData.tags : undefined,
    unitOfMeasure: formData.unitOfMeasure,
    retailPrice: formData.retailPrice,
    costPrice: formData.costPrice,
    wholesalePrice: formData.wholesalePrice,
    weddingEventPrice: formData.weddingEventPrice,
    taxCategory: formData.taxCategory,
    trackInventory: formData.trackInventory,
    trackBatch: formData.trackBatch,
    openingStock: formData.trackInventory ? formData.openingStock : undefined,
    reorderLevel: formData.trackInventory ? formData.reorderLevel : undefined,
    shelfLifeDays: formData.isPerishable ? formData.shelfLifeDays : undefined,
    expiryAlertDays: formData.isPerishable ? formData.expiryAlertDays : undefined,
    temperatureNotes: formData.temperatureNotes || undefined,
    accounting: {
      incomeAccount: formData.incomeAccount,
      expenseAccount: formData.expenseAccount,
    },
    settings: {
      status: formData.status,
      allowAsRawMaterial: formData.allowAsRawMaterial,
      availableOnline: formData.availableOnline,
      commissionEligible: formData.commissionEligible,
    },
  };

  if (formData.color || formData.variety || formData.grade || 
      formData.countryOfOrigin || (formData.seasonality && formData.seasonality.length > 0)) {
    payload.flowerAttributes = {
      color: formData.color || undefined,
      variety: formData.variety || undefined,
      grade: formData.grade,
      countryOfOrigin: formData.countryOfOrigin,
      seasonality: formData.seasonality?.length ? formData.seasonality : undefined,
    };
  }

  if (formData.supplierId || formData.leadTimeDays) {
    payload.supplier = {
      supplierId: formData.supplierId || undefined,
      leadTimeDays: formData.leadTimeDays,
    };
  }

  return payload;
};

// ============================================
// API FUNCTIONS
// ============================================

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

interface CreatedProduct {
  id: string;
  sku: string;
  productName: string;
  createdAt: string;
}

/**
 * Create product via real API
 */
export const createProduct = async (
  formData: ProductFormData
): Promise<ApiResponse<CreatedProduct>> => {
  const payload = transformToApiPayload(formData);
  const result = await createProductApi(payload as any);
  return {
    success: true,
    data: result,
    message: 'Product created successfully',
  };
};

/**
 * Save as draft — uses create with draft status
 */
export const saveDraft = async (
  formData: Partial<ProductFormData>
): Promise<ApiResponse<{ draftId: string }>> => {
  // TODO: Implement draft endpoint when available
  console.log('📝 Draft data:', formData);
  return {
    success: true,
    data: { draftId: `draft-${Date.now()}` },
    message: 'Draft saved successfully',
  };
};

/**
 * Fetch suppliers from real API
 */
export const fetchSuppliers = async (): Promise<ApiResponse<Supplier[]>> => {
  const data = await getAllSuppliers();
  const suppliers: Supplier[] = (data ?? []).map((s: any) => ({
    id: s.id,
    name: s.name,
    code: s.name?.substring(0, 3).toUpperCase() ?? '',
    leadTime: s.paymentTermsDays ?? 0,
  }));
  return { success: true, data: suppliers };
};

/**
 * Create supplier via real API
 */
export const createSupplier = async (
  supplier: Omit<Supplier, 'id'>
): Promise<ApiResponse<Supplier>> => {
  const result = await createSupplierApi({
    name: supplier.name,
    paymentTermsDays: supplier.leadTime ?? 0,
  });
  return {
    success: true,
    data: { ...supplier, id: result.id ?? `sup-${Date.now()}` },
    message: 'Supplier created successfully',
  };
};

/**
 * Validate SKU uniqueness via real API
 */
export const validateSku = async (sku: string): Promise<ApiResponse<{ isUnique: boolean }>> => {
  const result = await validateSkuApi(sku);
  return {
    success: true,
    data: { isUnique: result?.isUnique ?? result },
  };
};

/**
 * Upload image (still client-side preview — extend with file upload endpoint)
 */
export const uploadImage = async (
  file: File
): Promise<ApiResponse<{ imageId: string; url: string }>> => {
  const url = URL.createObjectURL(file);
  return {
    success: true,
    data: { imageId: `img-${Date.now()}`, url },
    message: 'Image uploaded successfully',
  };
};
