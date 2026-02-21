/**
 * Label Print Modal — Enhanced
 * Supports Thermal (2×1 inch) and A4 Sheet grid printing.
 * Florist POS + ERP SaaS Platform
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
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
  ToggleButtonGroup,
  ToggleButton,
  Chip,
  useTheme,
  alpha,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import PrintIcon from '@mui/icons-material/Print';
import LocalOfferIcon from '@mui/icons-material/LocalOffer';
import ThermostatIcon from '@mui/icons-material/Thermostat';
import DescriptionIcon from '@mui/icons-material/Description';

import type {
  LabelData,
  LabelConfig,
  BarcodeFormat,
  PrintMode,
  A4GridLayout,
} from './BarcodeTypes';
import { DEFAULT_LABEL_CONFIG, LABEL_SIZES, A4_GRID_LAYOUTS } from './BarcodeTypes';
import { printLabels } from './BarcodeUtils';
import ThermalLabel from './ThermalLabel';
import A4GridSheet from './A4GridSheet';

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
// CONSTANTS
// ============================================

const A4_PREVIEW_SCALE = 0.32;
const MAX_PREVIEW_LABELS_A4 = 48;

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

  // ── State ──
  const [printMode, setPrintMode] = useState<PrintMode>('thermal');
  const [a4Layout, setA4Layout] = useState<A4GridLayout>('3x8');

  const [config, setConfig] = useState<LabelConfig>({
    ...DEFAULT_LABEL_CONFIG,
    ...initialConfig,
  });

  // Reset on open
  useEffect(() => {
    if (open) {
      setConfig({ ...DEFAULT_LABEL_CONFIG, ...initialConfig });
      setPrintMode('thermal');
      setA4Layout('3x8');
    }
  }, [open, initialConfig]);

  // ── Helpers ──
  const updateConfig = useCallback((updates: Partial<LabelConfig>) => {
    setConfig((prev) => ({ ...prev, ...updates }));
  }, []);

  const handleSizeChange = useCallback(
    (sizeValue: string) => {
      const size = LABEL_SIZES.find((s) => s.value === sizeValue);
      if (size) updateConfig({ width: size.width, height: size.height });
    },
    [updateConfig],
  );

  const currentSizeValue =
    LABEL_SIZES.find((s) => s.width === config.width && s.height === config.height)?.value ??
    '50x25';

  const a4Grid = useMemo(() => A4_GRID_LAYOUTS[a4Layout], [a4Layout]);
  const labelsPerA4Page = a4Grid.cols * a4Grid.rows;

  const canPrint = !!labelData.barcode;

  // ── Handlers ──
  const handlePrint = useCallback(() => {
    if (!canPrint) return;
    printLabels(labelData, config, printMode, a4Layout);
  }, [labelData, config, printMode, a4Layout, canPrint]);

  // ── Render ──
  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: {
          bgcolor: dk ? '#1a1a2e' : '#fff',
          borderRadius: 3,
          maxHeight: '90vh',
        },
      }}
    >
      {/* ─── Header ─── */}
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

      <DialogContent dividers sx={{ overflowY: 'auto' }}>
        {/* ─── Product Info ─── */}
        <Box sx={{ mb: 2.5 }}>
          <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
            Label Information
          </Typography>
          <Box
            sx={{
              p: 2,
              bgcolor: dk ? alpha('#fff', 0.04) : alpha('#000', 0.02),
              borderRadius: 2,
            }}
          >
            <Typography variant="body2" sx={{ fontWeight: 600 }}>
              {labelData.name}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              SKU: {labelData.sku} &nbsp;|&nbsp; Barcode: {labelData.barcode || '—'}
            </Typography>
            {labelData.price !== undefined && (
              <Typography variant="body2" sx={{ fontWeight: 700, mt: 0.5 }}>
                ₹{labelData.price.toFixed(2)}
              </Typography>
            )}
          </Box>
        </Box>

        {/* ─── Print Mode Toggle ─── */}
        <Box sx={{ mb: 2.5 }}>
          <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
            Print Mode
          </Typography>
          <ToggleButtonGroup
            value={printMode}
            exclusive
            onChange={(_, v) => v && setPrintMode(v)}
            size="small"
            fullWidth
            sx={{
              '& .MuiToggleButton-root': {
                textTransform: 'none',
                fontWeight: 600,
                gap: 0.5,
              },
            }}
          >
            <ToggleButton value="thermal">
              <ThermostatIcon fontSize="small" />
              Thermal 2×1″
            </ToggleButton>
            <ToggleButton value="a4">
              <DescriptionIcon fontSize="small" />
              A4 Sheet
            </ToggleButton>
          </ToggleButtonGroup>
        </Box>

        {/* ─── A4 Layout Selector (only when A4 mode) ─── */}
        {printMode === 'a4' && (
          <Box sx={{ mb: 2.5 }}>
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
              Sheet Layout
            </Typography>
            <ToggleButtonGroup
              value={a4Layout}
              exclusive
              onChange={(_, v) => v && setA4Layout(v)}
              size="small"
              fullWidth
              sx={{
                '& .MuiToggleButton-root': {
                  textTransform: 'none',
                  fontWeight: 600,
                },
              }}
            >
              <ToggleButton value="3x8">
                3 × 8&nbsp;
                <Chip label="24/page" size="small" variant="outlined" sx={{ ml: 0.5, height: 20 }} />
              </ToggleButton>
              <ToggleButton value="2x7">
                2 × 7&nbsp;
                <Chip label="14/page" size="small" variant="outlined" sx={{ ml: 0.5, height: 20 }} />
              </ToggleButton>
            </ToggleButtonGroup>
          </Box>
        )}

        {/* ─── Label Preview ─── */}
        <Box sx={{ mb: 2.5 }}>
          <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
            Preview
            {printMode === 'a4' && (
              <Typography component="span" variant="caption" color="text.secondary" sx={{ ml: 1 }}>
                ({a4Layout} grid — {labelsPerA4Page} labels/page)
              </Typography>
            )}
          </Typography>

          <Box
            sx={{
              p: 2,
              bgcolor: dk ? '#111' : '#f5f5f5',
              border: `2px dashed ${dk ? 'rgba(255,255,255,0.15)' : '#ddd'}`,
              borderRadius: 2,
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'flex-start',
              overflow: 'auto',
              maxHeight: 360,
              minHeight: 120,
            }}
          >
            {!labelData.barcode ? (
              <Typography color="error" variant="body2" sx={{ my: 4 }}>
                No barcode available — cannot generate preview.
              </Typography>
            ) : printMode === 'thermal' ? (
              /* Thermal: single label, zoomed 2× for readability */
              <Box sx={{ transform: 'scale(2)', transformOrigin: 'top center', my: 2 }}>
                <ThermalLabel data={labelData} config={config} />
              </Box>
            ) : (
              /* A4: scaled-down grid preview */
              <A4GridSheet
                data={labelData}
                config={config}
                layout={a4Layout}
                quantity={Math.min(config.quantity, MAX_PREVIEW_LABELS_A4)}
                scale={A4_PREVIEW_SCALE}
              />
            )}
          </Box>
        </Box>

        <Divider sx={{ my: 2 }} />

        {/* ─── Print Settings ─── */}
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
          onChange={(e) =>
            updateConfig({ quantity: Math.max(1, parseInt(e.target.value) || 1) })
          }
          slotProps={{ input: { inputProps: { min: 1, max: 500 } } }}
          helperText={
            printMode === 'a4'
              ? `${Math.ceil(config.quantity / labelsPerA4Page)} page(s) needed`
              : undefined
          }
          sx={{ mb: 2 }}
        />

        {/* Thermal: Label Size */}
        {printMode === 'thermal' && (
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
        )}

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

      {/* ─── Actions ─── */}
      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} sx={{ fontWeight: 600 }}>
          Cancel
        </Button>
        <Button
          variant="contained"
          startIcon={<PrintIcon />}
          onClick={handlePrint}
          disabled={!canPrint}
          sx={{ fontWeight: 700, minWidth: 140 }}
        >
          Print{' '}
          {printMode === 'thermal'
            ? config.quantity > 1
              ? `(${config.quantity})`
              : ''
            : `(${config.quantity} on ${Math.ceil(config.quantity / labelsPerA4Page)} pg)`}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default LabelPrintModal;
