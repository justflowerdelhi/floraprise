/**
 * GiftCardBuilder.tsx — Designer form for the Gift Card Builder module.
 *
 * Left-side form with: occasion, color theme, background grid selector,
 * message template / custom message, sender name, font controls, logo upload.
 */
import React, { useCallback } from 'react';
import {
  Box,
  Typography,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Slider,
  ToggleButtonGroup,
  ToggleButton,
  Switch,
  FormControlLabel,
  Button,
  useTheme,
} from '@mui/material';
import {
  FormatAlignLeft,
  FormatAlignCenter,
  FormatAlignRight,
  CloudUpload,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import type { SelectChangeEvent } from '@mui/material';
import type { GiftCardFormData, LogoPosition } from './GiftCardTypes';
import {
  OCCASION_OPTIONS,
  COLOR_THEME_OPTIONS,
  BACKGROUND_TEMPLATES,
  MESSAGE_TEMPLATES,
  FONT_OPTIONS,
} from './GiftCardTypes';

interface Props {
  form: GiftCardFormData;
  onChange: (patch: Partial<GiftCardFormData>) => void;
}

export default function GiftCardBuilder({ form, onChange }: Props) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  // ─── Helpers ─────────────────────────────────────────────

  const handleSelect = (field: keyof GiftCardFormData) => (e: SelectChangeEvent) => {
    const val = e.target.value;
    onChange({ [field]: val });

    // When occasion changes, reset message to first template (if any)
    if (field === 'occasion') {
      const templates = MESSAGE_TEMPLATES[val] ?? [];
      onChange({ occasion: val, message: templates[0] ?? '' });
    }
  };

  const handleLogoUpload = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;
      const url = URL.createObjectURL(file);
      onChange({ logoFile: file, logoPreviewUrl: url, logoEnabled: true });
    },
    [onChange],
  );

  const handleRemoveLogo = useCallback(() => {
    if (form.logoPreviewUrl) URL.revokeObjectURL(form.logoPreviewUrl);
    onChange({ logoFile: null, logoPreviewUrl: '', logoEnabled: false });
  }, [form.logoPreviewUrl, onChange]);

  const templates = MESSAGE_TEMPLATES[form.occasion] ?? [];

  // ─── Render ──────────────────────────────────────────────

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5, p: 2 }}>
      {/* ── Occasion ──────────────── */}
      <FormControl size="small" fullWidth>
        <InputLabel>Occasion</InputLabel>
        <Select value={form.occasion} label="Occasion" onChange={handleSelect('occasion')}>
          {OCCASION_OPTIONS.map((o) => (
            <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>
          ))}
        </Select>
      </FormControl>

      {/* ── Color Theme ───────────── */}
      <FormControl size="small" fullWidth>
        <InputLabel>Color Theme</InputLabel>
        <Select value={form.colorTheme} label="Color Theme" onChange={handleSelect('colorTheme')}>
          {COLOR_THEME_OPTIONS.map((o) => (
            <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>
          ))}
        </Select>
      </FormControl>

      {/* ── Background Selector ───── */}
      <Box>
        <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
          Background Style
        </Typography>
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: 'repeat(4, 1fr)',
            gap: 1,
          }}
        >
          {BACKGROUND_TEMPLATES.map((t) => (
            <Box
              key={t.id}
              onClick={() => onChange({ backgroundId: t.id })}
              sx={{
                position: 'relative',
                aspectRatio: '5 / 7',
                borderRadius: 1,
                overflow: 'hidden',
                cursor: 'pointer',
                border: form.backgroundId === t.id
                  ? '3px solid'
                  : '2px solid transparent',
                borderColor: form.backgroundId === t.id
                  ? 'primary.main'
                  : 'transparent',
                transition: 'all 0.2s',
                '&:hover': { opacity: 0.85, transform: 'scale(1.03)' },
                background: t.gradient,
              }}
            >
              <Box
                component="img"
                src={t.image}
                alt={t.name}
                sx={{
                  position: 'absolute',
                  inset: 0,
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover',
                }}
                onError={(e: React.SyntheticEvent<HTMLImageElement>) => {
                  (e.target as HTMLImageElement).style.display = 'none';
                }}
              />
              {/* Label overlay */}
              <Box
                sx={{
                  position: 'absolute',
                  bottom: 0,
                  left: 0,
                  right: 0,
                  background: 'linear-gradient(transparent, rgba(0,0,0,0.45))',
                  p: 0.5,
                  pt: 1.5,
                }}
              >
                <Typography variant="caption" sx={{ fontSize: '0.55rem', lineHeight: 1.1, color: '#fff', fontWeight: 600 }}>
                  {t.name}
                </Typography>
              </Box>
            </Box>
          ))}
        </Box>
      </Box>

      {/* ── Message Template ──────── */}
      {templates.length > 0 && (
        <FormControl size="small" fullWidth>
          <InputLabel>Message Template</InputLabel>
          <Select
            value={templates.includes(form.message) ? form.message : ''}
            label="Message Template"
            onChange={(e) => onChange({ message: e.target.value })}
          >
            {templates.map((msg, i) => (
              <MenuItem key={i} value={msg}>
                {msg.length > 45 ? msg.slice(0, 45) + '…' : msg}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
      )}

      {/* ── Custom Message ────────── */}
      <TextField
        label="Message"
        multiline
        rows={3}
        size="small"
        fullWidth
        value={form.message}
        onChange={(e) => onChange({ message: e.target.value })}
        placeholder="Enter your custom message…"
      />

      {/* ── Sender Name ───────────── */}
      <TextField
        label="Sender Name"
        size="small"
        fullWidth
        value={form.senderName}
        onChange={(e) => onChange({ senderName: e.target.value })}
        placeholder="e.g., With love, Sarah"
      />

      {/* ── Font Controls ─────────── */}
      <Typography variant="subtitle2" sx={{ fontWeight: 600, mt: 0.5 }}>
        Font Controls
      </Typography>

      <FormControl size="small" fullWidth>
        <InputLabel>Font Family</InputLabel>
        <Select value={form.fontFamily} label="Font Family" onChange={handleSelect('fontFamily')}>
          {FONT_OPTIONS.map((f) => (
            <MenuItem key={f.value} value={f.value} sx={{ fontFamily: f.fontFamily }}>
              {f.label}
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      <Box>
        <Typography variant="caption" sx={{ color: 'text.secondary' }}>
          Font Size: {form.fontSize}px
        </Typography>
        <Slider
          value={form.fontSize}
          min={18}
          max={48}
          step={1}
          onChange={(_, v) => onChange({ fontSize: v as number })}
          size="small"
        />
      </Box>

      <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
        <TextField
          label="Font Color"
          type="color"
          size="small"
          value={form.fontColor}
          onChange={(e) => onChange({ fontColor: e.target.value })}
          sx={{ width: 100, '& input': { cursor: 'pointer', p: 0.5, height: 32 } }}
        />

        <ToggleButtonGroup
          size="small"
          exclusive
          value={form.textAlign}
          onChange={(_, v) => { if (v) onChange({ textAlign: v }); }}
        >
          <ToggleButton value="left"><FormatAlignLeft /></ToggleButton>
          <ToggleButton value="center"><FormatAlignCenter /></ToggleButton>
          <ToggleButton value="right"><FormatAlignRight /></ToggleButton>
        </ToggleButtonGroup>
      </Box>

      {/* ── Logo Upload ───────────── */}
      <Typography variant="subtitle2" sx={{ fontWeight: 600, mt: 0.5 }}>
        Logo
      </Typography>

      <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', flexWrap: 'wrap' }}>
        <Button
          variant="outlined"
          size="small"
          component="label"
          startIcon={<CloudUpload />}
        >
          Upload Logo
          <input type="file" hidden accept="image/*" onChange={handleLogoUpload} />
        </Button>

        {form.logoPreviewUrl && (
          <>
            <Box
              component="img"
              src={form.logoPreviewUrl}
              alt="Logo preview"
              sx={{ height: 40, borderRadius: 1, border: '1px solid', borderColor: 'divider' }}
            />
            <Button size="small" color="error" onClick={handleRemoveLogo} startIcon={<DeleteIcon />}>
              Remove
            </Button>
          </>
        )}
      </Box>

      {form.logoPreviewUrl && (
        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
          <FormControlLabel
            control={
              <Switch
                checked={form.logoEnabled}
                onChange={(e) => onChange({ logoEnabled: e.target.checked })}
                size="small"
              />
            }
            label="Show Logo"
          />

          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Position</InputLabel>
            <Select
              value={form.logoPosition}
              label="Position"
              onChange={(e) => onChange({ logoPosition: e.target.value as LogoPosition })}
            >
              <MenuItem value="top">Top</MenuItem>
              <MenuItem value="bottom">Bottom</MenuItem>
            </Select>
          </FormControl>
        </Box>
      )}
    </Box>
  );
}
