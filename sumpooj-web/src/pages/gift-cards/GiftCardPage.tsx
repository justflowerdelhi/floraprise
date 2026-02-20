/**
 * GiftCardPage.tsx — AI Floral Background Generator for Gift Card Module
 * Florist ERP SaaS
 *
 * Two-panel layout:
 *   Left  — Form (GiftCardDesigner)
 *   Right — Preview (GiftCardPreview)
 */
import React, { useState, useCallback } from 'react';
import { Box, useTheme } from '@mui/material';
import type { GiftCardFormData, SavedGiftCard } from './GiftCardTypes';
import { INITIAL_FORM_DATA } from './GiftCardTypes';
import { generateBackground } from './giftCardApi';
import GiftCardDesigner from './GiftCardDesigner';
import GiftCardPreview from './GiftCardPreview';

const GiftCardPage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bgColor = dk ? '#0f0f0f' : '#f8f9fa';

  // ─── State ────────────────────────────────────────────────

  const [form, setForm] = useState<GiftCardFormData>({ ...INITIAL_FORM_DATA });
  const [isGenerating, setIsGenerating] = useState(false);
  const [backgroundImageUrl, setBackgroundImageUrl] = useState<string | null>(null);
  const [savedCards, setSavedCards] = useState<SavedGiftCard[]>([]);

  // ─── Form Change Handler ──────────────────────────────────

  const handleFieldChange = useCallback(
    (field: keyof GiftCardFormData, value: string) => {
      setForm((prev) => ({ ...prev, [field]: value }));
    },
    [],
  );

  // ─── Generate Background ──────────────────────────────────

  const handleGenerate = useCallback(async () => {
    if (!form.occasion || !form.colorTheme || !form.floralStyle) return;

    setIsGenerating(true);
    try {
      const result = await generateBackground({
        occasion: form.occasion,
        theme: form.colorTheme,
        floralStyle: form.floralStyle,
      });
      setBackgroundImageUrl(result.backgroundImageUrl);
    } catch (err) {
      console.error('Failed to generate background:', err);
    } finally {
      setIsGenerating(false);
    }
  }, [form.occasion, form.colorTheme, form.floralStyle]);

  // ─── Save Handler ─────────────────────────────────────────

  const handleSave = useCallback((card: SavedGiftCard) => {
    setSavedCards((prev) => [card, ...prev]);
    console.log('💾 Gift Card saved:', card);
    // In production, POST to backend or attach to order in context
  }, []);

  // ─── Render ───────────────────────────────────────────────

  return (
    <Box
      sx={{
        display: 'flex',
        height: '100vh',
        bgcolor: bgColor,
        overflow: 'hidden',
      }}
    >
      {/* Left Panel — Designer Form */}
      <Box
        sx={{
          width: 400,
          minWidth: 360,
          maxWidth: 440,
          borderRight: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          bgcolor: dk ? '#121212' : '#ffffff',
          overflow: 'auto',
          flexShrink: 0,
        }}
      >
        <GiftCardDesigner
          form={form}
          onChange={handleFieldChange}
          onGenerate={handleGenerate}
          isGenerating={isGenerating}
          hasBackground={!!backgroundImageUrl}
        />
      </Box>

      {/* Right Panel — Preview */}
      <Box
        sx={{
          flex: 1,
          overflow: 'auto',
          display: 'flex',
          alignItems: 'flex-start',
          justifyContent: 'center',
          p: 3,
        }}
      >
        <GiftCardPreview
          form={form}
          backgroundImageUrl={backgroundImageUrl}
          isGenerating={isGenerating}
          onSave={handleSave}
        />
      </Box>
    </Box>
  );
};

export default GiftCardPage;
