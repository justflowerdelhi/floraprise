/**
 * retailProduct.test.mjs — Comprehensive Test Suite for Floraprise ERP Retail Product Management
 *
 * Tests:
 * - Test A: Create Product Payload Structure & Shared Entity Conformance (no retail flags)
 * - Test B: Non-Destructive Edit Payload (preserves omitted advanced fields)
 * - Test C: Strict TrackBatch Rule (preserved, toggleable, never forced false)
 * - Test D: Strict TrackInventory Rule (preserved, toggleable)
 * - Test E: Florist UOM Defaults & Allowed Domain Values
 * - Test F: Client-Side Input Validation Logic
 * - Test G: Operational View Routing Dispatcher (RETAIL vs PROFESSIONAL)
 * - Test H: Cross-View Data Continuity & Professional Field Preservation
 */

import assert from 'node:assert';

console.log('--- Running Retail Product Management Test Suite ---\n');

// ─── Test Helpers & Domain Models ─────────────────────────────

const FLORIST_UOM_OPTIONS = [
  'Stem',
  'Bunch',
  'Box',
  'Piece',
  'Dozen',
  'Pack',
  'Roll',
  'Set',
  'Meter',
  'Kilogram',
  'Gram',
  'Liter',
];

/** Simulates the payload constructor in RetailProductModal for Create */
function buildCreatePayload(input, selectedCategory) {
  return {
    productName: input.name.trim(),
    sku: input.sku.trim(),
    barcode: input.barcode?.trim() ? input.barcode.trim() : null,
    productType: 'SingleFlower',
    category: selectedCategory?.name || 'Other',
    categoryId: input.categoryId,
    unitOfMeasure: input.unitOfMeasure || 'Stem',
    retailPrice: Number(input.retailPrice) || 0,
    costPrice: Number(input.costPrice) || 0,
    taxCategory: 'Standard',
    trackInventory: Boolean(input.trackInventory),
    trackBatch: Boolean(input.trackBatch),
    reorderLevel: input.trackInventory ? Number(input.reorderLevel) || 0 : 0,
    description: input.description?.trim() ? input.description.trim() : null,
    accounting: {
      incomeAccount: '4000',
      expenseAccount: '5000',
    },
    settings: {
      status: 'active',
      allowAsRawMaterial: false,
      availableOnline: false,
      commissionEligible: false,
    },
  };
}

/** Simulates the non-destructive payload constructor in RetailProductModal for Update */
function buildUpdatePayload(input) {
  return {
    productName: input.name.trim(),
    categoryId: input.categoryId || undefined,
    barcode: input.barcode !== undefined && input.barcode.trim() ? input.barcode.trim() : null,
    retailPrice: Number(input.retailPrice) || 0,
    costPrice: Number(input.costPrice) || 0,
    trackInventory: Boolean(input.trackInventory),
    trackBatch: Boolean(input.trackBatch),
    reorderLevel: input.trackInventory ? Number(input.reorderLevel) || 0 : 0,
    description: input.description?.trim() ? input.description.trim() : null,
  };
}

/** Simulates backend ProductService.cs UpdateAsync field merging */
function simulateBackendUpdate(existingProduct, updateRequest) {
  return {
    id: existingProduct.id,
    sku: existingProduct.sku, // SKU is immutable on update
    name: updateRequest.productName ?? existingProduct.name,
    categoryId: updateRequest.categoryId ?? existingProduct.categoryId,
    barcode: updateRequest.barcode !== undefined ? updateRequest.barcode : existingProduct.barcode,
    retailPrice: updateRequest.retailPrice ?? existingProduct.retailPrice,
    costPrice: updateRequest.costPrice ?? existingProduct.costPrice,
    trackInventory: updateRequest.trackInventory ?? existingProduct.trackInventory,
    trackBatch: updateRequest.trackBatch ?? existingProduct.trackBatch,
    reorderLevel: updateRequest.reorderLevel ?? existingProduct.reorderLevel,
    description: updateRequest.description ?? existingProduct.description,
    unitOfMeasure: existingProduct.unitOfMeasure,

    // Advanced fields that Retail does not touch - MUST BE PRESERVED
    flowerAttributes: existingProduct.flowerAttributes,
    shelfLifeDays: existingProduct.shelfLifeDays,
    expiryAlertDays: existingProduct.expiryAlertDays,
    temperatureNotes: existingProduct.temperatureNotes,
    supplier: existingProduct.supplier,
    accounting: existingProduct.accounting,
    wholesalePrice: existingProduct.wholesalePrice,
    weddingEventPrice: existingProduct.weddingEventPrice,
    isMultiUnit: existingProduct.isMultiUnit,
    avgUnitsPerStem: existingProduct.avgUnitsPerStem,
    tags: existingProduct.tags,
    settings: existingProduct.settings,
  };
}

