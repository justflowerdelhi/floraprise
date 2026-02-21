/**
 * POS Module Exports
 * FloraEdge Walk-In POS System
 */

// Full-Screen POS (Single Cart Architecture)
export { default as POSFullScreenLayout } from './POSFullScreenLayout';
export { default as POSScreen } from './POSScreen';
export { POSProvider, usePOS, usePOSNavigationBlocker } from './POSContext';
export type { POSState, POSSession, CartLifecycle } from './POSContext';

// V2 Components (using POSContext)
export { default as POSCartPanelV2 } from './POSCartPanelV2';
export { default as POSPaymentDrawerV2 } from './POSPaymentDrawerV2';

// Legacy Layout (using CartContext)
export { default as POSLayout } from './POSLayout';

// Shared Components
export { default as POSTopBar } from './POSTopBar';
export { default as CategorySidebar } from './CategorySidebar';
export { default as ProductGrid } from './ProductGrid';
export { default as ProductCard } from './ProductCard';
export { default as POSCartPanel } from './POSCartPanel';
export { default as POSPaymentDrawer } from './POSPaymentDrawer';
export { default as POSCustomerDrawer } from './POSCustomerDrawer';

// Types
export * from './POSTypes';
