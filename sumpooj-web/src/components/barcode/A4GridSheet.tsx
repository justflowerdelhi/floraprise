/**
 * A4GridSheet – Renders a paginated A4 grid of barcode labels.
 * Used both for on-screen preview and inside the print iframe.
 */

import { useEffect, useRef, useCallback } from 'react';
import 'jsbarcode/dist/JsBarcode.all.js';
import type { LabelData, LabelConfig, A4GridLayout, A4GridConfig } from './BarcodeTypes';
import { A4_GRID_LAYOUTS } from './BarcodeTypes';
import { getCurrencySymbol } from '../../core/i18n';

const JsBarcode = (window as Window & {
  JsBarcode?: (element: SVGElement, code: string, options?: Record<string, unknown>) => void;
}).JsBarcode;

interface A4GridSheetProps {
  data: LabelData;
  config: LabelConfig;
  layout: A4GridLayout;
  /** Total number of labels to generate */
  quantity: number;
  /** Scale for on-screen preview (default 1) */
  scale?: number;
}

/** Individual cell inside the grid */
const GridCell: React.FC<{
  data: LabelData;
  config: LabelConfig;
  grid: A4GridConfig;
}> = ({ data, config, grid }) => {
  const svgRef = useRef<SVGSVGElement>(null);
  const currencySymbol = getCurrencySymbol();

  useEffect(() => {
    if (!svgRef.current || !data.barcode) return;
    if (!JsBarcode) return;
    try {
      JsBarcode(svgRef.current, data.barcode, {
        format:
          config.barcodeFormat === 'EAN13'
            ? 'EAN13'
            : config.barcodeFormat === 'UPC'
              ? 'UPC'
              : 'CODE128',
        width: 1.2,
        height: 24,
        displayValue: true,
        fontSize: 9,
        textMargin: 1,
        margin: 0,
        font: 'monospace',
      });
    } catch (e) {
      console.error('Barcode render error:', e);
    }
  }, [data.barcode, config.barcodeFormat]);

  return (
    <div
      className="a4-label-cell"
      style={{
        width: `${grid.labelWidth}mm`,
        height: `${grid.labelHeight}mm`,
        padding: '1mm 1.5mm',
        fontFamily: "'Arial', sans-serif",
        boxSizing: 'border-box',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        border: '0.25px dotted #ccc',
        overflow: 'hidden',
        backgroundColor: '#fff',
        color: '#000',
      }}
    >
      <div
        style={{
          fontSize: '8px',
          fontWeight: 700,
          textAlign: 'center',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap',
          maxWidth: '100%',
          marginBottom: '1px',
          lineHeight: 1.2,
        }}
      >
        {data.name}
      </div>

      <div style={{ fontSize: '6.5px', color: '#666', marginBottom: '1px' }}>
        {data.sku}
      </div>

      <svg ref={svgRef} style={{ margin: '1px 0', maxWidth: '100%' }} />

      {config.includePrice && data.price !== undefined && (
        <div style={{ fontSize: '10px', fontWeight: 700, marginTop: '1px' }}>
          {currencySymbol}{data.price.toFixed(2)}
        </div>
      )}

      {config.includeExpiry && data.expiryDate && (
        <div style={{ fontSize: '6.5px', color: '#555' }}>
          Exp:{' '}
          {new Date(data.expiryDate).toLocaleDateString('en-IN', {
            day: '2-digit',
            month: 'short',
            year: 'numeric',
          })}
        </div>
      )}
    </div>
  );
};

const A4GridSheet: React.FC<A4GridSheetProps> = ({
  data,
  config,
  layout,
  quantity,
  scale = 1,
}) => {
  const grid = A4_GRID_LAYOUTS[layout];
  const labelsPerPage = grid.cols * grid.rows;
  const totalPages = Math.ceil(quantity / labelsPerPage);

  const pages = useCallback(() => {
    const result: number[][] = [];
    let remaining = quantity;
    for (let p = 0; p < totalPages; p++) {
      const count = Math.min(remaining, labelsPerPage);
      result.push(Array.from({ length: count }, (_, i) => p * labelsPerPage + i));
      remaining -= count;
    }
    return result;
  }, [quantity, totalPages, labelsPerPage]);

  return (
    <div
      className="a4-grid-container"
      style={{
        transform: scale !== 1 ? `scale(${scale})` : undefined,
        transformOrigin: 'top left',
      }}
    >
      {pages().map((cellIndices, pageIdx) => (
        <div
          key={pageIdx}
          className="a4-page"
          style={{
            width: '210mm',
            minHeight: '297mm',
            backgroundColor: '#fff',
            color: '#000',
            paddingLeft: `${grid.marginLeft}mm`,
            paddingTop: `${grid.marginTop}mm`,
            boxSizing: 'border-box',
            pageBreakAfter: pageIdx < totalPages - 1 ? 'always' : 'auto',
            display: 'grid',
            gridTemplateColumns: `repeat(${grid.cols}, ${grid.labelWidth}mm)`,
            gridAutoRows: `${grid.labelHeight}mm`,
            columnGap: `${grid.columnGap}mm`,
            rowGap: `${grid.rowGap}mm`,
          }}
        >
          {cellIndices.map((idx) => (
            <GridCell key={idx} data={data} config={config} grid={grid} />
          ))}
        </div>
      ))}
    </div>
  );
};

export default A4GridSheet;
