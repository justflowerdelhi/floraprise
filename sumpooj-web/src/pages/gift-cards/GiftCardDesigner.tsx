/**
 * GiftCardDesigner.tsx — Form panel for configuring AI floral gift card
 *
 * Fields: Occasion, Color Theme, Floral Style, Message, Sender Name
 * Plus: Font picker, text color override, Generate button
 */
import React from 'react';
import {
  Box, Typography, TextField, MenuItem, Button, CircularProgress,
  useTheme, alpha, Divider, Select, FormControl, InputLabel,
  type SelectChangeEvent,
} from '@mui/material';
import {
  AutoAwesome as GenerateIcon,
  Palette as PaletteIcon,
  FormatColorText as FontIcon,
} from '@mui/icons-material';
import type { GiftCardFormData } from './GiftCardTypes';
import {
  OCCASION_OPTIONS, COLOR_THEME_OPTIONS, FLORAL_STYLE_OPTIONS,
  FONT_OPTIONS, THEME_TEXT_COLORS,
} from './GiftCardTypes';

// ─── Props ──────────────────────────────────────────────────

interface GiftCardDesignerProps {
  form: GiftCardFormData;
  onChange: (field: keyof GiftCardFormData, value: string) => void;
  onGenerate: () => void;
  isGenerating: boolean;
  hasBackground: boolean;
}

// ─── Component ──────────────────────────────────────────────

