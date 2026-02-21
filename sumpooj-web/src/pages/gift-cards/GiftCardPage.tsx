/**
 * GiftCardPage.tsx — Full-page Gift Card Builder
 *
 * Two-panel layout: Designer (left, scrollable) + Live Preview (right, fixed).
 * Includes Download-as-Image and Save actions.
 */
import React, { useState, useRef, useCallback } from 'react';
import {
  Box,
  Typography,
  Button,
  Card,
  CardContent,
  Snackbar,
  Alert,
  useTheme,
} from '@mui/material';
import { Download, Save } from '@mui/icons-material';
import { toPng } from 'html-to-image';
import GiftCardBuilder from './GiftCardBuilder';
import GiftCardPreview from './GiftCardPreview';
import type { GiftCardFormData, SavedGiftCard } from './GiftCardTypes';
import { INITIAL_FORM_DATA } from './GiftCardTypes';

export default function GiftCardPage() {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const [form, setForm] = useState<GiftCardFormData>({ ...INITIAL_FORM_DATA });
  const [snack, setSnack] = useState<{ msg: string; severity: 'success' | 'error' } | null>(null);
  const previewRef = useRef<HTMLDivElement>(null);

  const patchForm = useCallback(
    (patch: Partial<GiftCardFormData>) => setForm((prev) => ({ ...prev, ...patch })),
    [],
  );

  // ── Download as Image ────────────────────────────────────
  const handleDownload = useCallback(async () => {
    if (!previewRef.current) return;
    try {
      const dataUrl = await toPng(previewRef.current, { pixelRatio: 2 });
      const link = document.createElement('a');
      link.download = `gift-card-${Date.now()}.png`;
      link.href = dataUrl;
      link.click();
      setSnack({ msg: 'Image downloaded!', severity: 'success' });
    } catch {
      setSnack({ msg: 'Failed to export image', severity: 'error' });
    }
  }, []);

  // ── Save ─────────────────────────────────────────────────
  const handleSave = useCallback((): SavedGiftCard => {
    const saved: SavedGiftCard = {
      id: `gc_${Date.now()}`,
      occasion: form.occasion,
      colorTheme: form.colorTheme,
      backgroundStyle: form.backgroundId,
      message: form.message,
      senderName: form.senderName,
      fontFamily: form.fontFamily,
      fontSize: form.fontSize,
      fontColor: form.fontColor,
      logoUrl: form.logoPreviewUrl,
      createdAt: new Date().toISOString(),
    };
    setSnack({ msg: `Gift card saved (${saved.id})`, severity: 'success' });
    return saved;
  }, [form]);

  // ── Layout ───────────────────────────────────────────────
  return (
    <Box
      sx={{
        display: 'flex',
        height: '100%',
        bgcolor: dk ? '#0f0f0f' : '#f8f9fa',
        gap: 2,
        p: 2,
        overflow: 'hidden',
      }}
    >
      {/* ── Left: Designer Form ──────── */}
      <Card
        sx={{
          flex: '0 0 380px',
          overflowY: 'auto',
          bgcolor: dk ? '#1a1a1a' : '#fff',
          borderRadius: 2,
        }}
      >
        <CardContent sx={{ p: 0 }}>
          <Typography
            variant="h6"
            sx={{ fontWeight: 700, px: 2, pt: 2, pb: 1 }}
          >
            Gift Card Designer
          </Typography>
          <GiftCardBuilder form={form} onChange={patchForm} />
        </CardContent>
      </Card>

      {/* ── Right: Preview + Actions ─── */}
      <Box
        sx={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 2,
          overflow: 'auto',
        }}
      >
        <GiftCardPreview ref={previewRef} form={form} />

        <Box sx={{ display: 'flex', gap: 1.5 }}>
          <Button
            variant="contained"
            startIcon={<Download />}
            onClick={handleDownload}
            disabled={!form.backgroundId}
          >
            Download as Image
          </Button>
          <Button
            variant="outlined"
            startIcon={<Save />}
            onClick={handleSave}
            disabled={!form.backgroundId || !form.message}
          >
            Save Card
          </Button>
        </Box>
      </Box>

      {/* ── Snackbar ─────────────────── */}
      <Snackbar
        open={!!snack}
        autoHideDuration={3000}
        onClose={() => setSnack(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        {snack ? (
          <Alert severity={snack.severity} onClose={() => setSnack(null)} variant="filled">
            {snack.msg}
          </Alert>
        ) : undefined}
      </Snackbar>
    </Box>
  );
}
