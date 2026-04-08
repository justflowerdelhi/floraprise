/**
 * Product API Functions
 * Real API calls to the backend
 */

import type { ProductFormData, ProductApiPayload, Supplier, UnitOfMeasure } from '../types/product.types';
import {
  createProduct as createProductApi,
  deleteProduct as deleteProductApi,
  getProductById as getProductByIdApi,
  searchProducts as searchProductsApi,
  updateProduct as updateProductApi,
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

export interface ProductDetailResponse {
  id: string;
  name?: string;
  productName?: string;
  sku?: string;
  barcode?: string | null;
  brand?: string | null;
  productType?: string;
  categoryId?: string | null;
  description?: string | null;
  unitOfMeasure?: string;
  isActive?: boolean;
  retailPrice?: number;
  costPrice?: number;
  wholesalePrice?: number | null;
  weddingEventPrice?: number | null;
  taxCategory?: string;
  trackInventory?: boolean;
  trackBatch?: boolean;
  stockQuantity?: number;
  reorderLevel?: number;
  minimumStockLevel?: number;
  isPerishable?: boolean;
  shelfLifeDays?: number | null;
  expiryAlertDays?: number | null;
  temperatureNotes?: string | null;
  color?: string | null;
  variety?: string | null;
  flowerGrade?: string | null;
  countryOfOrigin?: string | null;
  seasonalAvailability?: string | null;
  defaultSupplierId?: string | null;
  leadTimeDays?: number | null;
  incomeAccount?: string | null;
  expenseAccount?: string | null;
  allowAsRawMaterial?: boolean;
  availableOnline?: boolean;
  commissionEligible?: boolean;
  tags?: string[];
  isMultiUnit?: boolean;
  avgUnitsPerStem?: number;
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
 * Fetch one product by id
 */
export const fetchProductById = async (
  id: string
): Promise<ApiResponse<ProductDetailResponse>> => {
  try {
    const result = await getProductByIdApi(id);
    return {
      success: true,
      data: result,
    };
  } catch (error) {
    let errorMsg = 'Failed to fetch product details';
    if (error && typeof error === 'object' && 'message' in error) {
      errorMsg = (error as any).message;
    }
    return {
      success: false,
      error: errorMsg,
      message: errorMsg,
    };
  }
};

const ALLOWED_UNITS = new Set<UnitOfMeasure>([
  'each',
  'stem',
  'bunch',
  'box',
  'case',
  'dozen',
  'foot',
  'yard',
  'roll',
  'pack',
]);

interface FetchSuggestedUnitParams {
  categoryId?: string;
  categoryName?: string;
  productType?: string;
}

interface SuggestedUnitResponse {
  unitOfMeasure?: UnitOfMeasure;
  sourceCount: number;
}

/**
 * Suggest unit of measure by checking existing products and taking the most frequent match.
 */
export const fetchSuggestedUnitOfMeasure = async (
  params: FetchSuggestedUnitParams,
): Promise<ApiResponse<SuggestedUnitResponse>> => {
  try {
    const result = await searchProductsApi({ PageSize: 500, IsActive: true });
    const items = Array.isArray(result) ? result : (result?.items ?? []);

    if (!Array.isArray(items) || items.length === 0) {
      return {
        success: true,
        data: { sourceCount: 0 },
      };
    }

    const categoryId = params.categoryId?.toLowerCase();
    const categoryName = params.categoryName?.toLowerCase();
    const productType = params.productType?.toLowerCase();

    const scoreAndFilter = (item: any) => {
      const unitRaw = item?.unitOfMeasure;
      if (typeof unitRaw !== 'string') return null;
      const normalizedUnit = unitRaw.toLowerCase() as UnitOfMeasure;
      if (!ALLOWED_UNITS.has(normalizedUnit)) return null;

      let score = 0;
      const itemCategoryId = String(item?.categoryId ?? '').toLowerCase();
      const itemCategory = String(item?.category ?? '').toLowerCase();
      const itemProductType = String(item?.productType ?? '').toLowerCase();

      if (categoryId && itemCategoryId && itemCategoryId === categoryId) {
        score += 2;
      } else if (categoryName && itemCategory && itemCategory === categoryName) {
        score += 2;
      }

      if (productType && itemProductType && itemProductType === productType) {
        score += 1;
      }

      return { unit: normalizedUnit, score };
    };

    const scored = items
      .map(scoreAndFilter)
      .filter((x): x is { unit: UnitOfMeasure; score: number } => Boolean(x));

    const matching = scored.filter((x) => x.score > 0);
    if (matching.length === 0) {
      return {
        success: true,
        data: { sourceCount: 0 },
      };
    }

    const counts = new Map<UnitOfMeasure, { count: number; scoreSum: number }>();
    for (const row of matching) {
      const current = counts.get(row.unit) ?? { count: 0, scoreSum: 0 };
      counts.set(row.unit, {
        count: current.count + 1,
        scoreSum: current.scoreSum + row.score,
      });
    }

    const ranked = Array.from(counts.entries()).sort((a, b) => {
      if (b[1].scoreSum !== a[1].scoreSum) return b[1].scoreSum - a[1].scoreSum;
      if (b[1].count !== a[1].count) return b[1].count - a[1].count;
      return a[0].localeCompare(b[0]);
    });

    return {
      success: true,
      data: {
        unitOfMeasure: ranked[0]?.[0],
        sourceCount: matching.length,
      },
    };
  } catch (error) {
    let errorMsg = 'Failed to auto-suggest unit';
    if (error && typeof error === 'object' && 'message' in error) {
      errorMsg = (error as any).message;
    }
    return {
      success: false,
      error: errorMsg,
      message: errorMsg,
    };
  }
};

/**
 * Update product via real API
 */
export const updateProductById = async (
  id: string,
  formData: ProductFormData
): Promise<ApiResponse<null>> => {
  const payload = transformToApiPayload(formData);
  try {
    await updateProductApi(id, payload as any);
    return {
      success: true,
      data: null,
      message: 'Product updated successfully',
    };
  } catch (error) {
    let errorMsg = 'An unexpected error occurred';
    if (error && typeof error === 'object' && 'message' in error) {
      errorMsg = (error as any).message;
    }
    return {
      success: false,
      error: errorMsg,
      data: null,
      message: errorMsg,
    };
  }
};

/**
 * Hard-delete product via delete endpoint
 */
export const deleteProductById = async (
  id: string,
  forceDeleteReferences = false,
): Promise<ApiResponse<null>> => {
  try {
    await deleteProductApi(id, { forceDeleteReferences });
    return {
      success: true,
      data: null,
      message: 'Product deleted successfully',
    };
  } catch (error) {
    let errorMsg = 'Failed to delete product';
    const apiMessage = (error as any)?.response?.data?.message
      || (error as any)?.response?.data?.error
      || (error as any)?.response?.data?.title;
    if (apiMessage) {
      errorMsg = apiMessage;
    } else if (error && typeof error === 'object' && 'message' in error) {
      errorMsg = (error as any).message;
    }
    return {
      success: false,
      error: errorMsg,
      data: null,
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
