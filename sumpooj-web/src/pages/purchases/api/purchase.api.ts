/**
 * Purchase Entry Form — Mock API & Data
 */

import type { Supplier, Product, PurchaseFormData } from '../types/purchase.types';

// ============================================
// MOCK SUPPLIERS
// ============================================

export const mockSuppliers: Supplier[] = [
  {
    id: 'sup_001',
    name: 'Holland Flower Export BV',
    contactPerson: 'Jan de Vries',
    email: 'jan@hollandflowers.nl',
    phone: '+31-20-555-0101',
    address: 'Aalsmeer, Netherlands',
    defaultPaymentTerms: 'net_30',
    leadTimeDays: 3,
  },
  {
    id: 'sup_002',
    name: 'Fresh Petals Co.',
    contactPerson: 'Sarah Kim',
    email: 'sarah@freshpetals.com',
    phone: '+1-555-0202',
    address: 'Miami, FL, USA',
    defaultPaymentTerms: 'net_15',
    leadTimeDays: 1,
  },
  {
    id: 'sup_003',
    name: 'Roseland Farms',
    contactPerson: 'Emily Clark',
    email: 'emily@roseland.com',
    phone: '+1-555-0303',
    address: 'Watsonville, CA, USA',
    defaultPaymentTerms: 'net_7',
    leadTimeDays: 2,
  },
  {
    id: 'sup_004',
    name: 'Tropical Greens Ltd.',
    contactPerson: 'Marco Silva',
    email: 'marco@tropicalgreens.com',
    phone: '+57-1-555-0404',
    address: 'Bogotá, Colombia',
    defaultPaymentTerms: 'net_45',
    leadTimeDays: 5,
  },
  {
    id: 'sup_005',
    name: 'Garden Supplies Wholesale',
    contactPerson: 'Linda Tran',
    email: 'linda@gardensupplies.com',
    phone: '+1-555-0505',
    address: 'Portland, OR, USA',
    defaultPaymentTerms: 'net_30',
    leadTimeDays: 2,
  },
];

// ============================================
// MOCK PRODUCTS
// ============================================

export const mockProducts: Product[] = [
  {
    id: 'prod_001',
    name: 'Red Roses',
    sku: 'FL-ROSE-RED',
    isPerishable: true,
    defaultShelfLifeDays: 7,
    defaultUnit: 'stem',
    lastCost: 1.5,
    sellingPrice: 4.0,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_002',
    name: 'White Lilies',
    sku: 'FL-LILY-WHT',
    isPerishable: true,
    defaultShelfLifeDays: 10,
    defaultUnit: 'stem',
    lastCost: 2.0,
    sellingPrice: 5.5,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_003',
    name: 'Sunflowers',
    sku: 'FL-SUN-YLW',
    isPerishable: true,
    defaultShelfLifeDays: 8,
    defaultUnit: 'stem',
    lastCost: 1.75,
    sellingPrice: 4.5,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_004',
    name: 'Baby\'s Breath (Gypsophila)',
    sku: 'FL-GYPS-WHT',
    isPerishable: true,
    defaultShelfLifeDays: 14,
    defaultUnit: 'bunch',
    lastCost: 3.0,
    sellingPrice: 8.0,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_005',
    name: 'Eucalyptus Bunches',
    sku: 'GR-EUCA-GRN',
    isPerishable: true,
    defaultShelfLifeDays: 21,
    defaultUnit: 'bunch',
    lastCost: 4.0,
    sellingPrice: 10.0,
    category: 'Greenery',
  },
  {
    id: 'prod_006',
    name: 'Glass Vase — Large',
    sku: 'ACC-VASE-LG',
    isPerishable: false,
    defaultUnit: 'piece',
    lastCost: 8.0,
    sellingPrice: 18.0,
    category: 'Accessories',
  },
  {
    id: 'prod_007',
    name: 'Floral Foam Brick',
    sku: 'SUP-FOAM-01',
    isPerishable: false,
    defaultUnit: 'piece',
    lastCost: 1.2,
    sellingPrice: 3.0,
    category: 'Supplies',
  },
  {
    id: 'prod_008',
    name: 'Orchid Phalaenopsis',
    sku: 'FL-ORCH-MIX',
    isPerishable: true,
    defaultShelfLifeDays: 28,
    defaultUnit: 'piece',
    lastCost: 12.0,
    sellingPrice: 28.0,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_009',
    name: 'Tulips — Mixed',
    sku: 'FL-TULP-MIX',
    isPerishable: true,
    defaultShelfLifeDays: 5,
    defaultUnit: 'bunch',
    lastCost: 5.0,
    sellingPrice: 12.0,
    category: 'Fresh Flowers',
  },
  {
    id: 'prod_010',
    name: 'Ribbon Spool — Satin White',
    sku: 'SUP-RIBN-WH',
    isPerishable: false,
    defaultUnit: 'piece',
    lastCost: 3.5,
    sellingPrice: 7.0,
    category: 'Supplies',
  },
];

// ============================================
// MOCK API CALLS
// ============================================

export const fetchSuppliers = (): Promise<Supplier[]> => {
  return new Promise((resolve) => {
    setTimeout(() => resolve([...mockSuppliers]), 400);
  });
};

export const fetchProducts = (search?: string): Promise<Product[]> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      if (search) {
        const q = search.toLowerCase();
        resolve(
          mockProducts.filter(
            (p) =>
              p.name.toLowerCase().includes(q) ||
              p.sku.toLowerCase().includes(q)
          )
        );
      } else {
        resolve([...mockProducts]);
      }
    }, 300);
  });
};

export const submitPurchaseOrder = (
  data: PurchaseFormData
): Promise<{ success: boolean; purchaseOrderId: string }> => {
  return new Promise((resolve) => {
    console.log('📦 Purchase Order Submitted:', JSON.stringify(data, null, 2));
    setTimeout(() => {
      resolve({
        success: true,
        purchaseOrderId: `PO-${Date.now().toString().slice(-8)}`,
      });
    }, 1200);
  });
};

export const savePurchaseDraft = (
  data: PurchaseFormData
): Promise<{ success: boolean }> => {
  return new Promise((resolve) => {
    console.log('💾 Draft Saved:', JSON.stringify(data, null, 2));
    localStorage.setItem('purchase_draft', JSON.stringify(data));
    setTimeout(() => resolve({ success: true }), 500);
  });
};

export const addSupplier = (
  supplier: Omit<Supplier, 'id'>
): Promise<Supplier> => {
  return new Promise((resolve) => {
    const newSupplier: Supplier = {
      ...supplier,
      id: `sup_${Date.now().toString().slice(-6)}`,
    };
    console.log('🏢 Supplier Added:', newSupplier);
    setTimeout(() => resolve(newSupplier), 500);
  });
};
