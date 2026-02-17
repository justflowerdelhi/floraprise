/**
 * Product API Mock Functions
 * These will be replaced with actual API calls when backend is ready
 */

import type { ProductFormData, ProductApiPayload, Supplier } from '../types/product.types';

// ============================================
// MOCK DATA
// ============================================

export const mockSuppliers: Supplier[] = [
  { id: 'sup-001', name: 'Ecuador Rose Farms', code: 'ERF', leadTime: 5 },
  { id: 'sup-002', name: 'Holland Bulb Co.', code: 'HBC', leadTime: 7 },
  { id: 'sup-003', name: 'California Flowers', code: 'CAF', leadTime: 2 },
  { id: 'sup-004', name: 'Colombian Blooms', code: 'COB', leadTime: 4 },
  { id: 'sup-005', name: 'Kenya Export Ltd', code: 'KEL', leadTime: 6 },
];

// ============================================
// TRANSFORM FORM DATA TO API PAYLOAD
// ============================================

export const transformToApiPayload = (formData: ProductFormData): ProductApiPayload => {
  const payload: ProductApiPayload = {
    // Core identification
    productName: formData.productName,
    sku: formData.sku,
    barcode: formData.barcode || undefined,
    
    // Classification
    productType: formData.productType,
    brand: formData.brand || undefined,
    description: formData.description || undefined,
    tags: formData.tags?.length ? formData.tags : undefined,
    
    // Units & Pricing
    unitOfMeasure: formData.unitOfMeasure,
    retailPrice: formData.retailPrice,
    costPrice: formData.costPrice,
    wholesalePrice: formData.wholesalePrice,
    weddingEventPrice: formData.weddingEventPrice,
    
    // Taxation
    taxCategory: formData.taxCategory,
    
    // Inventory
    trackInventory: formData.trackInventory,
    openingStock: formData.trackInventory ? formData.openingStock : undefined,
    reorderLevel: formData.trackInventory ? formData.reorderLevel : undefined,
    
    // Perishable
    isPerishable: formData.isPerishable,
    shelfLifeDays: formData.isPerishable ? formData.shelfLifeDays : undefined,
    expiryAlertDays: formData.isPerishable ? formData.expiryAlertDays : undefined,
    temperatureNotes: formData.temperatureNotes || undefined,
    
    // Accounting
    accounting: {
      incomeAccount: formData.incomeAccount,
      expenseAccount: formData.expenseAccount,
    },
    
    // Settings
    settings: {
      status: formData.status,
      allowAsRawMaterial: formData.allowAsRawMaterial,
      availableOnline: formData.availableOnline,
      commissionEligible: formData.commissionEligible,
    },
  };

  // Add flower-specific attributes if any exist
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

  // Add supplier info if exists
  if (formData.supplierId || formData.leadTimeDays) {
    payload.supplier = {
      supplierId: formData.supplierId || undefined,
      leadTimeDays: formData.leadTimeDays,
    };
  }

  return payload;
};

// ============================================
// MOCK API FUNCTIONS
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
 * Mock create product API call
 * Simulates network delay and returns mock response
 */
export const createProduct = async (
  formData: ProductFormData
): Promise<ApiResponse<CreatedProduct>> => {
  // Transform to API payload
  const payload = transformToApiPayload(formData);
  
  // Simulate network delay
  await new Promise((resolve) => setTimeout(resolve, 1500));

  // Log payload for development debugging
  console.log('📦 Product API Payload:', JSON.stringify(payload, null, 2));

  // Mock success response
  return {
    success: true,
    data: {
      id: `prod-${Date.now()}`,
      sku: payload.sku,
      productName: payload.productName,
      createdAt: new Date().toISOString(),
    },
    message: 'Product created successfully',
  };
};

/**
 * Mock save as draft API call
 */
export const saveDraft = async (
  formData: Partial<ProductFormData>
): Promise<ApiResponse<{ draftId: string }>> => {
  await new Promise((resolve) => setTimeout(resolve, 800));

  console.log('📝 Draft saved:', formData);

  return {
    success: true,
    data: {
      draftId: `draft-${Date.now()}`,
    },
    message: 'Draft saved successfully',
  };
};

/**
 * Mock fetch suppliers API call
 */
export const fetchSuppliers = async (): Promise<ApiResponse<Supplier[]>> => {
  await new Promise((resolve) => setTimeout(resolve, 500));

  return {
    success: true,
    data: mockSuppliers,
  };
};

/**
 * Mock create supplier API call
 */
export const createSupplier = async (
  supplier: Omit<Supplier, 'id'>
): Promise<ApiResponse<Supplier>> => {
  await new Promise((resolve) => setTimeout(resolve, 800));

  const newSupplier: Supplier = {
    ...supplier,
    id: `sup-${Date.now()}`,
  };

  console.log('🏢 New supplier created:', newSupplier);

  return {
    success: true,
    data: newSupplier,
    message: 'Supplier created successfully',
  };
};

/**
 * Mock validate SKU uniqueness
 */
export const validateSku = async (sku: string): Promise<ApiResponse<{ isUnique: boolean }>> => {
  await new Promise((resolve) => setTimeout(resolve, 300));

  // Mock: SKU is unique unless it starts with 'TEST'
  const isUnique = !sku.toUpperCase().startsWith('TEST');

  return {
    success: true,
    data: { isUnique },
  };
};

/**
 * Mock upload image
 */
export const uploadImage = async (
  file: File
): Promise<ApiResponse<{ imageId: string; url: string }>> => {
  await new Promise((resolve) => setTimeout(resolve, 1000));

  // Create a local URL for preview (in real app, this would be a CDN URL)
  const url = URL.createObjectURL(file);

  return {
    success: true,
    data: {
      imageId: `img-${Date.now()}`,
      url,
    },
    message: 'Image uploaded successfully',
  };
};

// ============================================
// EXAMPLE JSON PAYLOAD
// ============================================

export const examplePayload: ProductApiPayload = {
  productName: 'Red Freedom Rose',
  sku: 'ROSE-RED-001',
  barcode: '123456789012',
  productType: 'fresh_flower',
  brand: 'Ecuador Premium',
  description: 'Beautiful long-stem red roses, perfect for arrangements',
  tags: ['roses', 'red', 'wedding', 'romantic'],
  unitOfMeasure: 'stem',
  retailPrice: 5.99,
  costPrice: 2.50,
  wholesalePrice: 3.99,
  weddingEventPrice: 4.50,
  taxCategory: 'standard',
  trackInventory: true,
  openingStock: 100,
  reorderLevel: 25,
  isPerishable: true,
  shelfLifeDays: 7,
  expiryAlertDays: 2,
  temperatureNotes: 'Keep refrigerated at 34-38°F',
  flowerAttributes: {
    color: 'Red',
    variety: 'Freedom',
    grade: 'premium',
    countryOfOrigin: 'ECU',
    seasonality: ['year_round', 'valentines'],
  },
  supplier: {
    supplierId: 'sup-001',
    leadTimeDays: 5,
  },
  accounting: {
    incomeAccount: '4010',
    expenseAccount: '5010',
  },
  settings: {
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: true,
  },
};
