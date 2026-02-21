/**
 * GiftCardTypes.ts — Types & Constants for Gift Card Builder Module
 * Static background templates, message templates, font options, and form state.
 */

// ─── Background Templates ───────────────────────────────────

export interface BackgroundTemplate {
  id: string;
  name: string;
  image: string;
  /** CSS gradient used as visible background (always shown; image overlays if present) */
  gradient: string;
}

export const BACKGROUND_TEMPLATES: BackgroundTemplate[] = [
  {
    id: 'rose-light',
    name: 'Classic Rose Frame',
    image: '/gift-cards/backgrounds/frame-rose-light.jpg',
    gradient: 'linear-gradient(160deg, #fce4ec 0%, #f8bbd0 40%, #f48fb1 70%, #fce4ec 100%)',
  },
  {
    id: 'gold-elegant',
    name: 'Gold Elegant Frame',
    image: '/gift-cards/backgrounds/frame-gold-elegant.jpg',
    gradient: 'linear-gradient(145deg, #fffde7 0%, #fff9c4 30%, #ffe082 65%, #ffd54f 100%)',
  },
  {
    id: 'corner-floral',
    name: 'Corner Floral Light',
    image: '/gift-cards/backgrounds/frame-corner-floral.jpg',
    gradient: 'linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 35%, #a5d6a7 70%, #e8f5e9 100%)',
  },
  {
    id: 'watercolor-soft',
    name: 'Soft Watercolor',
    image: '/gift-cards/backgrounds/frame-watercolor-soft.jpg',
    gradient: 'linear-gradient(150deg, #e3f2fd 0%, #bbdefb 30%, #e1bee7 65%, #f3e5f5 100%)',
  },
  {
    id: 'modern-minimal',
    name: 'Modern Minimal Floral',
    image: '/gift-cards/backgrounds/frame-modern-minimal.jpg',
    gradient: 'linear-gradient(170deg, #fafafa 0%, #f5f5f5 30%, #e0e0e0 60%, #f5f5f5 100%)',
  },
  {
    id: 'rustic-garden',
    name: 'Rustic Garden Frame',
    image: '/gift-cards/backgrounds/frame-rustic-garden.jpg',
    gradient: 'linear-gradient(140deg, #efebe9 0%, #d7ccc8 35%, #bcaaa4 65%, #efebe9 100%)',
  },
  {
    id: 'peach-blush',
    name: 'Peach Blush Frame',
    image: '/gift-cards/backgrounds/frame-peach-blush.jpg',
    gradient: 'linear-gradient(155deg, #fff3e0 0%, #ffe0b2 30%, #ffcc80 60%, #fff3e0 100%)',
  },
  {
    id: 'lavender-soft',
    name: 'Lavender Soft Frame',
    image: '/gift-cards/backgrounds/frame-lavender-soft.jpg',
    gradient: 'linear-gradient(135deg, #f3e5f5 0%, #e1bee7 35%, #ce93d8 65%, #f3e5f5 100%)',
  },
];

// ─── Card Dimensions ────────────────────────────────────────

export const CARD_WIDTH  = 500;
export const CARD_HEIGHT = 700;

// ─── Dropdown Option Types ──────────────────────────────────

export interface DropdownOption {
  value: string;
  label: string;
}

// ─── Occasion Options ───────────────────────────────────────

export const OCCASION_OPTIONS: DropdownOption[] = [
  { value: 'birthday',        label: 'Birthday' },
  { value: 'anniversary',     label: 'Anniversary' },
  { value: 'sympathy',        label: 'Sympathy' },
  { value: 'wedding',         label: 'Wedding' },
  { value: 'thank_you',       label: 'Thank You' },
  { value: 'love',            label: 'Love' },
  { value: 'congratulations', label: 'Congratulations' },
  { value: 'new_baby',        label: 'New Baby' },
  { value: 'get_well',        label: 'Get Well' },
  { value: 'custom',          label: 'Custom' },
];

// ─── Color Theme Options ────────────────────────────────────

export const COLOR_THEME_OPTIONS: DropdownOption[] = [
  { value: 'soft_pink',       label: 'Soft Pink' },
  { value: 'white_gold',      label: 'White Gold' },
  { value: 'red_romantic',    label: 'Red Romantic' },
  { value: 'lavender_pastel', label: 'Lavender Pastel' },
  { value: 'blue_elegant',    label: 'Blue Elegant' },
  { value: 'peach_blush',     label: 'Peach Blush' },
  { value: 'green_natural',   label: 'Green Natural' },
  { value: 'black_gold',      label: 'Black Gold' },
];

