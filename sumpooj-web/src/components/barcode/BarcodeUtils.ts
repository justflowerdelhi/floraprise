/**
 * Barcode Utilities
 * Complete Barcode & Label System
 * Florist POS + ERP SaaS Platform
 */

import JsBarcode from 'jsbarcode';
import type {
  BarcodeFormat,
  BarcodeSourceType,
  LabelData,
  LabelConfig,
  BarcodeValidationResult,
  BARCODE_PREFIXES,
  PrintMode,
  A4GridLayout,
  A4GridConfig,
} from './BarcodeTypes';
import { A4_GRID_LAYOUTS } from './BarcodeTypes';
import { getCurrencySymbol } from '../../core/i18n';

// ============================================
// BARCODE GENERATION UTILITIES
// ============================================

/**
 * Generate a random internal barcode
 * Format: PREFIX-YYYYMMDD-XXXXX (where X is random alphanumeric)
 */
export function generateInternalBarcode(
  prefix: keyof typeof BARCODE_PREFIXES = 'INTERNAL'
): string {
  const prefixMap = {
    INTERNAL: 'INT',
    BATCH: 'BAT',
    FINISHED: 'FIN',
  };
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const random = generateRandomString(5);
  return `${prefixMap[prefix]}${dateStr}${random}`;
}

/**
 * Generate alphanumeric string
 */
function generateRandomString(length: number): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing chars: I, O, 0, 1
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * Format barcode for display (with dashes)
 */
export function formatBarcodeDisplay(barcode: string): string {
  if (!barcode) return '';
  
  // Internal/Batch/Finished format: XXXYYYYMMDDXXXXX -> XXX-YYYYMMDD-XXXXX
  if (/^(INT|BAT|FIN)\d{8}[A-Z0-9]{5}$/.test(barcode)) {
    return `${barcode.slice(0, 3)}-${barcode.slice(3, 11)}-${barcode.slice(11)}`;
  }
  
  // EAN-13 format
  if (/^\d{13}$/.test(barcode)) {
    return `${barcode.slice(0, 1)}-${barcode.slice(1, 7)}-${barcode.slice(7, 12)}-${barcode.slice(12)}`;
  }
  
  return barcode;
}

// ============================================
// BARCODE VALIDATION
// ============================================

/**
 * Validate barcode format and structure
 */
export function validateBarcode(barcode: string): BarcodeValidationResult {
  if (!barcode || barcode.trim() === '') {
    return {
      isValid: false,
      isUnique: false,
      errorMessage: 'Barcode cannot be empty',
    };
  }

  const trimmed = barcode.trim().toUpperCase();

  // Check minimum length
  if (trimmed.length < 3) {
    return {
      isValid: false,
      isUnique: false,
      errorMessage: 'Barcode must be at least 3 characters',
    };
  }

  // Check for invalid characters (only alphanumeric and hyphens)
  if (!/^[A-Z0-9-]+$/.test(trimmed)) {
    return {
      isValid: false,
      isUnique: false,
      errorMessage: 'Barcode can only contain letters, numbers, and hyphens',
    };
  }

  // Detect format
  let detectedFormat: BarcodeFormat = 'CODE128';
  
  if (/^\d{13}$/.test(trimmed)) {
    detectedFormat = 'EAN13';
  } else if (/^\d{12}$/.test(trimmed)) {
    detectedFormat = 'UPC';
  } else if (/^[A-Z0-9]+$/.test(trimmed)) {
    detectedFormat = 'CODE128';
  }

  return {
    isValid: true,
    isUnique: true, // Will be checked by backend
    detectedFormat,
  };
}

/**
 * Determine barcode type from prefix
 */
export function getBarcodeType(barcode: string): BarcodeSourceType {
  if (!barcode) return 'EXTERNAL';
  
  const upper = barcode.toUpperCase();
  if (upper.startsWith('INT')) return 'INTERNAL';
  if (upper.startsWith('BAT')) return 'BATCH';
  if (upper.startsWith('FIN')) return 'FINISHED';
  
  return 'EXTERNAL';
}

// ============================================
// SVG BARCODE RENDERING
// ============================================

/**
 * Render barcode to SVG element
 */
