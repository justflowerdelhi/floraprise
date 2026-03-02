/**
 * gift-card.api.ts — Gift Cards API Service
 *
 * Endpoints:
 *   GET    /gift-cards/search
 *   GET    /gift-cards/:id
 *   DELETE /gift-cards/:id
 *   GET    /gift-cards/check-balance/:code
 *   POST   /gift-cards
 *   POST   /gift-cards/redeem
 *   POST   /gift-cards/:id/add-balance
 *   POST   /ai/giftcard/background
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface GiftCardSearchParams {
  Query?: string;
  Status?: string;
  MinBalance?: number;
  Page?: number;
  PageSize?: number;
}

export interface CreateGiftCardRequest {
  amount: number;
  recipientName?: string | null;
  recipientEmail?: string | null;
  recipientPhone?: string | null;
  senderName?: string | null;
  personalMessage?: string | null;
  designTheme?: string | null;
  expiresAt?: string | null;
}

export interface RedeemGiftCardRequest {
  code: string;
  amount: number;
  orderId?: string | null;
}

export interface AddBalanceRequest {
  amount: number;
}

export interface GenerateGiftCardBackgroundRequest {
  occasion: string;
  theme: string;
  floralStyle: string;
}

export interface AIUsageInfo {
  dailyUsed: number;
  dailyLimit: number;
  dailyRemaining: number;
  monthlyUsed: number;
  monthlyLimit: number;
  monthlyRemaining: number;
}

export interface GenerateGiftCardBackgroundResponse {
  imageUrl: string;
  prompt: string;
  usage: AIUsageInfo;
}

// ─── API Functions ──────────────────────────────────────────

export const searchGiftCards = async (params: GiftCardSearchParams = {}) => {
  const res = await api.get('/gift-cards/search', { params });
  return res.data;
};

export const getGiftCardById = async (id: string) => {
  const res = await api.get(`/gift-cards/${id}`);
  return res.data;
};

export const deleteGiftCard = async (id: string) => {
  const res = await api.delete(`/gift-cards/${id}`);
  return res.data;
};

export const checkGiftCardBalance = async (code: string) => {
  const res = await api.get(`/gift-cards/check-balance/${code}`);
  return res.data;
};

export const createGiftCard = async (data: CreateGiftCardRequest) => {
  const res = await api.post('/gift-cards', data);
  return res.data;
};

export const redeemGiftCard = async (data: RedeemGiftCardRequest) => {
  const res = await api.post('/gift-cards/redeem', data);
  return res.data;
};

export const addGiftCardBalance = async (id: string, data: AddBalanceRequest) => {
  const res = await api.post(`/gift-cards/${id}/add-balance`, data);
  return res.data;
};

export const generateGiftCardBackground = async (
  data: GenerateGiftCardBackgroundRequest
): Promise<GenerateGiftCardBackgroundResponse> => {
  const res = await api.post('/ai/giftcard/background', data);
  return res.data;
};

export const getAIGiftCardUsage = async (): Promise<AIUsageInfo> => {
  const res = await api.get('/ai/giftcard/usage');
  return res.data;
};
