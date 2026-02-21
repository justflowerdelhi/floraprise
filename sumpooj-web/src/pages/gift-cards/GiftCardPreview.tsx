/**
 * GiftCardPreview.tsx — Live 5×7 preview of the greeting card
 *
 * Renders the background template, centered message, sender name,
 * and optional logo inside a fixed 500×700 container.
 */
import React, { forwardRef } from 'react';
import { Box, Typography } from '@mui/material';
import type { GiftCardFormData } from './GiftCardTypes';
import {
  BACKGROUND_TEMPLATES,
  CARD_WIDTH,
  CARD_HEIGHT,
  FONT_OPTIONS,
} from './GiftCardTypes';

interface Props {
  form: GiftCardFormData;
}

const GiftCardPreview = forwardRef<HTMLDivElement, Props>(({ form }, ref) => {
  const bg = BACKGROUND_TEMPLATES.find((t) => t.id === form.backgroundId);
  const fontOpt = FONT_OPTIONS.find((f) => f.value === form.fontFamily);
  const fontFamily = fontOpt?.fontFamily ?? "'Playfair Display', Georgia, serif";

  return (
    <Box
      ref={ref}
      sx={{
        position: 'relative',
        width: CARD_WIDTH,
        height: CARD_HEIGHT,
        bgcolor: '#fff',
        boxShadow: '0 4px 24px rgba(0,0,0,0.15)',
        borderRadius: 2,
        overflow: 'hidden',
        flexShrink: 0,
        mx: 'auto',
      }}
    >
      {/* ── Background Image ────────── */}
      {bg && (
        <>
          {/* Gradient base (always visible) */}
          <Box
            sx={{
              position: 'absolute',
              inset: 0,
              background: bg.gradient,
            }}
          />
          {/* Photo overlay (covers gradient when loaded) */}
          <Box
            component="img"
            src={bg.image}
            alt={bg.name}
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
        </>
      )}

      {/* ── Fallback when no background ── */}
      {!bg && (
        <Box
          sx={{
            position: 'absolute',
            inset: 0,
            background: 'linear-gradient(135deg, #fce4ec 0%, #f3e5f5 50%, #e8eaf6 100%)',
          }}
        />
      )}

      {/* ── Logo (top) ────────────── */}
      {form.logoEnabled && form.logoPreviewUrl && form.logoPosition === 'top' && (
        <Box
          component="img"
          src={form.logoPreviewUrl}
          alt="Logo"
          sx={{
            position: 'absolute',
            top: 24,
            left: '50%',
            transform: 'translateX(-50%)',
            maxWidth: 120,
            maxHeight: 60,
            objectFit: 'contain',
            zIndex: 2,
          }}
        />
      )}

      {/* ── Center Text Block ────── */}
      <Box
        sx={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: '70%',
          textAlign: form.textAlign,
          zIndex: 2,
        }}
      >
        {form.message && (
          <Typography
            sx={{
              fontFamily,
              fontSize: form.fontSize,
              color: form.fontColor,
              lineHeight: 1.4,
              textShadow: '0 1px 4px rgba(0,0,0,0.3)',
              whiteSpace: 'pre-wrap',
              wordBreak: 'break-word',
            }}
          >
            {form.message}
          </Typography>
        )}

        {form.senderName && (
          <Typography
            sx={{
              fontFamily,
              fontSize: Math.max(14, form.fontSize * 0.55),
              color: form.fontColor,
              mt: 2,
              opacity: 0.85,
              textShadow: '0 1px 3px rgba(0,0,0,0.2)',
            }}
          >
            — {form.senderName}
          </Typography>
        )}
      </Box>

      {/* ── Logo (bottom) ─────────── */}
      {form.logoEnabled && form.logoPreviewUrl && form.logoPosition === 'bottom' && (
        <Box
          component="img"
          src={form.logoPreviewUrl}
          alt="Logo"
          sx={{
            position: 'absolute',
            bottom: 24,
            left: '50%',
            transform: 'translateX(-50%)',
            maxWidth: 120,
            maxHeight: 60,
            objectFit: 'contain',
            zIndex: 2,
          }}
        />
      )}
    </Box>
  );
});

GiftCardPreview.displayName = 'GiftCardPreview';

export default GiftCardPreview;