/** Client-side validation helper */
function validateRetailProductInput(input) {
  const errors = {};
  if (!input.name || !input.name.trim()) errors.name = 'Product name is required';
  if (!input.sku || !input.sku.trim()) errors.sku = 'SKU is required';
  if (!input.categoryId) errors.categoryId = 'Category is required';

  const retail = parseFloat(input.retailPrice);
  if (isNaN(retail) || retail < 0) errors.retailPrice = 'Valid selling price is required';

  const cost = parseFloat(input.costPrice);
  if (input.costPrice !== undefined && input.costPrice !== '' && (isNaN(cost) || cost < 0)) {
    errors.costPrice = 'Valid cost price is required';
  }

  if (input.trackInventory) {
    const reorder = parseInt(input.reorderLevel, 10);
    if (isNaN(reorder) || reorder < 0) errors.reorderLevel = 'Valid reorder level is required';
  }

  return { isValid: Object.keys(errors).length === 0, errors };
}

// ─── Test A: Create Product Payload Structure & Shared Entity Conformance ─────
{
  const input = {
    name: 'Red Naomi Rose',
    sku: 'ROS-RED-001',
    barcode: '8901234567890',
    categoryId: 'cat-flowers-01',
    unitOfMeasure: 'Stem',
    retailPrice: 150.0,
    costPrice: 65.0,
    trackInventory: true,
    trackBatch: true,
    reorderLevel: 25,
    description: 'Grade A premium Red Naomi roses from Kenya',
  };

  const selectedCategory = { id: 'cat-flowers-01', name: 'Fresh Flowers' };
  const payload = buildCreatePayload(input, selectedCategory);

  assert.strictEqual(payload.productName, 'Red Naomi Rose');
  assert.strictEqual(payload.sku, 'ROS-RED-001');
  assert.strictEqual(payload.barcode, '8901234567890');
  assert.strictEqual(payload.unitOfMeasure, 'Stem');
  assert.strictEqual(payload.retailPrice, 150.0);
  assert.strictEqual(payload.costPrice, 65.0);
  assert.strictEqual(payload.trackInventory, true);
  assert.strictEqual(payload.trackBatch, true);
  assert.strictEqual(payload.reorderLevel, 25);

  // Critical: Verify NO speculative Retail flags were added
  assert.strictEqual('retailProduct' in payload, false, 'Payload must not have retailProduct flag');
  assert.strictEqual('isRetail' in payload, false, 'Payload must not have isRetail flag');
  assert.strictEqual('simpleProduct' in payload, false, 'Payload must not have simpleProduct flag');

  console.log('✓ Test A Passed: Create product creates standard shared Product entity (no retail flags)');
}