export function renderBarcodeToSVG(
  svgElement: SVGElement,
  value: string,
  options?: {
    format?: BarcodeFormat;
    width?: number;
    height?: number;
    displayValue?: boolean;
    fontSize?: number;
    textMargin?: number;
  }
): void {
  const {
    format = 'CODE128',
    width = 2,
    height = 50,
    displayValue = true,
    fontSize = 12,
    textMargin = 2,
  } = options || {};

  try {
    JsBarcode(svgElement, value, {
      format: format === 'EAN13' ? 'EAN13' : format === 'UPC' ? 'UPC' : 'CODE128',
      width,
      height,
      displayValue,
      fontSize,
      textMargin,
      margin: 0,
      font: 'monospace',
    });
  } catch (error) {
    console.error('Failed to render barcode:', error);
  }
}

/**
 * Generate barcode SVG string for printing
 */
export function generateBarcodeSVGString(
  value: string,
  options?: {
    format?: BarcodeFormat;
    width?: number;
    height?: number;
    displayValue?: boolean;
  }
): string {
  const {
    format = 'CODE128',
    width = 2,
    height = 40,
    displayValue = false,
  } = options || {};

  // Create temporary SVG element
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  
  try {
    JsBarcode(svg, value, {
      format: format === 'EAN13' ? 'EAN13' : format === 'UPC' ? 'UPC' : 'CODE128',
      width,
      height,
      displayValue,
      margin: 0,
      font: 'monospace',
      fontSize: 10,
    });
    
    return new XMLSerializer().serializeToString(svg);
  } catch (error) {
    console.error('Failed to generate barcode SVG:', error);
    return '';
  }
}

// ============================================
// LABEL PRINTING
// ============================================

/**
 * Generate printable label HTML
 */
export function generateLabelHTML(
  data: LabelData,
  config: LabelConfig
): string {
  const currencySymbol = getCurrencySymbol();
  const barcodeSVG = generateBarcodeSVGString(data.barcode, {
    format: config.barcodeFormat,
    width: 1.5,
    height: 30,
    displayValue: true,
  });

  const priceSection = config.includePrice && data.price !== undefined
    ? `<div style="font-size: 14px; font-weight: bold; margin-top: 2px;">${currencySymbol}${data.price.toFixed(2)}</div>`
    : '';

  const expirySection = config.includeExpiry && data.expiryDate
    ? `<div style="font-size: 9px; color: #666;">Exp: ${formatExpiryDate(data.expiryDate)}</div>`
    : '';

  return `
    <div style="
      width: ${config.width}mm;
      height: ${config.height}mm;
      padding: 2mm;
      font-family: 'Arial', sans-serif;
      box-sizing: border-box;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      border: 0.5px dotted #ccc;
      page-break-after: always;
    ">
      <div style="font-size: 10px; font-weight: bold; text-align: center; margin-bottom: 2px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 100%;">
        ${escapeHTML(data.name)}
      </div>
      <div style="font-size: 8px; color: #666; margin-bottom: 2px;">
        ${escapeHTML(data.sku)}
      </div>
      <div style="margin: 2px 0;">
        ${barcodeSVG}
      </div>
      ${priceSection}
      ${expirySection}
    </div>
  `;
}

/**
 * Print labels – supports Thermal and A4 modes.
 */
export function printLabels(
  data: LabelData,
  config: LabelConfig,
  mode: PrintMode = 'thermal',
  a4Layout: A4GridLayout = '3x8'
): void {
  if (mode === 'a4') {
    printA4Labels(data, config, a4Layout);
  } else {
    printThermalLabels(data, config);
  }
}

/**
 * Print thermal labels (one per page, exact label size).
 */
