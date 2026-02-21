/**
 * category.api.ts — Product Categories API Service
 *
 * Endpoints:
 *   GET    /categories
 *   GET    /categories/:id
 *   POST   /categories
 *   PUT    /categories/:id
 *   DELETE /categories/:id       (soft-delete / deactivate)
 *   PUT    /categories/:id/activate
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface ProductCategoryDto {
  id: string;
  name: string;
  isPerishable: boolean;
  trackBatchByDefault: boolean;
  isActive: boolean;
  productCount: number;
  createdAtUtc: string;
  updatedAtUtc: string | null;
}

export interface CreateProductCategoryRequest {
  name: string;
  isPerishable: boolean;
  trackBatchByDefault: boolean;
}

export interface UpdateProductCategoryRequest {
  name: string;
  isPerishable: boolean;
  trackBatchByDefault: boolean;
}

// ─── API Functions ──────────────────────────────────────────

/** Fetch all categories (optionally include inactive) */
export const getCategories = async (includeInactive = false): Promise<ProductCategoryDto[]> => {
  const res = await api.get('/categories', { params: { includeInactive } });
  return res.data;
};

/** Fetch single category by ID */
export const getCategoryById = async (id: string): Promise<ProductCategoryDto> => {
  const res = await api.get(`/categories/${id}`);
  return res.data;
};

/** Create a new category */
export const createCategory = async (data: CreateProductCategoryRequest): Promise<{ id: string }> => {
  const res = await api.post('/categories', data);
  return res.data;
};

/** Update an existing category */
export const updateCategory = async (id: string, data: UpdateProductCategoryRequest): Promise<void> => {
  await api.put(`/categories/${id}`, data);
};

/** Soft-delete (deactivate) a category */
export const deactivateCategory = async (id: string): Promise<void> => {
  await api.delete(`/categories/${id}`);
};

/** Re-activate a previously deactivated category */
export const activateCategory = async (id: string): Promise<void> => {
  await api.put(`/categories/${id}/activate`);
};
