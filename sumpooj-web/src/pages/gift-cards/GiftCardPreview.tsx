/**
 * GiftCardPreview.tsx — Premium 5×7 Greeting Card Live Preview
 *
 * Displays:
 * - Premium AI-generated floral background (500×700 — true 5:7 ratio)
 * - Soft decorative border with corner accents
 * - Floral frame around edges (part of background)
 * - Clear empty center space for custom message
 * - Elegant font with auto-contrast + text shadows
 * - Balanced & symmetrical luxury aesthetic
 * - Save / Attach to Order / Download actions (print-ready 2× resolution)
 */
import React, { useRef, useCallback, useState } from 'react';
import {
  Box, Typography, Button, useTheme, alpha, CircularProgress,
  Dialog, DialogTitle, DialogContent, DialogActions, TextField,
  Snackbar, Alert,
} from '@mui/material';
import {
  Download as DownloadIcon,
  Save as SaveIcon,
  AttachFile as AttachIcon,
} from '@mui/icons-material';
import { toPng } from 'html-to-image';
import type { GiftCardFormData, SavedGiftCard } from './GiftCardTypes';
import {
  FONT_OPTIONS, OCCASION_OPTIONS, COLOR_THEME_OPTIONS, FLORAL_STYLE_OPTIONS,
  CARD_WIDTH, CARD_HEIGHT,
} from './GiftCardTypes';

// ─── Props ──────────────────────────────────────────────────

interface GiftCardPreviewProps {
  form: GiftCardFormData;
  backgroundImageUrl: string | null;
  isGenerating: boolean;
  onSave: (card: SavedGiftCard) => void;
}

// ─── Component ──────────────────────────────────────────────

