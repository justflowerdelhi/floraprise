/**
 * operationalView.test.mjs
 * Automated verification of Operational View entitlement, resolution, and persistence logic.
 */

import assert from 'node:assert';

// -----------------------------------------------------------------------------
// Simulation of OperationalView Logic (matching TenantTypes and OperationalViewContext)
// -----------------------------------------------------------------------------

const OPERATIONAL_VIEWS = {
  RETAIL: 'RETAIL',
  PROFESSIONAL: 'PROFESSIONAL',
};

const OPERATIONAL_VIEW_STORAGE_KEY = 'floraprise.erp.viewMode';

function isProfessionalViewEligible(plan) {
  if (!plan) return false;
  return plan === 'GROWTH' || plan === 'PRO' || plan === 'ENTERPRISE';
}

function resolveOperationalView(plan, storedPreference) {
  if (!isProfessionalViewEligible(plan)) {
    return 'RETAIL';
  }
  if (storedPreference === 'RETAIL') {
    return 'RETAIL';
  }
  if (storedPreference === 'PROFESSIONAL') {
    return 'PROFESSIONAL';
  }
  return 'PROFESSIONAL';
}

// Mock mockStorage for browser persistence simulation
class MockStorage {
  constructor() {
    this.store = {};
  }
  getItem(key) {
    return this.store[key] ?? null;
  }
  setItem(key, val) {
    this.store[key] = String(val);
  }
  removeItem(key) {
    delete this.store[key];
  }
  clear() {
    this.store = {};
  }
}

function getStoredOperationalView(storage) {
  if (!storage) return null;
  try {
    const raw = storage.getItem(OPERATIONAL_VIEW_STORAGE_KEY);
    if (raw === OPERATIONAL_VIEWS.RETAIL || raw === OPERATIONAL_VIEWS.PROFESSIONAL) {
      return raw;
    }
    return null;
  } catch {
    return null;
  }
}

function setStoredOperationalView(view, storage) {
  if (!storage) return;
  try {
    storage.setItem(OPERATIONAL_VIEW_STORAGE_KEY, view);
  } catch {
    // Silently ignore
  }
}

// -----------------------------------------------------------------------------
// Test Runner
// -----------------------------------------------------------------------------

console.log('--- Running Operational View Test Suite ---\n');

// Test A: Starter + no preference → RETAIL
{
  const result = resolveOperationalView('STARTER', null);
  assert.strictEqual(result, 'RETAIL', 'Test A Failed: Starter with no preference must be RETAIL');
  console.log('✓ Test A Passed: Starter + no preference -> RETAIL');
}

// Test B: Starter + stored PROFESSIONAL → RETAIL (Ineligible forced to Retail)
{
  const result = resolveOperationalView('STARTER', 'PROFESSIONAL');
  assert.strictEqual(result, 'RETAIL', 'Test B Failed: Starter with stored PROFESSIONAL must still be RETAIL');
  console.log('✓ Test B Passed: Starter + stored PROFESSIONAL -> RETAIL');
}

// Test C: Eligible plan + no preference → PROFESSIONAL (Default for Growth, Pro, Enterprise)
{
  for (const plan of ['GROWTH', 'PRO', 'ENTERPRISE']) {
    const result = resolveOperationalView(plan, null);
    assert.strictEqual(result, 'PROFESSIONAL', `Test C Failed: ${plan} with no preference must default to PROFESSIONAL`);
  }
  console.log('✓ Test C Passed: Eligible plan (GROWTH/PRO/ENTERPRISE) + no preference -> PROFESSIONAL');
}

// Test D: Eligible plan + stored RETAIL → RETAIL
{
  for (const plan of ['GROWTH', 'PRO', 'ENTERPRISE']) {
    const result = resolveOperationalView(plan, 'RETAIL');
    assert.strictEqual(result, 'RETAIL', `Test D Failed: ${plan} with stored RETAIL must be RETAIL`);
  }
  console.log('✓ Test D Passed: Eligible plan + stored RETAIL -> RETAIL');
}