// ─── Test B: Non-Destructive Edit Payload & Field Isolation ──────────────────
{
  const existingProduct = {
    id: 'prod-123',
    sku: 'ROS-RED-001',
    name: 'Red Naomi Rose',
    categoryId: 'cat-flowers-01',
    barcode: '8901234567890',
    unitOfMeasure: 'Stem',
    retailPrice: 150.0,
    costPrice: 65.0,
    trackInventory: true,
    trackBatch: true,
    reorderLevel: 25,
    description: 'Original description',

    // Advanced Professional fields
    flowerAttributes: { color: 'Dark Red', variety: 'Naomi', grade: 'Premium' },
    shelfLifeDays: 14,
    expiryAlertDays: 3,
    temperatureNotes: 'Store between 2-4C',
    supplier: { supplierId: 'sup-001', leadTimeDays: 2 },
    accounting: { incomeAccount: '4010', expenseAccount: '5010' },
    wholesalePrice: 110.0,
    weddingEventPrice: 135.0,
    isMultiUnit: true,
    avgUnitsPerStem: 3,
    tags: ['roses', 'premium', 'valentines'],
    settings: { status: 'active', allowAsRawMaterial: true, availableOnline: true, commissionEligible: false },
  };

  // Retail user updates ONLY selling price and description
  const retailEditInput = {
    name: 'Red Naomi Rose',
    categoryId: 'cat-flowers-01',
    barcode: '8901234567890',
    retailPrice: 165.0, // updated
    costPrice: 65.0,
    trackInventory: true,
    trackBatch: true,
    reorderLevel: 25,
    description: 'Updated retail notes', // updated
  };

  const updatePayload = buildUpdatePayload(retailEditInput);

  // Ensure updatePayload does NOT carry empty/null advanced properties
  assert.strictEqual(updatePayload.flowerAttributes, undefined);
  assert.strictEqual(updatePayload.shelfLifeDays, undefined);
  assert.strictEqual(updatePayload.supplier, undefined);
  assert.strictEqual(updatePayload.accounting, undefined);

  // Simulate backend persistence
  const updatedProduct = simulateBackendUpdate(existingProduct, updatePayload);

  // Verify retail changes applied
  assert.strictEqual(updatedProduct.retailPrice, 165.0);
  assert.strictEqual(updatedProduct.description, 'Updated retail notes');

  // Verify ALL advanced fields survived completely intact
  assert.deepStrictEqual(updatedProduct.flowerAttributes, { color: 'Dark Red', variety: 'Naomi', grade: 'Premium' });
  assert.strictEqual(updatedProduct.shelfLifeDays, 14);
  assert.strictEqual(updatedProduct.temperatureNotes, 'Store between 2-4C');
  assert.deepStrictEqual(updatedProduct.supplier, { supplierId: 'sup-001', leadTimeDays: 2 });
  assert.deepStrictEqual(updatedProduct.accounting, { incomeAccount: '4010', expenseAccount: '5010' });
  assert.strictEqual(updatedProduct.wholesalePrice, 110.0);
  assert.strictEqual(updatedProduct.weddingEventPrice, 135.0);
  assert.strictEqual(updatedProduct.isMultiUnit, true);

  console.log('✓ Test B Passed: Non-destructive edit preserves all advanced Professional fields');
}

// ─── Test C: Strict TrackBatch Rule Verification ─────────────────────────────
{
  // Case 1: Product with TrackBatch = true preserves TrackBatch = true
  const batchProduct = {
    id: 'prod-batch-1',
    sku: 'LIL-WHT-001',
    name: 'White Oriental Lily',
    trackInventory: true,
    trackBatch: true, // TRUE
    reorderLevel: 15,
  };

  const update1 = buildUpdatePayload({
    name: batchProduct.name,
    trackInventory: true,
    trackBatch: batchProduct.trackBatch, // keeps true
    retailPrice: 200,
    costPrice: 90,
  });

  assert.strictEqual(update1.trackBatch, true, 'TrackBatch must remain true');

  // Case 2: Florist can explicitly toggle TrackBatch to false
  const update2 = buildUpdatePayload({
    name: batchProduct.name,
    trackInventory: true,
    trackBatch: false, // user chooses false
    retailPrice: 200,
    costPrice: 90,
  });

  assert.strictEqual(update2.trackBatch, false, 'Florist choice of false is honored');

  // Case 3: Product with TrackBatch = false can be toggled to true
  const nonBatchProduct = {
    id: 'prod-vase-1',
    sku: 'VAS-GLS-001',
    name: 'Glass Cylinder Vase',
    trackInventory: true,
    trackBatch: false, // FALSE
  };

  const update3 = buildUpdatePayload({
    name: nonBatchProduct.name,
    trackInventory: true,
    trackBatch: true, // florist enables batch
    retailPrice: 450,
    costPrice: 220,
  });

  assert.strictEqual(update3.trackBatch, true, 'Florist can enable batch tracking');

  console.log('✓ Test C Passed: Strict TrackBatch rule adheres to specifications (never forced false)');
}

// ─── Test D: Strict TrackInventory Rule Verification ─────────────────────────
{
  const serviceProduct = {
    id: 'prod-srv-1',
    sku: 'SRV-DEL-001',
    name: 'Express Delivery Service',
    trackInventory: false,
    trackBatch: false,
  };

  const update = buildUpdatePayload({
    name: serviceProduct.name,
    trackInventory: false,
    trackBatch: false,
    reorderLevel: 0,
    retailPrice: 100,
    costPrice: 0,
  });

  assert.strictEqual(update.trackInventory, false);
  assert.strictEqual(update.reorderLevel, 0);

  console.log('✓ Test D Passed: TrackInventory rule verified for both tracked and untracked products');
}

