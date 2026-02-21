/**
 * Label Print Modal
 * Complete Barcode & Label System
 * Florist POS + ERP SaaS Platform
 */

import { useState, useEffect, useRef, useCallback } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Box,
  Typography,
  Button,
  TextField,
  FormControlLabel,
  Switch,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Divider,
  IconButton,
  useTheme,
  alpha,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import PrintIcon from '@mui/icons-material/Print';
import LocalOfferIcon from '@mui/icons-material/LocalOffer';
import JsBarcode from 'jsbarcode';

import type { LabelData, LabelConfig, BarcodeFormat } from './BarcodeTypes';
import { DEFAULT_LABEL_CONFIG, LABEL_SIZES } from './BarcodeTypes';
import { printLabels, generateLabelHTML } from './BarcodeUtils';

// ============================================
// PROPS INTERFACE
// ============================================

interface LabelPrintModalProps {
  open: boolean;
  onClose: () => void;
  labelData: LabelData;
  /** Optional initial config override */
  initialConfig?: Partial<LabelConfig>;
}

// ============================================
// COMPONENT
// ============================================

const LabelPrintModal: React.FC<LabelPrintModalProps> = ({
  open,
  onClose,
  labelData,
  initialConfig,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const previewRef = useRef<HTMLDivElement>(null);
  const barcodeSvgRef = useRef<SVGSVGElement>(null);

  // Label configuration state
  const [config, setConfig] = useState<LabelConfig>({
    ...DEFAULT_LABEL_CONFIG,
    ...initialConfig,
  });

  // Preview HTML
  const [previewHTML, setPreviewHTML] = useState('');

  // Update preview when config or data changes
  useEffect(() => {
    if (open && labelData.barcode) {
      const html = generateLabelHTML(labelData, config);
      setPreviewHTML(html);
    }
  }, [open, labelData, config]);

  // Render barcode to SVG ref
  useEffect(() => {
    if (open && barcodeSvgRef.current && labelData.barcode) {
      try {
        JsBarcode(barcodeSvgRef.current, labelData.barcode, {
          format: config.barcodeFormat === 'EAN13' ? 'EAN13' : 
                  config.barcodeFormat === 'UPC' ? 'UPC' : 'CODE128',
          width: 1.5,
          height: 40,
          displayValue: true,
          fontSize: 12,
          textMargin: 2,
          margin: 0,
          font: 'monospace',
        });
      } catch (error) {
        console.error('Barcode render error:', error);
      }
    }
  }, [open, labelData.barcode, config.barcodeFormat]);

  // Handle print
  const handlePrint = useCallback(() => {
    if (!labelData.barcode) return;
    printLabels(labelData, config);
  }, [labelData, config]);

  // Handle config changes
  const updateConfig = useCallback((updates: Partial<LabelConfig>) => {
    setConfig(prev => ({ ...prev, ...updates }));
  }, []);

  // Handle label size change
  const handleSizeChange = useCallback((sizeValue: string) => {
    const size = LABEL_SIZES.find(s => s.value === sizeValue);
    if (size) {
      updateConfig({ width: size.width, height: size.height });
    }
  }, [updateConfig]);

  // Get current size value
  const currentSizeValue = LABEL_SIZES.find(
    s => s.width === config.width && s.height === config.height
  )?.value || '50x25';

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          bgcolor: dk ? '#1a1a2e' : '#fff',
          borderRadius: 3,
        },
      }}
    >
      {/* Header */}
      <DialogTitle
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          pb: 1,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <LocalOfferIcon sx={{ color: theme.palette.primary.main }} />
          <Typography variant="h6" sx={{ fontWeight: 700 }}>
            Print Labels
          </Typography>
        </Box>
        <IconButton onClick={onClose} size="small">
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent dividers>
        {/* Product Info */}
        <Box sx={{ mb: 3 }}>
          <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
            Label Information
          </Typography>
          <Box sx={{ p: 2, bgcolor: dk ? alpha('#fff', 0.04) : alpha('#000', 0.02), borderRadius: 2 }}>
            <Typography variant="body2" sx={{ fontWeight: 600 }}>
              {labelData.name}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              SKU: {labelData.sku}
            </Typography>
            {labelData.price !== undefined && (
              <Typography variant="body2" sx={{ fontWeight: 700, mt: 0.5 }}>
                ₹{labelData.price.toFixed(2)}
              </Typography>
            )}
          </Box>
        </Box>

        {/* Label Preview */}
        <Box sx={{ mb: 3 }}>
          <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
            Label Preview
          </Typography>
          <Box
            sx={{
              p: 3,
              bgcolor: '#fff',
              border: `2px dashed ${dk ? 'rgba(255,255,255,0.2)' : '#ddd'}`,
              borderRadius: 2,
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              minHeight: 120,
            }}
          >
            {/* Actual Preview */}
            <Box
              sx={{
                width: `${config.width}mm`,
                height: `${config.height}mm`,
                p: '2mm',
                fontFamily: 'Arial, sans-serif',
                boxSizing: 'border-box',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                border: '0.5px dotted #999',
                bgcolor: '#fff',
                color: '#000',
              }}
            >
              <Typography
                sx={{
                  fontSize: '10px',
                  fontWeight: 700,
                  textAlign: 'center',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                  maxWidth: '100%',
                  mb: '2px',
                }}
              >
                {labelData.name}
              </Typography>
              <Typography
                sx={{
                  fontSize: '8px',
                  color: '#666',
                  mb: '2px',
                }}
              >
                {labelData.sku}
              </Typography>
              <svg ref={barcodeSvgRef} style={{ margin: '2px 0' }} />
              {config.includePrice && labelData.price !== undefined && (
                <Typography
                  sx={{
                    fontSize: '14px',
                    fontWeight: 700,
                    mt: '2px',
                  }}
                >
                  ₹{labelData.price.toFixed(2)}
                </Typography>
              )}
              {config.includeExpiry && labelData.expiryDate && (
                <Typography
                  sx={{
                    fontSize: '9px',
                    color: '#666',
                  }}
                >
                  Exp: {new Date(labelData.expiryDate).toLocaleDateString('en-IN', {
                    day: '2-digit',
                    month: 'short',
                    year: 'numeric',
                  })}
                </Typography>
              )}
            </Box>
          </Box>
        </Box>

        <Divider sx={{ my: 2 }} />

        {/* Print Settings */}
        <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 2 }}>
          Print Settings
        </Typography>

        {/* Quantity */}
        <TextField
          label="Number of Labels"
          type="number"
          size="small"
          fullWidth
          value={config.quantity}
          onChange={(e) => updateConfig({ quantity: Math.max(1, parseInt(e.target.value) || 1) })}
          slotProps={{
            input: {
              inputProps: { min: 1, max: 100 },
            },
          }}
          sx={{ mb: 2 }}
        />

        {/* Label Size */}
        <FormControl fullWidth size="small" sx={{ mb: 2 }}>
          <InputLabel>Label Size</InputLabel>
          <Select
            value={currentSizeValue}
            label="Label Size"
            onChange={(e) => handleSizeChange(e.target.value as string)}
          >
            {LABEL_SIZES.map((size) => (
              <MenuItem key={size.value} value={size.value}>
                {size.label}
              </MenuItem>
            ))}
          </Select>
        </FormControl>

        {/* Barcode Format */}
        <FormControl fullWidth size="small" sx={{ mb: 2 }}>
          <InputLabel>Barcode Format</InputLabel>
          <Select
            value={config.barcodeFormat}
            label="Barcode Format"
            onChange={(e) => updateConfig({ barcodeFormat: e.target.value as BarcodeFormat })}
          >
            <MenuItem value="CODE128">CODE128 (Default)</MenuItem>
            <MenuItem value="EAN13">EAN-13</MenuItem>
            <MenuItem value="UPC">UPC</MenuItem>
            <MenuItem value="CODE39">CODE39</MenuItem>
          </Select>
        </FormControl>

        {/* Toggle Options */}
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
          <FormControlLabel
            control={
              <Switch
                checked={config.includePrice}
                onChange={(e) => updateConfig({ includePrice: e.target.checked })}
                color="primary"
              />
            }
            label="Include Price"
          />
          {labelData.expiryDate && (
            <FormControlLabel
              control={
                <Switch
                  checked={config.includeExpiry}
                  onChange={(e) => updateConfig({ includeExpiry: e.target.checked })}
                  color="primary"
                />
              }
              label="Include Expiry Date"
            />
          )}
        </Box>
      </DialogContent>

      {/* Actions */}
      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} sx={{ fontWeight: 600 }}>
          Cancel
        </Button>
        <Button
          variant="contained"
          startIcon={<PrintIcon />}
          onClick={handlePrint}
          disabled={!labelData.barcode}
          sx={{ fontWeight: 700, minWidth: 120 }}
        >
          Print {config.quantity > 1 ? `(${config.quantity})` : ''}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default LabelPrintModal;
