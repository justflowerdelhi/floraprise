export interface PosDiscountRules {
  maxDiscountPercent: number;
  maxDiscountAmount: number;
}

const DEFAULT_MAX_PERCENT = Number(import.meta.env.VITE_POS_MAX_DISCOUNT_PERCENT ?? 30);
const DEFAULT_MAX_AMOUNT = Number(import.meta.env.VITE_POS_MAX_DISCOUNT_AMOUNT ?? 5000);

const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

function getStorageKey(tenantId?: string): string {
  return `pos-discount-rules:${tenantId ?? 'default'}`;
}

export function getDefaultPosDiscountRules(): PosDiscountRules {
  return {
    maxDiscountPercent: clamp(Number.isFinite(DEFAULT_MAX_PERCENT) ? DEFAULT_MAX_PERCENT : 30, 0, 100),
    maxDiscountAmount: clamp(Number.isFinite(DEFAULT_MAX_AMOUNT) ? DEFAULT_MAX_AMOUNT : 5000, 0, 1_000_000),
  };
}

export function getPosDiscountRules(tenantId?: string): PosDiscountRules {
  const defaults = getDefaultPosDiscountRules();
  try {
    const raw = localStorage.getItem(getStorageKey(tenantId));
    if (!raw) return defaults;
    const parsed = JSON.parse(raw) as Partial<PosDiscountRules>;
    return {
      maxDiscountPercent: clamp(Number(parsed.maxDiscountPercent ?? defaults.maxDiscountPercent), 0, 100),
      maxDiscountAmount: clamp(Number(parsed.maxDiscountAmount ?? defaults.maxDiscountAmount), 0, 1_000_000),
    };
  } catch {
    return defaults;
  }
}

export function savePosDiscountRules(rules: PosDiscountRules, tenantId?: string): PosDiscountRules {
  const sanitized: PosDiscountRules = {
    maxDiscountPercent: clamp(Number(rules.maxDiscountPercent), 0, 100),
    maxDiscountAmount: clamp(Number(rules.maxDiscountAmount), 0, 1_000_000),
  };
  localStorage.setItem(getStorageKey(tenantId), JSON.stringify(sanitized));
  return sanitized;
}