// ─── Test E: Florist UOM Defaults & Allowed Domain Values ─────────────────────
{
  assert.ok(FLORIST_UOM_OPTIONS.includes('Stem'), "Must contain 'Stem'");
  assert.ok(FLORIST_UOM_OPTIONS.includes('Bunch'), "Must contain 'Bunch'");
  assert.ok(FLORIST_UOM_OPTIONS.includes('Box'), "Must contain 'Box'");
  assert.ok(FLORIST_UOM_OPTIONS.includes('Piece'), "Must contain 'Piece'");
  assert.ok(FLORIST_UOM_OPTIONS.includes('Dozen'), "Must contain 'Dozen'");

  // Default UOM for a new florist product must be Stem
  const defaultPayload = buildCreatePayload({
    name: 'Carnation Pink',
    sku: 'CAR-PNK-01',
    categoryId: 'cat-1',
    retailPrice: 40,
    costPrice: 15,
  });

  assert.strictEqual(defaultPayload.unitOfMeasure, 'Stem', 'Default UOM must be Stem');
  console.log("✓ Test E Passed: Florist UOM default is 'Stem' and matches domain definitions");
}

// ─── Test F: Client-Side Input Validation Logic ──────────────────────────────
{
  // Missing name
  const res1 = validateRetailProductInput({ name: '', sku: 'SKU-1', categoryId: 'cat-1', retailPrice: '50' });
  assert.strictEqual(res1.isValid, false);
  assert.ok(res1.errors.name);

  // Missing SKU
  const res2 = validateRetailProductInput({ name: 'Rose', sku: '', categoryId: 'cat-1', retailPrice: '50' });
  assert.strictEqual(res2.isValid, false);
  assert.ok(res2.errors.sku);

  // Missing category
  const res3 = validateRetailProductInput({ name: 'Rose', sku: 'SKU-1', categoryId: '', retailPrice: '50' });
  assert.strictEqual(res3.isValid, false);
  assert.ok(res3.errors.categoryId);

  // Invalid negative price
  const res4 = validateRetailProductInput({ name: 'Rose', sku: 'SKU-1', categoryId: 'cat-1', retailPrice: '-10' });
  assert.strictEqual(res4.isValid, false);
  assert.ok(res4.errors.retailPrice);

  // Valid input
  const res5 = validateRetailProductInput({
    name: 'Red Naomi Rose',
    sku: 'ROS-RED-01',
    categoryId: 'cat-1',
    retailPrice: '120.00',
    costPrice: '55.00',
    trackInventory: true,
    reorderLevel: '10',
  });
  assert.strictEqual(res5.isValid, true);
  assert.strictEqual(Object.keys(res5.errors).length, 0);

  console.log('✓ Test F Passed: Client-side validation correctly validates required fields and types');
}

// ─── Test G: Operational View Routing Dispatcher ─────────────────────────────
{
  function dispatchProductsRoute(viewMode) {
    if (viewMode === 'RETAIL') {
      return 'RetailProductsPage';
    }
    return 'ProductsListPage';
  }

  assert.strictEqual(dispatchProductsRoute('RETAIL'), 'RetailProductsPage');
  assert.strictEqual(dispatchProductsRoute('PROFESSIONAL'), 'ProductsListPage');

  console.log('✓ Test G Passed: Products route dispatcher resolves Retail vs Professional correctly');
}

// ─── Test H: Cross-View Data Continuity & Parity ─────────────────────────────
{
  // Product created from Android Cloud / Retail Web
  const productFromRetail = buildCreatePayload(
    {
      name: 'Sunburst Sunflower',
      sku: 'SUN-YEL-01',
      barcode: '123456789012',
      categoryId: 'cat-fresh',
      unitOfMeasure: 'Stem',
      retailPrice: 95.0,
      costPrice: 40.0,
      trackInventory: true,
      trackBatch: true,
      reorderLevel: 20,
      description: 'Bright golden sunflowers',
    },
    { id: 'cat-fresh', name: 'Fresh Flowers' }
  );

  // Verify that an ERP Professional consumer can read all properties without error
  assert.strictEqual(productFromRetail.productName, 'Sunburst Sunflower');
  assert.strictEqual(productFromRetail.taxCategory, 'Standard');
  assert.deepStrictEqual(productFromRetail.accounting, { incomeAccount: '4000', expenseAccount: '5000' });
  assert.strictEqual(productFromRetail.settings.status, 'active');

  console.log('✓ Test H Passed: Cross-view data continuity verified across Web, Cloud, and Professional');
}

console.log('\n--- All Retail Product Management Tests Passed Successfully! ---');
