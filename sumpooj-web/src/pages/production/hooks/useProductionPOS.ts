/**
 * useProductionPOS.ts — POS Integration Hooks for Floral Production
 *
 * Provides:
 * - Sellable finished goods for POS display
 * - Barcode scan lookup
 * - On-demand assembly from recipe
 * - Deduction from FinishedGoodsBatch (NOT raw inventory)
 *
 * Safety:
 * - Expired batches auto-hidden from POS
 * - Zero-quantity batches hidden from POS
 * - On-demand mode deducts raw components via FIFO
 * - Pre-produced mode deducts from finished batch only
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import type {
  POSFinishedGoodItem,
  FloralRecipe,
  FinishedGoodsBatch,
} from '../types/ProductionTypes';
import {
  getFinishedBatches,
  getRecipes,
  createOnDemandAssembly,
} from '../api/production.api';
import { isBatchSellable, isExpired } from '../utils/production.utils';
import api from '../../../api/axios';

// ─── Hook: POS Finished Goods ───────────────────────────────

export interface UseFinishedGoodsPOSResult {
  /** Sellable finished goods (active, in-stock, not expired) */
  items: POSFinishedGoodItem[];
  /** Loading state */
  loading: boolean;
  /** Refresh the list */
  refresh: () => Promise<void>;
  /** Look up item by barcode scan */
  findByBarcode: (barcode: string) => POSFinishedGoodItem | undefined;
  /** Deduct quantity from a finished batch (after sale) */
  deductFromBatch: (batchId: string, quantity: number) => Promise<boolean>;
}

export function useFinishedGoodsPOS(locationId?: string): UseFinishedGoodsPOSResult {
  const [batches, setBatches] = useState<FinishedGoodsBatch[]>([]);
  const [recipes, setRecipes] = useState<FloralRecipe[]>([]);
  const [loading, setLoading] = useState(true);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [batchData, recipeData] = await Promise.all([
        getFinishedBatches(),
        getRecipes(),
      ]);
      setBatches(batchData);
      setRecipes(recipeData);
    } catch {
      // handle error silently in POS
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadData(); }, [loadData]);

  // Build sellable items from active, non-expired batches with stock
  const items: POSFinishedGoodItem[] = useMemo(() => {
    return batches
      .filter((b) => isBatchSellable(b))
      .filter((b) => !locationId || b.locationId === locationId)
      .map((b) => {
        const recipe = recipes.find((r) => r.id === b.recipeId);
        return {
          productId: b.productId ?? b.id,
          name: b.recipeName,
          batchId: b.id,
          batchCode: b.batchCode,
          barcode: b.barcode,
          sellingPrice: recipe?.sellingPrice ?? 0,
          quantityAvailable: b.quantityAvailable,
          expectedExpiry: b.expectedExpiry,
          isExpired: isExpired(b.expectedExpiry),
          recipeId: b.recipeId,
        };
      })
      .filter((item) => !item.isExpired); // double-check filter
  }, [batches, recipes, locationId]);

  const findByBarcode = useCallback(
    (barcode: string): POSFinishedGoodItem | undefined => {
      return items.find((item) => item.barcode === barcode);
    },
    [items],
  );

  const deductFromBatch = useCallback(
    async (batchId: string, quantity: number): Promise<boolean> => {
      try {
        await api.post(`/production/finished-goods/${batchId}/deduct`, { quantity });
        // Optimistic local update
        setBatches((prev) =>
          prev.map((b) => {
            if (b.id !== batchId) return b;
            const newQty = Math.max(0, b.quantityAvailable - quantity);
            return { ...b, quantityAvailable: newQty };
          }),
        );
        return true;
      } catch (err) {
        console.error('Failed to deduct from batch:', err);
        return false;
      }
    },
    [],
  );

  return { items, loading, refresh: loadData, findByBarcode, deductFromBatch };
}

// ─── Hook: On-Demand Assembly at POS ────────────────────────

export interface UseOnDemandAssemblyResult {
  /** Available active recipes for on-demand */
  recipes: FloralRecipe[];
  /** Loading state */
  loading: boolean;
  /** Assemble on-demand: deducts raw components, no finished stock created */
  assembleOnDemand: (recipeId: string, quantity: number, locationId: string) => Promise<boolean>;
}

export function useOnDemandAssembly(): UseOnDemandAssemblyResult {
  const [recipes, setRecipes] = useState<FloralRecipe[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const data = await getRecipes();
        setRecipes(data.filter((r) => r.isActive));
      } catch {
        // handle error
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const assembleOnDemand = useCallback(
    async (recipeId: string, quantity: number, locationId: string): Promise<boolean> => {
      try {
        const result = await createOnDemandAssembly({ recipeId, quantity, locationId });
        return result.success;
      } catch {
        return false;
      }
    },
    [],
  );

  return { recipes, loading, assembleOnDemand };
}

// ─── Hook: Combined POS Production Integration ─────────────

export interface UsePOSProductionResult {
  /** Finished goods available for POS */
  finishedGoods: UseFinishedGoodsPOSResult;
  /** On-demand assembly capability */
  onDemand: UseOnDemandAssemblyResult;
}

export function usePOSProduction(locationId?: string): UsePOSProductionResult {
  const finishedGoods = useFinishedGoodsPOS(locationId);
  const onDemand = useOnDemandAssembly();

  return { finishedGoods, onDemand };
}