const GiftCardDesigner: React.FC<GiftCardDesignerProps> = ({
  form, onChange, onGenerate, isGenerating, hasBackground,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const canGenerate = form.occasion && form.colorTheme && form.floralStyle;

  const fieldSx = dk ? {
    '& .MuiOutlinedInput-root': {
      color: '#e0e0e0',
      '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' },
      '&:hover fieldset': { borderColor: 'rgba(255,255,255,0.3)' },
      '&.Mui-focused fieldset': { borderColor: theme.palette.primary.main },
    },
    '& .MuiInputLabel-root': { color: 'rgba(255,255,255,0.5)' },
  } : undefined;

  const handleSelectChange = (field: keyof GiftCardFormData) => (e: SelectChangeEvent<string>) => {
    const val = e.target.value;
    onChange(field, val);
    // Auto-set text color when theme changes
    if (field === 'colorTheme' && THEME_TEXT_COLORS[val]) {
      onChange('textColor', THEME_TEXT_COLORS[val]);
    }
  };

  return (
    <Box
      sx={{
        p: 3,
        display: 'flex',
        flexDirection: 'column',
        gap: 2.5,
        height: '100%',
        overflow: 'auto',
      }}
    >
      {/* Header */}
      <Box>
        <Typography variant="h5" sx={{ fontWeight: 800, mb: 0.5, fontFamily: "'Playfair Display', serif" }}>
          🌸 Greeting Card Designer
        </Typography>
        <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
          Premium vertical 5×7 greeting card with AI-generated floral background
        </Typography>
      </Box>

      <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.08)' : undefined }} />

      {/* Section: Background Configuration */}
      <Typography variant="subtitle2" sx={{ fontWeight: 700, color: theme.palette.primary.main, mt: 0.5 }}>
        Background Configuration
      </Typography>

      {/* Occasion */}
      <FormControl fullWidth size="small" sx={fieldSx}>
        <InputLabel>Occasion</InputLabel>
        <Select
          value={form.occasion}
          label="Occasion"
          onChange={handleSelectChange('occasion')}
        >
          {OCCASION_OPTIONS.map((o) => (
            <MenuItem key={o.value} value={o.value}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>{o.emoji}</span> {o.label}
              </Box>
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      {/* Color Theme */}
      <FormControl fullWidth size="small" sx={fieldSx}>
        <InputLabel>Color Theme</InputLabel>
        <Select
          value={form.colorTheme}
          label="Color Theme"
          onChange={handleSelectChange('colorTheme')}
        >
          {COLOR_THEME_OPTIONS.map((o) => (
            <MenuItem key={o.value} value={o.value}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>{o.emoji}</span> {o.label}
              </Box>
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      {/* Floral Style */}
      <FormControl fullWidth size="small" sx={fieldSx}>
        <InputLabel>Floral Style</InputLabel>
        <Select
          value={form.floralStyle}
          label="Floral Style"
          onChange={handleSelectChange('floralStyle')}
        >
          {FLORAL_STYLE_OPTIONS.map((o) => (
            <MenuItem key={o.value} value={o.value}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>{o.emoji}</span> {o.label}
              </Box>
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      {/* Generate Button */}
      <Button
        variant="contained"
        size="large"
        fullWidth
        disabled={!canGenerate || isGenerating}
        onClick={onGenerate}
        startIcon={isGenerating ? <CircularProgress size={20} color="inherit" /> : <GenerateIcon />}
        sx={{
          py: 1.5,
          fontWeight: 700,
          fontSize: '0.95rem',
          background: canGenerate && !isGenerating
            ? 'linear-gradient(135deg, #7B4DB1 0%, #5B2E91 50%, #3B1E71 100%)'
            : undefined,
          '&:hover': {
            background: 'linear-gradient(135deg, #8B5DC1 0%, #6B3EA1 50%, #4B2E81 100%)',
          },
        }}
      >
        {isGenerating ? 'Designing your card…' : hasBackground ? 'Regenerate Design' : 'Generate Card Design'}
      </Button>

      <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.08)' : undefined }} />

      {/* Section: Card Content */}
      <Typography variant="subtitle2" sx={{ fontWeight: 700, color: theme.palette.secondary.main }}>
        Card Content
      </Typography>

      {/* Message */}
      <TextField
        label="Message"
        multiline
        rows={4}
        fullWidth
        size="small"
        value={form.message}
        onChange={(e) => onChange('message', e.target.value)}
        placeholder="Write a heartfelt message…"
        inputProps={{ maxLength: 200 }}
        helperText={`${form.message.length}/200 characters`}
        sx={fieldSx}
      />

      {/* Sender Name */}
      <TextField
        label="Sender Name"
        fullWidth
        size="small"
        value={form.senderName}
        onChange={(e) => onChange('senderName', e.target.value)}
        placeholder="e.g. With love, Sarah"
        inputProps={{ maxLength: 60 }}
        sx={fieldSx}
      />

      <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.08)' : undefined }} />

      {/* Section: Text Styling */}
      <Typography variant="subtitle2" sx={{ fontWeight: 700, color: dk ? '#ff9800' : '#e65100' }}>
        <FontIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'text-bottom' }} />
        Text Styling
      </Typography>

      {/* Font Choice */}
      <FormControl fullWidth size="small" sx={fieldSx}>
        <InputLabel>Font</InputLabel>
        <Select
          value={form.fontChoice}
          label="Font"
          onChange={handleSelectChange('fontChoice')}
        >
          {FONT_OPTIONS.map((f) => (
            <MenuItem key={f.value} value={f.value}>
              <span style={{ fontFamily: f.fontFamily }}>{f.label}</span>
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      {/* Text Color */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
        <PaletteIcon sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', fontSize: 20 }} />
        <Typography variant="body2" sx={{ fontWeight: 600, flex: 1 }}>
          Text Color
        </Typography>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Box
            component="input"
            type="color"
            value={form.textColor}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => onChange('textColor', e.target.value)}
            sx={{
              width: 36, height: 36,
              border: `2px solid ${dk ? 'rgba(255,255,255,0.2)' : '#ccc'}`,
              borderRadius: 1,
              cursor: 'pointer',
              p: 0,
              bgcolor: 'transparent',
              '&::-webkit-color-swatch-wrapper': { p: '2px' },
              '&::-webkit-color-swatch': { borderRadius: '2px', border: 'none' },
            }}
          />
          <Typography variant="caption" sx={{ fontFamily: 'monospace', color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
            {form.textColor}
          </Typography>
        </Box>
      </Box>

      {/* Auto-contrast hint */}
      {form.colorTheme && (
        <Typography
          variant="caption"
          sx={{
            color: dk ? 'rgba(255,255,255,0.35)' : 'text.disabled',
            fontStyle: 'italic',
            mt: -1,
          }}
        >
          💡 Text color auto-adjusts for contrast when you pick a color theme
        </Typography>
      )}
    </Box>
  );
};

export default GiftCardDesigner;
