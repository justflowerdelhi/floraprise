/**
 * GiftCardBuilderModal.tsx — Modal wrapper for the Gift Card Builder
 *
 * Opens as a full-screen dialog from POS / Phone Order.
 * On save, returns the SavedGiftCard to the caller via `onSave`.
 */
import React, { useState, useRef, useCallback } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  IconButton,
  Snackbar,
  Alert,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import { Close, Download, Save } from '@mui/icons-material';
import { toPng } from 'html-to-image';
import GiftCardBuilder from './GiftCardBuilder';
import GiftCardPreview from './GiftCardPreview';
import type { GiftCardFormData, SavedGiftCard } from './GiftCardTypes';
import { INITIAL_FORM_DATA } from './GiftCardTypes';

interface Props {
  open: boolean;
  onClose: () => void;
  onSave: (card: SavedGiftCard) => void;
}

export default function GiftCardBuilderModal({ open, onClose, onSave }: Props) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const fullScreen = useMediaQuery(theme.breakpoints.down('md'));

  const [form, setForm] = useState<GiftCardFormData>({ ...INITIAL_FORM_DATA });
  const [snack, setSnack] = useState<string | null>(null);
  const previewRef = useRef<HTMLDivElement>(null);

  const patchForm = useCallback(
    (patch: Partial<GiftCardFormData>) => setForm((prev) => ({ ...prev, ...patch })),
    [],
  );

  // Reset form when dialog opens
  const handleEnter = () => setForm({ ...INITIAL_FORM_DATA });

  // ── Download ──────────────────────────────────────────────
  const handleDownload = useCallback(async () => {
    if (!previewRef.current) return;
    try {
      const dataUrl = await toPng(previewRef.current, { pixelRatio: 2 });
      const link = document.createElement('a');
      link.download = `gift-card-${Date.now()}.png`;
      link.href = dataUrl;
      link.click();
    } catch {
      setSnack('Failed to export image');
    }
  }, []);

  // ── Save & Attach ─────────────────────────────────────────
  const handleSave = useCallback(() => {
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
    onSave(saved);
    onClose();
  }, [form, onSave, onClose]);

  return (
    <>
      <Dialog
        open={open}
        onClose={onClose}
        maxWidth="lg"
        fullWidth
        fullScreen={fullScreen}
        TransitionProps={{ onEnter: handleEnter }}
        PaperProps={{
          sx: {
            height: fullScreen ? '100%' : '85vh',
            bgcolor: dk ? '#121212' : '#f8f9fa',
          },
        }}
      >
        <DialogTitle
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            fontWeight: 700,
            py: 1.5,
          }}
        >
          Gift Card Builder
          <IconButton onClick={onClose} size="small">
            <Close />
          </IconButton>
        </DialogTitle>

        <DialogContent dividers sx={{ p: 0 }}>
          <Box
            sx={{
              display: 'flex',
              height: '100%',
              overflow: 'hidden',
              flexDirection: fullScreen ? 'column' : 'row',
            }}
          >
            {/* ── Left: Designer ────── */}
            <Box
              sx={{
                flex: '0 0 380px',
                overflowY: 'auto',
                borderRight: fullScreen ? 'none' : '1px solid',
                borderBottom: fullScreen ? '1px solid' : 'none',
                borderColor: 'divider',
              }}
            >
              <GiftCardBuilder form={form} onChange={patchForm} />
            </Box>

            {/* ── Right: Preview ────── */}
            <Box
              sx={{
                flex: 1,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                p: 2,
                overflow: 'auto',
              }}
            >
              <GiftCardPreview ref={previewRef} form={form} />
            </Box>
          </Box>
        </DialogContent>

        <DialogActions sx={{ px: 3, py: 1.5 }}>
          <Button onClick={onClose}>Cancel</Button>
          <Button
            variant="outlined"
            startIcon={<Download />}
            onClick={handleDownload}
            disabled={!form.backgroundId}
          >
            Download
          </Button>
          <Button
            variant="contained"
            startIcon={<Save />}
            onClick={handleSave}
            disabled={!form.backgroundId || !form.message}
          >
            Save &amp; Attach to Order
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar
        open={!!snack}
        autoHideDuration={3000}
        onClose={() => setSnack(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        {snack ? (
          <Alert severity="error" onClose={() => setSnack(null)} variant="filled">
            {snack}
          </Alert>
        ) : undefined}
      </Snackbar>
    </>
  );
}
