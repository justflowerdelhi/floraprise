/**
 * API Audit Script — Compares frontend API calls against backend controller endpoints.
 *
 * Usage:
 *   node scripts/api-audit.mjs
 *
 * Scans:
 *   - sumpooj-web/src/**\/*.api.ts for api.get/post/put/patch/delete calls
 *   - Sumpooj.API/Controllers/*.cs for [Http*] and [Route] attributes
 *
 * Output:
 *   - ✅ Matched endpoints (frontend → backend)
 *   - ❌ Missing endpoints (frontend calls but no backend handler)
 *   - ⚠️  Mock-only endpoints (wrapped in USE_MOCK_DATA but no real API)
 */

import { readFileSync, readdirSync, statSync } from 'fs';
import { join, relative } from 'path';

const ROOT = process.cwd();
const FE_DIR = join(ROOT, 'sumpooj-web', 'src');
const BE_DIR = join(ROOT, 'Sumpooj.API', 'Controllers');

// ── Collect frontend API calls ──────────────────────────────────────────────

function findFiles(dir, ext) {
  const results = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      results.push(...findFiles(full, ext));
    } else if (full.endsWith(ext)) {
      results.push(full);
    }
  }
  return results;
}

function extractFrontendCalls(filePath) {
  const content = readFileSync(filePath, 'utf-8');
  const calls = [];
  const regex = /api\.(get|post|put|patch|delete)\s*(?:<[^>]*>)?\s*\(\s*[`'"](.*?)[`'"]/gi;
  let match;
  while ((match = regex.exec(content)) !== null) {
    const method = match[1].toUpperCase();
    let path = match[2]
      .replace(/\$\{[^}]+\}/g, '{id}')  // template literals → {id}
      .replace(/\/\{id\}\//, '/{id}/')   // normalize
      .split('?')[0];                    // strip query params

    // Check if this call is inside a mock block
    const lineNum = content.substring(0, match.index).split('\n').length;
    const contextLines = content.split('\n').slice(Math.max(0, lineNum - 10), lineNum);
    const isMockOnly = contextLines.some(l => l.includes('USE_MOCK_DATA') || l.includes('// TODO'));

    calls.push({
      method,
      path: path.startsWith('/') ? path : '/' + path,
      file: relative(ROOT, filePath),
      line: lineNum,
      mockOnly: isMockOnly,
    });
  }
  return calls;
}

// ── Collect backend endpoints ───────────────────────────────────────────────

function extractBackendEndpoints(filePath) {
  const content = readFileSync(filePath, 'utf-8');
  const endpoints = [];

  // Get controller route prefix
  const routeMatch = content.match(/\[Route\("api\/(.+?)"\)\]/);
  const controllerMatch = content.match(/\[Route\("api\/\[controller\]"\)\]/);
  const classMatch = content.match(/public class (\w+)Controller/);

  let prefix = '';
  if (routeMatch && !routeMatch[1].includes('[controller]')) {
    prefix = '/' + routeMatch[1];
  } else if (controllerMatch && classMatch) {
    // [Route("api/[controller]")] → /ControllerName
    prefix = '/' + classMatch[1];
  }

  // Get all [Http*] attributes
  const httpRegex = /\[Http(Get|Post|Put|Patch|Delete)(?:\("(.+?)"\))?\]/gi;
  let match;
  while ((match = httpRegex.exec(content)) !== null) {
    const method = match[1].toUpperCase();
    const sub = match[2] || '';
    const fullPath = prefix + (sub ? '/' + sub : '');
    endpoints.push({
      method,
      path: fullPath.replace(/\{(\w+):guid\}/g, '{id}').replace(/\{(\w+)\}/g, '{id}'),
      file: relative(ROOT, filePath),
    });
  }
  return endpoints;
}

// ── Normalize for comparison ────────────────────────────────────────────────

function normalizePath(p) {
  return p.toLowerCase().replace(/\/+$/, '').replace(/\{[^}]+\}/g, '{id}');
}

// ── Run Audit ───────────────────────────────────────────────────────────────

const feFiles = findFiles(FE_DIR, '.api.ts');
const beFiles = findFiles(BE_DIR, '.cs');

const feCalls = feFiles.flatMap(extractFrontendCalls);
const beEndpoints = beFiles.flatMap(extractBackendEndpoints);

// Deduplicate frontend calls
const feUnique = new Map();
for (const call of feCalls) {
  const key = `${call.method} ${normalizePath(call.path)}`;
  if (!feUnique.has(key)) {
    feUnique.set(key, call);
  }
}

// Build backend lookup
const beLookup = new Set();
const bePatterns = []; // For parametric matching
for (const ep of beEndpoints) {
  const norm = `${ep.method} ${normalizePath(ep.path)}`;
  beLookup.add(norm);
  // Build regex pattern: replace {id} with [^/]+ for fuzzy matching
  const parts = norm.split(' ');
  const regex = new RegExp('^' + parts[0] + ' ' + parts[1].replace(/\{id\}/g, '[^/]+') + '$');
  bePatterns.push(regex);
}

// ── Report ──────────────────────────────────────────────────────────────────

const matched = [];
const missing = [];
const mockOnly = [];

for (const [key, call] of feUnique) {
  if (beLookup.has(key) || bePatterns.some(rx => rx.test(key))) {
    matched.push(call);
  } else if (call.mockOnly) {
    mockOnly.push(call);
  } else {
    missing.push(call);
  }
}

console.log('\n╔══════════════════════════════════════════════════════════════╗');
console.log('║           SUMPOOJ API AUDIT REPORT                         ║');
console.log('╚══════════════════════════════════════════════════════════════╝\n');

console.log(`📊 Summary: ${matched.length} matched | ${missing.length} MISSING | ${mockOnly.length} mock-only\n`);

if (missing.length > 0) {
  console.log('─── ❌ MISSING ENDPOINTS (frontend calls, no backend handler) ──────\n');
  for (const call of missing.sort((a, b) => a.path.localeCompare(b.path))) {
    console.log(`  ${call.method.padEnd(7)} ${call.path}`);
    console.log(`          └─ ${call.file}:${call.line}`);
  }
}

if (mockOnly.length > 0) {
  console.log('\n─── ⚠️  MOCK-ONLY ENDPOINTS (TODO / mock data, no real API) ────────\n');
  for (const call of mockOnly.sort((a, b) => a.path.localeCompare(b.path))) {
    console.log(`  ${call.method.padEnd(7)} ${call.path}`);
    console.log(`          └─ ${call.file}:${call.line}`);
  }
}

if (matched.length > 0) {
  console.log('\n─── ✅ MATCHED ENDPOINTS ──────────────────────────────────────────\n');
  for (const call of matched.sort((a, b) => a.path.localeCompare(b.path))) {
    console.log(`  ${call.method.padEnd(7)} ${call.path}`);
  }
}

console.log(`\n─── Backend endpoints with no frontend caller ─────────────────────\n`);
const feKeys = new Set([...feUnique.keys()]);
const orphanBe = beEndpoints.filter(ep => !feKeys.has(`${ep.method} ${normalizePath(ep.path)}`));
const orphanUnique = new Map();
for (const ep of orphanBe) {
  const key = `${ep.method} ${normalizePath(ep.path)}`;
  if (!orphanUnique.has(key)) orphanUnique.set(key, ep);
}
for (const [, ep] of [...orphanUnique].sort((a, b) => a[1].path.localeCompare(b[1].path))) {
  console.log(`  ${ep.method.padEnd(7)} ${ep.path}  (${ep.file})`);
}

console.log('\n✅ Audit complete.\n');