function printThermalLabels(data: LabelData, config: LabelConfig): void {
  const labelsHTML = Array(config.quantity)
    .fill(null)
    .map(() => generateLabelHTML(data, config))
    .join('');

  const printWindow = window.open('', '_blank', 'width=400,height=600');
  if (!printWindow) {
    console.error('Failed to open print window. Check popup blocker.');
    return;
  }

  printWindow.document.write(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Print Thermal Labels</title>
        <style>
          @page {
            size: ${config.width}mm ${config.height}mm;
            margin: 0;
          }
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { margin: 0; padding: 0; }
          .thermal-label { page-break-after: always; }
          .thermal-label:last-child { page-break-after: auto; }
          @media print {
            body { margin: 0; padding: 0; }
            .no-print { display: none !important; }
          }
        </style>
      </head>
      <body>
        ${labelsHTML}
        <script>
          window.onload = function() {
            window.print();
            window.onafterprint = function() { window.close(); };
          };
        <\/script>
      </body>
    </html>
  `);
  printWindow.document.close();
}

/**
 * Print A4 sheet labels in a grid layout.
 */
function printA4Labels(
  data: LabelData,
  config: LabelConfig,
  layout: A4GridLayout
): void {
  const grid: A4GridConfig = A4_GRID_LAYOUTS[layout];
  const labelsPerPage = grid.cols * grid.rows;
  const totalPages = Math.ceil(config.quantity / labelsPerPage);

  let allPagesHTML = '';
  let remaining = config.quantity;

  for (let p = 0; p < totalPages; p++) {
    const countThisPage = Math.min(remaining, labelsPerPage);
    remaining -= countThisPage;

    let cellsHTML = '';
    for (let i = 0; i < countThisPage; i++) {
      cellsHTML += generateA4CellHTML(data, config, grid);
    }

    allPagesHTML += `
      <div class="a4-page" style="
        width: 210mm;
        min-height: 297mm;
        padding-left: ${grid.marginLeft}mm;
        padding-top: ${grid.marginTop}mm;
        box-sizing: border-box;
        display: grid;
        grid-template-columns: repeat(${grid.cols}, ${grid.labelWidth}mm);
        grid-auto-rows: ${grid.labelHeight}mm;
        column-gap: ${grid.columnGap}mm;
        row-gap: ${grid.rowGap}mm;
        page-break-after: ${p < totalPages - 1 ? 'always' : 'auto'};
      ">
        ${cellsHTML}
      </div>
    `;
  }

  const printWindow = window.open('', '_blank', 'width=800,height=1000');
  if (!printWindow) {
    console.error('Failed to open print window. Check popup blocker.');
    return;
  }

  printWindow.document.write(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Print A4 Labels</title>
        <style>
          @page {
            size: A4;
            margin: 0;
          }
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { margin: 0; padding: 0; background: #fff; color: #000; }
          @media print {
            body { margin: 0; padding: 0; }
            .no-print { display: none !important; }
          }
        </style>
      </head>
      <body>
        ${allPagesHTML}
        <script>
          window.onload = function() {
            window.print();
            window.onafterprint = function() { window.close(); };
          };
        <\/script>
      </body>
    </html>
  `);
  printWindow.document.close();
}

/**
 * Generate HTML for a single cell in the A4 grid.
 */
function generateA4CellHTML(
  data: LabelData,
  config: LabelConfig,
  grid: A4GridConfig
): string {
  const currencySymbol = getCurrencySymbol();
  const barcodeSVG = generateBarcodeSVGString(data.barcode, {
    format: config.barcodeFormat,
    width: 1.2,
    height: 24,
    displayValue: true,
  });

  const priceSection =
    config.includePrice && data.price !== undefined
      ? `<div style="font-size: 10px; font-weight: bold; margin-top: 1px;">${currencySymbol}${data.price.toFixed(2)}</div>`
      : '';

  const expirySection =
    config.includeExpiry && data.expiryDate
      ? `<div style="font-size: 6.5px; color: #555;">Exp: ${formatExpiryDate(data.expiryDate)}</div>`
      : '';

  return `
    <div style="
      width: ${grid.labelWidth}mm;
      height: ${grid.labelHeight}mm;
      padding: 1mm 1.5mm;
      font-family: 'Arial', sans-serif;
      box-sizing: border-box;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      border: 0.25px dotted #ccc;
      overflow: hidden;
    ">
      <div style="font-size: 8px; font-weight: bold; text-align: center; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 100%; margin-bottom: 1px;">
        ${escapeHTML(data.name)}
      </div>
      <div style="font-size: 6.5px; color: #666; margin-bottom: 1px;">
        ${escapeHTML(data.sku)}
      </div>
      <div style="margin: 1px 0; max-width: 100%;">
        ${barcodeSVG}
      </div>
      ${priceSection}
      ${expirySection}
    </div>
  `;
}

// ============================================
// HELPER FUNCTIONS
// ============================================

function escapeHTML(str: string): string {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

function formatExpiryDate(dateStr: string): string {
  try {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  } catch {
    return dateStr;
  }
}

// ============================================
// SCANNER INPUT PROCESSING
// ============================================

/**
 * Process scanner input (typically fired rapidly)
 * Returns true if likely from a barcode scanner
 */
export function isScannerInput(
  inputValue: string,
  timeSinceLastInput: number
): boolean {
  // Barcode scanners typically input entire barcode in < 100ms
  // And barcodes are usually 8+ characters
  return timeSinceLastInput < 100 && inputValue.length >= 8;
}

/**
 * Clean barcode input (remove common scanner artifacts)
 */
export function cleanBarcodeInput(input: string): string {
  return input
    .trim()
    .replace(/[\r\n]/g, '') // Remove line breaks
    .replace(/^\s+|\s+$/g, '') // Trim whitespace
    .toUpperCase();
}
