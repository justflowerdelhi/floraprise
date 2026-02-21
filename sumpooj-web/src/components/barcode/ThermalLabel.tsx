/**
 * ThermalLabel – A single 2×1 inch (50×25 mm) barcode label.
 * Renders inline for preview; also used inside the print-only iframe.
 */

import { useEffect, useRef } from 'react';
import JsBarcode from 'jsbarcode';
import type { LabelData, LabelConfig } from './BarcodeTypes';

interface ThermalLabelProps {
  data: LabelData;
  config: LabelConfig;
  /** Scale factor applied for on-screen preview (default 1) */
  scale?: number;
}

const ThermalLabel: React.FC<ThermalLabelProps> = ({ data, config, scale = 1 }) => {
  const svgRef = useRef<SVGSVGElement>(null);

  useEffect(() => {
    if (!svgRef.current || !data.barcode) return;
    try {
      JsBarcode(svgRef.current, data.barcode, {
        format:
          config.barcodeFormat === 'EAN13'
            ? 'EAN13'
            : config.barcodeFormat === 'UPC'
              ? 'UPC'
              : 'CODE128',
        width: 1.2,
        height: 28,
        displayValue: true,
        fontSize: 10,
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
      className="thermal-label"
      style={{
        width: `${config.width}mm`,
        height: `${config.height}mm`,
        padding: '1.5mm 2mm',
        fontFamily: "'Arial', sans-serif",
        boxSizing: 'border-box',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        border: '0.5px dotted #999',
        backgroundColor: '#fff',
        color: '#000',
        overflow: 'hidden',
        transform: scale !== 1 ? `scale(${scale})` : undefined,
        transformOrigin: 'top left',
      }}
    >
      {/* Product name */}
      <div
        style={{
          fontSize: '9px',
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

      {/* SKU */}
      <div style={{ fontSize: '7px', color: '#666', marginBottom: '1px' }}>
        {data.sku}
      </div>

      {/* Barcode SVG */}
      <svg ref={svgRef} style={{ margin: '1px 0', maxWidth: '100%' }} />

      {/* Price (optional) */}
      {config.includePrice && data.price !== undefined && (
        <div style={{ fontSize: '11px', fontWeight: 700, marginTop: '1px' }}>
          ₹{data.price.toFixed(2)}
        </div>
      )}

      {/* Expiry (optional) */}
      {config.includeExpiry && data.expiryDate && (
        <div style={{ fontSize: '7px', color: '#555' }}>
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

export default ThermalLabel;
