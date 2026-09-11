/**
 * retailPos.api.ts — Retail POS API Service & Re-exports
 *
 * Consolidates backend API integrations for Retail POS:
 * - Product search and sellable finished goods
 * - Customer search and creation
 * - Authoritative order creation (POST /api/Orders)
 * - Thermal receipt printing integration
 */

import { searchProducts, normalizeProducts } from '../../../api/product.api';
import { searchCustomers, createCustomer } from '../../../api/customer.api';
import { createOrder, fetchSellableFinishedGoods, type CreateOrderRequest, type OrderDto } from '../../../api/order.api';
import {
  openReceiptWindow,
  printInWindow,
  printPosReceipt,
  getPosReceiptPrintMode,
  type PrintPosReceiptInput,
  type PosReceiptItem,
  type PosReceiptPayment,
} from '../utils/posReceiptPrint';

export interface RetailPOSProduct {
  id: string;
  name: string;
  sku: string;
  price: number;
  barcode?: string;
  categoryName?: string;
  stockQuantity: number;
  trackInventory: boolean;
  trackBatch: boolean;
  minimumStockLevel?: number;
  isPerishable?: boolean;
}

export interface RetailPOSCartItem {
  product: RetailPOSProduct;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
}

export interface RetailPOSCustomer {
  id: string;
  name: string;
  phone?: string;
  email?: string;
}

/**
 * Loads all active products and finished goods ready for retail sale
 */
export async function fetchRetailPOSCatalog(locationId?: string): Promise<RetailPOSProduct[]> {
  try {
    const [prodRes, finishedGoodsRes] = await Promise.all([
      searchProducts({ IsActive: true, PageSize: 500 }).catch(() => []),
      fetchSellableFinishedGoods().catch(() => []),
    ]);

    const rawItems: any[] = Array.isArray(prodRes) ? prodRes : (prodRes as any)?.items ?? [];
    const normalized = normalizeProducts(rawItems);

    const products: RetailPOSProduct[] = normalized.map((p: any) => ({
      id: String(p.id ?? ''),
      name: p.name || 'Unnamed Item',
      sku: p.sku || '',
      price: Number(p.retailPrice ?? p.price ?? 0),
      barcode: p.barcode || undefined,
      categoryName: p.categoryName || p.category || 'General',
      stockQuantity: Number(p.stockQuantity ?? p.stockOnHand ?? 0),
      trackInventory: p.trackInventory !== false,
      trackBatch: Boolean(p.trackBatch),
      minimumStockLevel: Number(p.minimumStockLevel ?? 0),
      isPerishable: Boolean(p.isPerishable),
    }));

    // Merge sellable finished goods (ready bouquets)
    const finishedGoodsItems: any[] = Array.isArray(finishedGoodsRes) ? finishedGoodsRes : [];
    const fgProducts: RetailPOSProduct[] = finishedGoodsItems
      .filter((fg: any) => !locationId || fg.locationId === locationId)
      .map((fg: any) => ({
        id: String(fg.id ?? fg.Id ?? ''),
        name: fg.name || fg.recipeName || 'Ready Bouquet',
        sku: fg.sku || fg.batchCode || fg.id,
        price: Number(fg.retailPrice ?? fg.price ?? 0),
        barcode: fg.barcode || fg.Barcode || undefined,
        categoryName: 'Ready Arrangements',
        stockQuantity: Number(fg.quantityAvailable ?? fg.quantity ?? 1),
        trackInventory: true,
        trackBatch: true,
        minimumStockLevel: 0,
        isPerishable: true,
      }))
      .filter((p) => Boolean(p.id));

    // Combine and deduplicate by ID
    const productMap = new Map<string, RetailPOSProduct>();
    for (const prod of products) {
      if (prod.id) productMap.set(prod.id, prod);
    }
    for (const fg of fgProducts) {
      if (fg.id && !productMap.has(fg.id)) {
        productMap.set(fg.id, fg);
      }
    }

    return Array.from(productMap.values());
  } catch (err) {
    console.error('[retailPos.api] Failed to load retail catalog:', err);
    return [];
  }
}

/**
 * Searches customers for POS
 */
export async function searchPOSCustomers(query: string): Promise<RetailPOSCustomer[]> {
  try {
    const res = await searchCustomers({ Query: query, PageSize: 20 });
    const items = Array.isArray(res) ? res : res?.items ?? [];
    return items.map((c: any) => ({
      id: c.id,
      name: c.name || 'Customer',
      phone: c.phone || '',
      email: c.email || '',
    }));
  } catch (err) {
    console.error('[retailPos.api] Failed to search customers:', err);
    return [];
  }
}

/**
 * Creates a walk-in customer quickly from POS
 */
export async function quickCreateCustomer(name: string, phone?: string): Promise<RetailPOSCustomer> {
  const res = await createCustomer({ name, phone: phone || null });
  return {
    id: res.id,
    name: res.name || name,
    phone: res.phone || phone || '',
    email: res.email || '',
  };
}

/**
 * Submits authoritative order to the backend
 */
export async function submitRetailPOSOrder(payload: CreateOrderRequest, idempotencyKey?: string): Promise<OrderDto> {
  return await createOrder(payload, idempotencyKey);
}

// Re-export receipt utilities for unified usage
export {
  openReceiptWindow,
  printInWindow,
  printPosReceipt,
  getPosReceiptPrintMode,
};
export type {
  PrintPosReceiptInput,
  PosReceiptItem,
  PosReceiptPayment,
  CreateOrderRequest,
  OrderDto,
};
