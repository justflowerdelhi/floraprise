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
  // --- Multi-unit validation logic ---
  let isMultiUnit = formData.isMultiUnit ?? false;
  let avgUnitsPerStem = formData.avgUnitsPerStem;
  let consumptionUnit = formData.consumptionUnit ?? 'STEM';
  if (!isMultiUnit) {
    avgUnitsPerStem = 1;
    consumptionUnit = 'STEM';
  } else {
    if (!avgUnitsPerStem || avgUnitsPerStem <= 1) {
      avgUnitsPerStem = 2; // Enforce >1 for multi-unit
    }
    if (!['STEM', 'BUD', 'BLOOM'].includes(consumptionUnit)) {
      consumptionUnit = 'STEM';
    }
  }

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

    // Multi-unit flower configuration (backward compatible)
    isMultiUnit,
    baseUnit: formData.baseUnit ?? 'STEM',
    consumptionUnit,
    avgUnitsPerStem,
    allowPartialConsumption: formData.allowPartialConsumption ?? false,
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
  try {
    const result = await createProductApi(payload as any);
    // If backend returns error in result, handle it
    if (result && result.error) {
      return {
        success: false,
        error: result.error,
        data: undefined,
        message: result.error,
      };
    }
    return {
      success: true,
      data: result,
      message: 'Product created successfully',
    };
  } catch (error) {
    let errorMsg = 'An unexpected error occurred';
    if (error && typeof error === 'object' && 'message' in error) {
      errorMsg = (error as any).message;
    }
    return {
      success: false,
      error: errorMsg,
      data: undefined,
      message: errorMsg,
    };
  }
};

/**
 * Save as draft — creates product with IsActive = false (draft state)
 */
export const saveDraft = async (
  formData: Partial<ProductFormData>
): Promise<ApiResponse<{ draftId: string }>> => {
  try {
    const payload = transformToApiPayload(formData as ProductFormData);
    const result = await createProductApi({ ...payload, isActive: false } as any);
    return {
      success: true,
      data: { draftId: result?.id ?? `draft-${Date.now()}` },
      message: 'Draft saved successfully',
    };
  } catch (err: any) {
    return {
      success: false,
      data: { draftId: '' },
      message: err?.message ?? 'Failed to save draft',
    };
  }
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