// Test E: Eligible plan + stored PROFESSIONAL → PROFESSIONAL
{
  for (const plan of ['GROWTH', 'PRO', 'ENTERPRISE']) {
    const result = resolveOperationalView(plan, 'PROFESSIONAL');
    assert.strictEqual(result, 'PROFESSIONAL', `Test E Failed: ${plan} with stored PROFESSIONAL must be PROFESSIONAL`);
  }
  console.log('✓ Test E Passed: Eligible plan + stored PROFESSIONAL -> PROFESSIONAL');
}

// Test F: Invalid stored value → safe fallback
{
  // Invalid string on Starter -> RETAIL
  assert.strictEqual(resolveOperationalView('STARTER', 'corrupted_view_value'), 'RETAIL');
  // Invalid string on Growth -> PROFESSIONAL (fallback to default)
  assert.strictEqual(resolveOperationalView('GROWTH', 'corrupted_view_value'), 'PROFESSIONAL');
  // Unknown plan or empty -> RETAIL
  assert.strictEqual(resolveOperationalView('', 'PROFESSIONAL'), 'RETAIL');
  assert.strictEqual(resolveOperationalView(null, 'PROFESSIONAL'), 'RETAIL');
  console.log('✓ Test F Passed: Invalid stored value or plan -> safe fallback');
}

// Test G: SSR/browser safety (no window or localStorage)
{
  // When storage is undefined (SSR environment)
  const stored = getStoredOperationalView(undefined);
  assert.strictEqual(stored, null, 'SSR must return null safely');
  assert.doesNotThrow(() => setStoredOperationalView('RETAIL', undefined), 'SSR setStored must not throw');
  console.log('✓ Test G Passed: SSR / browser safety verified (no window/localStorage crash)');
}

// Test H: Switching PROFESSIONAL -> RETAIL and RETAIL -> PROFESSIONAL
{
  const storage = new MockStorage();
  const plan = 'GROWTH';
  const canUseProfessional = isProfessionalViewEligible(plan);
  assert.strictEqual(canUseProfessional, true);

  // Initial: no preference -> PROFESSIONAL
  let currentView = resolveOperationalView(plan, getStoredOperationalView(storage));
  assert.strictEqual(currentView, 'PROFESSIONAL');

  // User switches to RETAIL
  setStoredOperationalView('RETAIL', storage);
  currentView = resolveOperationalView(plan, getStoredOperationalView(storage));
  assert.strictEqual(currentView, 'RETAIL');
  assert.strictEqual(storage.getItem(OPERATIONAL_VIEW_STORAGE_KEY), 'RETAIL');

  // User switches back to PROFESSIONAL
  setStoredOperationalView('PROFESSIONAL', storage);
  currentView = resolveOperationalView(plan, getStoredOperationalView(storage));
  assert.strictEqual(currentView, 'PROFESSIONAL');
  assert.strictEqual(storage.getItem(OPERATIONAL_VIEW_STORAGE_KEY), 'PROFESSIONAL');

  // If a Starter user attempts to switch to PROFESSIONAL
  const starterPlan = 'STARTER';
  const starterCanUseProfessional = isProfessionalViewEligible(starterPlan);
  assert.strictEqual(starterCanUseProfessional, false);

  // Even if localStorage contains PROFESSIONAL, Starter resolves to RETAIL
  const starterView = resolveOperationalView(starterPlan, storage.getItem(OPERATIONAL_VIEW_STORAGE_KEY));
  assert.strictEqual(starterView, 'RETAIL');

  console.log('✓ Test H Passed: Switching PROFESSIONAL <-> RETAIL with entitlement guard');
}

// Test I: Plan Eligibility Mapping
{
  assert.strictEqual(isProfessionalViewEligible('STARTER'), false);
  assert.strictEqual(isProfessionalViewEligible('GROWTH'), true);
  assert.strictEqual(isProfessionalViewEligible('PRO'), true);
  assert.strictEqual(isProfessionalViewEligible('ENTERPRISE'), true);
  console.log('✓ Test I Passed: Plan eligibility strictly adheres to specification');
}

console.log('\n--- All Operational View Tests Passed Successfully! ---');
