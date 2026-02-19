/**
 * Production Module — Barrel Exports
 */

// Pages
export { default as FloralRecipeList } from './FloralRecipeList';
export { default as FloralRecipeForm } from './FloralRecipeForm';
export { default as ProductionScreen } from './ProductionScreen';
export { default as FinishedGoodsInventory } from './FinishedGoodsInventory';
export { default as CustomBouquetBuilder } from './CustomBouquetBuilder';
export { default as MaintenanceModal } from './MaintenanceModal';
export { default as WastageLogPage } from './WastageLogPage';

// POS Hooks
export { useFinishedGoodsPOS, useOnDemandAssembly, usePOSProduction } from './hooks/useProductionPOS';

// Types
export type {
  FloralRecipe,
  FinishedGoodsBatch,
  RecipeComponent,
  ProductionRunRequest,
  ProductionRunResult,
  OnDemandAssemblyRequest,
  CustomBouquetRequest,
  MaintenanceRequest,
  ProductionMaintenanceLog,
  WastageLog,
  WastageReason,
  InventoryProduct,
  POSFinishedGoodItem,
} from './types/ProductionTypes';
