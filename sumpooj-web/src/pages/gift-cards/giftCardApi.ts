/**
 * giftCardApi.ts — API service for Premium 5×7 Greeting Card Background Generation
 * Florist ERP SaaS
 *
 * In production: POST /ai/giftcard/background with structured fields only.
 *   The backend (GiftCardController) builds the image-generation prompt.
 * In dev/mock: returns premium SVG backgrounds after a simulated delay.
 */

import api from '../../api/axios';
import type { GenerateBackgroundRequest, GenerateBackgroundResponse } from './GiftCardTypes';
import { MOCK_BACKGROUNDS, buildDesignPrompt } from './GiftCardTypes';

const IS_MOCK = !import.meta.env.VITE_AI_BACKEND_URL;

/**
 * Generate a premium floral greeting card background.
 *
 * Production — sends { occasion, theme, floralStyle } to the backend;
 *   the backend resolves the mapped floral description and builds the prompt.
 * Mock — uses the frontend-side buildDesignPrompt() mirror for debugging.
 */
export async function generateBackground(
  payload: GenerateBackgroundRequest,
): Promise<GenerateBackgroundResponse> {
  if (IS_MOCK) {
    // Simulate network latency (1.5–3s)
    await new Promise((r) => setTimeout(r, 1500 + Math.random() * 1500));

    const bgUrl = MOCK_BACKGROUNDS[payload.theme] ?? MOCK_BACKGROUNDS['romantic_red'];

    return {
      backgroundImageUrl: bgUrl,
      generatedAt: new Date().toISOString(),
      prompt: buildDesignPrompt(payload.occasion, payload.theme, payload.floralStyle),
    };
  }

  // Production — backend builds the prompt from the structured fields
  const { data } = await api.post<GenerateBackgroundResponse>(
    '/ai/giftcard/background',
    payload,
  );
  return data;
}