const GiftCardPreview: React.FC<GiftCardPreviewProps> = ({
  form, backgroundImageUrl, isGenerating, onSave,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const cardRef = useRef<HTMLDivElement>(null);

  const [isDownloading, setIsDownloading] = useState(false);
  const [attachDialogOpen, setAttachDialogOpen] = useState(false);
  const [attachOrderId, setAttachOrderId] = useState('');
  const [snackMsg, setSnackMsg] = useState('');

  // Resolve font family from fontChoice
  const selectedFont = FONT_OPTIONS.find((f) => f.value === form.fontChoice);
  const fontFamily = selectedFont?.fontFamily ?? "'Playfair Display', Georgia, serif";

  // Resolve labels for save metadata
  const occasionLabel = OCCASION_OPTIONS.find((o) => o.value === form.occasion)?.label ?? form.occasion;
  const themeLabel = COLOR_THEME_OPTIONS.find((o) => o.value === form.colorTheme)?.label ?? form.colorTheme;
  const styleLabel = FLORAL_STYLE_OPTIONS.find((o) => o.value === form.floralStyle)?.label ?? form.floralStyle;

  // ─── Download as PNG (print-ready 2×) ─────────────────────

  const handleDownload = useCallback(async () => {
    if (!cardRef.current) return;
    setIsDownloading(true);
    try {
      const dataUrl = await toPng(cardRef.current, {
        cacheBust: true,
        pixelRatio: 2, // 1000×1400 for print quality
        quality: 0.95,
        width: CARD_WIDTH,
        height: CARD_HEIGHT,
      });
      const link = document.createElement('a');
      link.download = `greeting-card-${form.occasion || 'custom'}-${Date.now()}.png`;
      link.href = dataUrl;
      link.click();
      setSnackMsg('Greeting card downloaded (high resolution)!');
    } catch (err) {
      console.error('Download failed:', err);
      setSnackMsg('Download failed — please try again');
    } finally {
      setIsDownloading(false);
    }
  }, [form.occasion]);

  // ─── Save Gift Card ──────────────────────────────────────

  const handleSave = useCallback(() => {
    if (!backgroundImageUrl) return;
    const saved: SavedGiftCard = {
      id: `gc_${Date.now()}`,
      occasion: form.occasion,
      colorTheme: form.colorTheme,
      floralStyle: form.floralStyle,
      message: form.message,
      senderName: form.senderName,
      backgroundImageUrl,
      fontChoice: form.fontChoice,
      textColor: form.textColor,
      createdAt: new Date().toISOString(),
    };
    onSave(saved);
    setSnackMsg('Gift card saved!');
  }, [form, backgroundImageUrl, onSave]);

  // ─── Attach to Order ──────────────────────────────────────

  const handleAttach = useCallback(() => {
    if (!backgroundImageUrl || !attachOrderId.trim()) return;
    const saved: SavedGiftCard = {
      id: `gc_${Date.now()}`,
      occasion: form.occasion,
      colorTheme: form.colorTheme,
      floralStyle: form.floralStyle,
      message: form.message,
      senderName: form.senderName,
      backgroundImageUrl,
      fontChoice: form.fontChoice,
      textColor: form.textColor,
      attachedOrderId: attachOrderId.trim(),
      createdAt: new Date().toISOString(),
    };
    onSave(saved);
    setAttachDialogOpen(false);
    setAttachOrderId('');
    setSnackMsg(`Gift card attached to order ${attachOrderId.trim()}`);
  }, [form, backgroundImageUrl, attachOrderId, onSave]);

  // ─── Empty State ──────────────────────────────────────────

  if (!backgroundImageUrl && !isGenerating) {
    return (
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100%',
          minHeight: CARD_HEIGHT,
          gap: 2.5,
          opacity: 0.5,
        }}
      >
        {/* Decorative card outline placeholder */}
        <Box
          sx={{
            width: CARD_WIDTH * 0.5,
            height: CARD_HEIGHT * 0.5,
            border: `2px dashed ${dk ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.12)'}`,
            borderRadius: 3,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 1.5,
            position: 'relative',
          }}
        >
          {/* Corner accents on placeholder */}
          <Box sx={{
            position: 'absolute', top: 8, left: 8, width: 16, height: 16,
            borderTop: `2px solid ${dk ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.15)'}`,
            borderLeft: `2px solid ${dk ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.15)'}`,
          }} />
          <Box sx={{
            position: 'absolute', top: 8, right: 8, width: 16, height: 16,
            borderTop: `2px solid ${dk ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.15)'}`,
            borderRight: `2px solid ${dk ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.15)'}`,
          }} />
          <Box sx={{
            position: 'absolute', bottom: 8, left: 8, width: 16, height: 16,
            borderBottom: `2px solid ${dk ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.15)'}`,
            borderLeft: `2px solid ${dk ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.15)'}`,
          }} />
          <Box sx={{
            position: 'absolute', bottom: 8, right: 8, width: 16, height: 16,
            borderBottom: `2px solid ${dk ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.15)'}`,
            borderRight: `2px solid ${dk ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.15)'}`,
          }} />

          <Typography sx={{ fontSize: '2.5rem', lineHeight: 1 }}>🌸</Typography>
          <Typography variant="subtitle1" sx={{ fontWeight: 700, fontFamily: "'Playfair Display', serif" }}>
            5×7 Greeting Card
          </Typography>
          <Typography variant="caption" sx={{ color: 'text.disabled', textAlign: 'center', maxWidth: 180, lineHeight: 1.4 }}>
            Configure your card design on the left and click <strong>Generate Background</strong>
          </Typography>
        </Box>

        <Typography variant="caption" sx={{ color: 'text.disabled', letterSpacing: '0.1em', textTransform: 'uppercase', fontSize: '0.65rem' }}>
          Premium Print-Ready Design
        </Typography>
      </Box>
    );
  }

  // ─── Loading State ────────────────────────────────────────

  if (isGenerating) {
    return (
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100%',
          minHeight: CARD_HEIGHT,
          gap: 2.5,
        }}
      >
        <Box sx={{ position: 'relative' }}>
          <CircularProgress size={72} thickness={2.5} sx={{ color: theme.palette.primary.main }} />
          <Box
            sx={{
              position: 'absolute',
              inset: 0,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Typography sx={{ fontSize: '1.8rem' }}>🌹</Typography>
          </Box>
        </Box>
        <Typography variant="h6" sx={{ fontWeight: 700, fontFamily: "'Playfair Display', serif" }}>
          Designing your greeting card…
        </Typography>
        <Typography variant="body2" sx={{ color: 'text.disabled', textAlign: 'center', maxWidth: 300 }}>
          Creating a premium {styleLabel} composition with floral frame, decorative border, and clear center space
        </Typography>
        <Typography variant="caption" sx={{ color: 'text.disabled', letterSpacing: '0.1em', textTransform: 'uppercase', fontSize: '0.6rem', mt: 1 }}>
          5×7 Vertical • Print-Ready • High Resolution
        </Typography>
      </Box>
    );
  }

  // ─── Premium Greeting Card Preview ─────────────────────────

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, py: 2 }}>
      {/* Card Info Bar */}
      <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', justifyContent: 'center', alignItems: 'center' }}>
        <Typography variant="caption" sx={{
          letterSpacing: '0.15em', textTransform: 'uppercase', fontSize: '0.6rem',
          color: dk ? 'rgba(255,255,255,0.35)' : 'text.disabled', mr: 1,
        }}>
          5×7 Premium
        </Typography>
        {[occasionLabel, themeLabel, styleLabel].filter(Boolean).map((tag) => (
          <Box
            key={tag}
            sx={{
              px: 1.5, py: 0.5,
              borderRadius: 10,
              bgcolor: alpha(theme.palette.primary.main, dk ? 0.2 : 0.08),
              color: theme.palette.primary.main,
              fontSize: '0.7rem',
              fontWeight: 600,
              letterSpacing: '0.02em',
            }}
          >
            {tag}
          </Box>
        ))}
      </Box>

      {/* ── The Premium 5×7 Greeting Card ── */}
      <Box
        ref={cardRef}
        sx={{
          position: 'relative',
          width: CARD_WIDTH,
          height: CARD_HEIGHT,
          borderRadius: '6px',
          overflow: 'hidden',
          flexShrink: 0,
          backgroundImage: `url(${backgroundImageUrl})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          // Premium shadow treatment
          boxShadow: dk
            ? `0 30px 80px rgba(0,0,0,0.7),
               0 8px 24px rgba(0,0,0,0.4),
               0 0 0 1px rgba(255,255,255,0.06),
               inset 0 0 0 1px rgba(255,255,255,0.04)`
            : `0 30px 80px rgba(0,0,0,0.12),
               0 8px 24px rgba(0,0,0,0.08),
               0 0 0 1px rgba(0,0,0,0.04)`,
          // Subtle paper texture effect
          '&::before': {
            content: '""',
            position: 'absolute',
            inset: 0,
            background: 'radial-gradient(ellipse at 50% 30%, rgba(255,255,255,0.08) 0%, transparent 60%)',
            pointerEvents: 'none',
            zIndex: 1,
          },
        }}
      >
        {/* Soft radial vignette for text readability in center */}
        <Box
          sx={{
            position: 'absolute',
            inset: 0,
            background: `radial-gradient(
              ellipse 55% 40% at 50% 50%,
              rgba(0,0,0,0.05) 0%,
              rgba(0,0,0,0.12) 60%,
              rgba(0,0,0,0.25) 100%
            )`,
            pointerEvents: 'none',
            zIndex: 2,
          }}
        />

        {/* ── Message content overlay (center space) ── */}
        <Box
          sx={{
            position: 'absolute',
            // Position within the clear center area (matching the radial-grad center in SVG)
            top: '26%',
            bottom: '26%',
            left: '12%',
            right: '12%',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            textAlign: 'center',
            zIndex: 3,
          }}
        >
          {/* Decorative top ornament */}
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1,
              mb: 2.5,
              opacity: 0.6,
            }}
          >
            <Box sx={{
              width: 40, height: '1px',
              background: `linear-gradient(to right, transparent, ${form.textColor})`,
              opacity: 0.5,
            }} />
            <Typography sx={{
              fontSize: '1.2rem',
              filter: 'drop-shadow(0 1px 3px rgba(0,0,0,0.3))',
              lineHeight: 1,
            }}>
              ✿
            </Typography>
            <Box sx={{
              width: 40, height: '1px',
              background: `linear-gradient(to left, transparent, ${form.textColor})`,
              opacity: 0.5,
            }} />
          </Box>

          {/* Message */}
          {form.message ? (
            <Typography
              sx={{
                fontFamily,
                fontSize: form.message.length > 100 ? '1.3rem' : '1.6rem',
                lineHeight: 1.7,
                color: form.textColor,
                textShadow: `
                  0 1px 6px rgba(0,0,0,0.35),
                  0 0 20px rgba(0,0,0,0.15)
                `,
                maxWidth: 360,
                wordBreak: 'break-word',
                whiteSpace: 'pre-line',
                letterSpacing: '0.01em',
              }}
            >
              {form.message}
            </Typography>
          ) : (
            <Typography
              sx={{
                fontFamily,
                fontSize: '1.3rem',
                color: form.textColor,
                opacity: 0.4,
                fontStyle: 'italic',
                textShadow: '0 1px 6px rgba(0,0,0,0.25)',
              }}
            >
              Your message here…
            </Typography>
          )}

          {/* Sender Name */}
          {form.senderName && (
            <Typography
              sx={{
                fontFamily,
                fontSize: '1rem',
                mt: 2.5,
                color: form.textColor,
                opacity: 0.8,
                textShadow: '0 1px 4px rgba(0,0,0,0.3)',
                fontStyle: 'italic',
                letterSpacing: '0.03em',
              }}
            >
              — {form.senderName}
            </Typography>
          )}

          {/* Decorative bottom ornament */}
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1,
              mt: 2.5,
              opacity: 0.6,
            }}
          >
            <Box sx={{
              width: 40, height: '1px',
              background: `linear-gradient(to right, transparent, ${form.textColor})`,
              opacity: 0.5,
            }} />
            <Typography sx={{
              fontSize: '1.2rem',
              filter: 'drop-shadow(0 1px 3px rgba(0,0,0,0.3))',
              lineHeight: 1,
              transform: 'rotate(180deg)',
            }}>
              ✿
            </Typography>
            <Box sx={{
              width: 40, height: '1px',
              background: `linear-gradient(to left, transparent, ${form.textColor})`,
              opacity: 0.5,
            }} />
          </Box>
        </Box>
      </Box>

      {/* Card dimensions label */}
      <Typography variant="caption" sx={{
        color: dk ? 'rgba(255,255,255,0.25)' : 'text.disabled',
        letterSpacing: '0.1em',
        textTransform: 'uppercase',
        fontSize: '0.6rem',
        mt: -1.5,
      }}>
        500 × 700 px • Downloads at 1000 × 1400 px
      </Typography>

      {/* ── Action Buttons ── */}
      <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap', justifyContent: 'center' }}>
        <Button
          variant="contained"
          color="primary"
          startIcon={<SaveIcon />}
          onClick={handleSave}
          sx={{
            fontWeight: 700, textTransform: 'none', px: 3, borderRadius: 2,
            background: 'linear-gradient(135deg, #7B4DB1 0%, #5B2E91 100%)',
            '&:hover': { background: 'linear-gradient(135deg, #8B5DC1 0%, #6B3EA1 100%)' },
          }}
        >
          Save Card
        </Button>

        <Button
          variant="outlined"
          color="secondary"
          startIcon={<AttachIcon />}
          onClick={() => setAttachDialogOpen(true)}
          sx={{ fontWeight: 700, textTransform: 'none', px: 3, borderRadius: 2 }}
        >
          Attach to Order
        </Button>

        <Button
          variant="outlined"
          startIcon={isDownloading ? <CircularProgress size={18} color="inherit" /> : <DownloadIcon />}
          disabled={isDownloading}
          onClick={handleDownload}
          sx={{ fontWeight: 700, textTransform: 'none', px: 3, borderRadius: 2 }}
        >
          {isDownloading ? 'Exporting…' : 'Download PNG'}
        </Button>
      </Box>

      {/* ── Attach to Order Dialog ── */}
      <Dialog
        open={attachDialogOpen}
        onClose={() => setAttachDialogOpen(false)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle sx={{ fontWeight: 700 }}>Attach Gift Card to Order</DialogTitle>
        <DialogContent>
          <Typography variant="body2" sx={{ mb: 2, color: 'text.secondary' }}>
            Enter the order number or ID to attach this gift card.
          </Typography>
          <TextField
            autoFocus
            fullWidth
            size="small"
            label="Order ID"
            placeholder="e.g. ORD-2026-0001"
            value={attachOrderId}
            onChange={(e) => setAttachOrderId(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAttachDialogOpen(false)} sx={{ textTransform: 'none' }}>
            Cancel
          </Button>
          <Button
            variant="contained"
            disabled={!attachOrderId.trim()}
            onClick={handleAttach}
            sx={{ fontWeight: 700, textTransform: 'none' }}
          >
            Attach
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={!!snackMsg}
        autoHideDuration={3000}
        onClose={() => setSnackMsg('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="success" variant="filled" onClose={() => setSnackMsg('')}>
          {snackMsg}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default GiftCardPreview;
