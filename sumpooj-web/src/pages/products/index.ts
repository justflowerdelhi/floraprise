/**
 * Products Module Index
 * Export all product-related components and utilities
 */

// Main components
export { default as AddProductForm } from './AddProductForm';

// Section components
export * from './components/sections';

// Form components
export * from './components/FormFields';
export { default as SectionCard } from './components/SectionCard';
export { default as QuickAddSupplierModal } from './components/QuickAddSupplierModal';

// Types
export * from './types/product.types';

// Schemas
export * from './schemas/product.schema';

// API
export * from './api/product.api';

// Utilities
export { generateSku, calculateExpiryDate, formatDate, formatCurrency, isPerishableType, isLowShelfLife, getProductTypeLabel } from './utils/product.utils';