// ─── Message Templates ──────────────────────────────────────

export const MESSAGE_TEMPLATES: Record<string, string[]> = {
  birthday: [
    'Wishing you a day as beautiful as flowers.',
    'May your birthday bloom with happiness.',
    'Another year of wonderful memories. Happy Birthday!',
    'Sending you sunshine and petals on your special day.',
  ],
  anniversary: [
    'Celebrating your love that grows stronger every year.',
    'Together is a beautiful place to be. Happy Anniversary!',
    'Your love story is one for the ages.',
    'Cheers to another chapter of happily ever after.',
  ],
  sympathy: [
    'With heartfelt sympathy and deepest condolences.',
    'Thinking of you during this difficult time.',
    'Wishing you peace and comfort.',
    'In loving memory — forever in our hearts.',
  ],
  wedding: [
    'Wishing you a lifetime of love and happiness.',
    'To a beautiful beginning together.',
    'May your marriage be as lovely as the flowers around you.',
    'Two hearts, one love. Congratulations!',
  ],
  thank_you: [
    'Thank you for brightening my world.',
    'Your kindness means more than words can say.',
    'Grateful for you and all you do.',
    'Thank you — you are truly appreciated.',
  ],
  love: [
    'You are the best thing that has ever happened to me.',
    'My love for you blooms every day.',
    'Forever yours, in every season.',
    'You make my heart bloom.',
  ],
  congratulations: [
    'Congratulations on this wonderful achievement!',
    'So proud of you — you deserve every bit of this!',
    'Hip hip hooray! What amazing news!',
    'Well done — the sky is the limit!',
  ],
  new_baby: [
    'Welcome to the world, little one!',
    'Tiny fingers, tiny toes — a bundle of joy!',
    'Congratulations on your new arrival!',
    'A new petal in the family garden.',
  ],
  get_well: [
    'Wishing you a speedy recovery.',
    'Sending healing thoughts and warm wishes.',
    'Get well soon — the world needs your smile.',
    'Rest, recover, and bloom again.',
  ],
  custom: [],
};

// ─── Font Options ───────────────────────────────────────────

export interface FontOption {
  value: string;
  label: string;
  fontFamily: string;
}

export const FONT_OPTIONS: FontOption[] = [
  { value: 'playfair',   label: 'Playfair Display',    fontFamily: "'Playfair Display', Georgia, serif" },
  { value: 'great_vibes', label: 'Great Vibes',         fontFamily: "'Great Vibes', 'Dancing Script', cursive" },
  { value: 'lora',       label: 'Lora',                fontFamily: "'Lora', Georgia, serif" },
  { value: 'montserrat', label: 'Montserrat',           fontFamily: "'Montserrat', 'Helvetica Neue', sans-serif" },
  { value: 'cormorant',  label: 'Cormorant Garamond',  fontFamily: "'Cormorant Garamond', 'Times New Roman', serif" },
];

// ─── Logo Position ──────────────────────────────────────────

export type LogoPosition = 'top' | 'bottom';

// ─── Gift Card Form State ───────────────────────────────────

export interface GiftCardFormData {
  occasion: string;
  colorTheme: string;
  backgroundId: string;
  message: string;
  senderName: string;
  fontFamily: string;
  fontSize: number;
  fontColor: string;
  textAlign: 'left' | 'center' | 'right';
  logoFile: File | null;
  logoPreviewUrl: string;
  logoPosition: LogoPosition;
  logoEnabled: boolean;
}

export const INITIAL_FORM_DATA: GiftCardFormData = {
  occasion: '',
  colorTheme: '',
  backgroundId: '',
  message: '',
  senderName: '',
  fontFamily: 'playfair',
  fontSize: 28,
  fontColor: '#ffffff',
  textAlign: 'center',
  logoFile: null,
  logoPreviewUrl: '',
  logoPosition: 'top',
  logoEnabled: false,
};

// ─── Saved Gift Card Object ─────────────────────────────────

export interface SavedGiftCard {
  id: string;
  occasion: string;
  colorTheme: string;
  backgroundStyle: string;
  message: string;
  senderName: string;
  fontFamily: string;
  fontSize: number;
  fontColor: string;
  logoUrl: string;
  createdAt: string;
}
