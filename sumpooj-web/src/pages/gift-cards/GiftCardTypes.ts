/**
 * GiftCardTypes.ts — Types & Constants for Premium 5×7 Greeting Card Designer
 * Florist ERP SaaS
 *
 * Vertical 5×7 print-ready greeting card with AI-generated floral backgrounds.
 * Design prompt template emphasises: floral frame, soft border, clear center,
 * symmetry, luxury aesthetic, no text, high resolution.
 */

// ─── Card Dimensions ────────────────────────────────────────
// True 5×7 vertical ratio (5:7). Preview renders at 500×700 px.
// Download renders at 2× (1000×1400 px) for print quality.

export const CARD_WIDTH  = 500;
export const CARD_HEIGHT = 700;
export const CARD_ASPECT = '5 / 7';

// ─── Dropdown Option Types ──────────────────────────────────

export interface DropdownOption {
  value: string;
  label: string;
  emoji?: string;
}

// ─── Occasion Options ───────────────────────────────────────

export const OCCASION_OPTIONS: DropdownOption[] = [
  { value: 'birthday',       label: 'Birthday',              emoji: '🎂' },
  { value: 'anniversary',    label: 'Anniversary',           emoji: '💍' },
  { value: 'wedding',        label: 'Wedding',               emoji: '💒' },
  { value: 'valentines',     label: "Valentine's Day",       emoji: '❤️' },
  { value: 'mothers_day',    label: "Mother's Day",          emoji: '🌷' },
  { value: 'fathers_day',    label: "Father's Day",          emoji: '👔' },
  { value: 'get_well',       label: 'Get Well Soon',         emoji: '🏥' },
  { value: 'sympathy',       label: 'Sympathy',              emoji: '🕊️' },
  { value: 'congratulations',label: 'Congratulations',       emoji: '🎉' },
  { value: 'thank_you',      label: 'Thank You',             emoji: '🙏' },
  { value: 'baby_shower',    label: 'Baby Shower',           emoji: '👶' },
  { value: 'housewarming',   label: 'Housewarming',          emoji: '🏠' },
  { value: 'graduation',     label: 'Graduation',            emoji: '🎓' },
  { value: 'just_because',   label: 'Just Because',          emoji: '💐' },
];

// ─── Color Theme Options ────────────────────────────────────

export const COLOR_THEME_OPTIONS: DropdownOption[] = [
  { value: 'romantic_red',    label: 'Romantic Red',         emoji: '🔴' },
  { value: 'blush_pink',      label: 'Blush Pink',           emoji: '🩷' },
  { value: 'lavender_dream',  label: 'Lavender Dream',       emoji: '💜' },
  { value: 'golden_sunset',   label: 'Golden Sunset',        emoji: '🌅' },
  { value: 'ocean_blue',      label: 'Ocean Blue',           emoji: '🌊' },
  { value: 'sage_green',      label: 'Sage Green',           emoji: '🍃' },
  { value: 'ivory_white',     label: 'Ivory & White',        emoji: '🤍' },
  { value: 'peach_coral',     label: 'Peach Coral',          emoji: '🍑' },
  { value: 'midnight_navy',   label: 'Midnight Navy',        emoji: '🌙' },
  { value: 'earthy_terracotta',label: 'Earthy Terracotta',   emoji: '🏺' },
];

// ─── Floral Style Options ───────────────────────────────────

export const FLORAL_STYLE_OPTIONS: DropdownOption[] = [
  { value: 'classic_roses',     label: 'Classic Roses',        emoji: '🌹' },
  { value: 'wildflower_meadow', label: 'Wildflower Meadow',    emoji: '🌼' },
  { value: 'tropical_paradise', label: 'Tropical Paradise',    emoji: '🌺' },
  { value: 'garden_english',    label: 'English Garden',       emoji: '🏡' },
  { value: 'minimal_botanical', label: 'Minimal Botanical',    emoji: '🌿' },
  { value: 'japanese_ikebana',  label: 'Japanese Ikebana',     emoji: '🎋' },
  { value: 'vintage_peony',     label: 'Vintage Peony',        emoji: '🌸' },
  { value: 'succulent_modern',  label: 'Succulent Modern',     emoji: '🪴' },
  { value: 'sunflower_rustic',  label: 'Sunflower Rustic',     emoji: '🌻' },
  { value: 'orchid_luxury',     label: 'Orchid Luxury',        emoji: '💮' },
];

// ─── Font Options ───────────────────────────────────────────

export interface FontOption {
  value: string;
  label: string;
  fontFamily: string;
}

export const FONT_OPTIONS: FontOption[] = [
  { value: 'playfair',   label: 'Playfair Display', fontFamily: "'Playfair Display', Georgia, serif" },
  { value: 'great_vibes',label: 'Great Vibes',      fontFamily: "'Great Vibes', 'Dancing Script', cursive" },
  { value: 'cormorant',  label: 'Cormorant Garamond',fontFamily: "'Cormorant Garamond', 'Times New Roman', serif" },
  { value: 'lora',       label: 'Lora',             fontFamily: "'Lora', 'Georgia', serif" },
  { value: 'dancing',    label: 'Dancing Script',   fontFamily: "'Dancing Script', cursive" },
];

// ─── Gift Card Form State ───────────────────────────────────

export interface GiftCardFormData {
  occasion: string;
  colorTheme: string;
  floralStyle: string;
  message: string;
  senderName: string;
  fontChoice: string;
  textColor: string;
}

export const INITIAL_FORM_DATA: GiftCardFormData = {
  occasion: '',
  colorTheme: '',
  floralStyle: '',
  message: '',
  senderName: '',
  fontChoice: 'playfair',
  textColor: '#ffffff',
};

// ─── Mapped Floral Style Descriptions ───────────────────────
// Botanically-specific descriptions that anchor AI image generators to the
// correct flower species instead of producing generic mixed arrangements.

export const MAPPED_FLORAL_STYLES: Record<string, string> = {
  classic_roses:     'lush red and pink roses with layered velvety petals, rosebuds, and dark green foliage',
  wildflower_meadow: 'daisies, cornflowers, poppies, Queen Anne\'s lace, and wild grasses in a natural meadow arrangement',
  tropical_paradise: 'hibiscus, plumeria, bird of paradise, and tropical palm leaves with vivid saturated colors',
  garden_english:    'cottage garden mix of David Austin roses, foxgloves, delphiniums, sweet peas, and lavender sprigs',
  minimal_botanical: 'delicate eucalyptus branches, olive leaves, and fine fern fronds in a clean minimalist arrangement',
  japanese_ikebana:  'cherry blossoms (sakura), chrysanthemums, and bamboo in elegant asymmetric ikebana composition',
  vintage_peony:     'full-bloom peonies in blush, ivory, and dusty rose with soft ruffled petals and vintage botanical detail',
  succulent_modern:  'echeveria rosettes, aloe, and jade succulents with thick geometric leaves in muted sage and dusty tones',
  sunflower_rustic:  'large golden sunflowers with brown centers, wheat stalks, dried grasses, and burlap-textured rustic elements',
  orchid_luxury:     'phalaenopsis and cymbidium orchids with arching stems, aerial roots, and glossy tropical leaves',
};

// ─── AI Prompt Template ─────────────────────────────────────
// Frontend-side mirror of the backend GiftCardController prompt.
// Used in mock mode only. In production the backend builds the prompt;
// the frontend just sends the structured fields (occasion, theme, floralStyle).

export function buildDesignPrompt(
  occasion: string,
  theme: string,
  floralStyle: string,
): string {
  const themeLabel        = COLOR_THEME_OPTIONS.find((o) => o.value === theme)?.label ?? theme;
  const mappedFloralStyle = MAPPED_FLORAL_STYLES[floralStyle]
    ?? FLORAL_STYLE_OPTIONS.find((o) => o.value === floralStyle)?.label
    ?? floralStyle;

  return [
    'Create a premium vertical 5x7 greeting card design.',
    '',
    'The primary floral composition must prominently feature:',
    mappedFloralStyle,
    '',
    'The selected flower type must dominate the design.',
    'Do not substitute with generic mixed flowers.',
    '',
    'Color theme:',
    themeLabel,
    '',
    'Design rules:',
    `- Floral frame around edges using ${mappedFloralStyle}.`,
    '- Clear empty center space.',
    '- Luxury greeting card layout.',
    '- High detail botanical realism.',
    '- No text.',
    '- No watermark.',
    '- Vertical orientation.',
  ].join('\n');
}

// ─── API Types ──────────────────────────────────────────────
// In production the backend builds the prompt from these fields.
// The frontend does NOT send a prompt string.

export interface GenerateBackgroundRequest {
  occasion: string;
  theme: string;
  floralStyle: string;
}

export interface GenerateBackgroundResponse {
  backgroundImageUrl: string;
  generatedAt: string;
  prompt?: string; // Echo for debugging
}

// ─── Saved Gift Card ────────────────────────────────────────

export interface SavedGiftCard {
  id: string;
  occasion: string;
  colorTheme: string;
  floralStyle: string;
  message: string;
  senderName: string;
  backgroundImageUrl: string;
  fontChoice: string;
  textColor: string;
  attachedOrderId?: string;
  createdAt: string;
}

// ─── Premium Mock Background Images ─────────────────────────
// High-fidelity SVG data URIs simulating AI-generated premium greeting cards.
// Each features: floral frame, decorative border, clear center space, symmetry.

/**
 * Build a premium 5×7 SVG greeting card background.
 * - Outer decorative border with corner accents
 * - Floral frame wreath around the perimeter
 * - Radial-grad center clear space for message
 * - Balanced top/bottom symmetry
 */
const premiumSvg = (
  gradientColors: [string, string, string],
  borderColor: string,
  accentColor: string,
  floralElements: string,
) => {
  const [c1, c2, c3] = gradientColors;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="500" height="700" viewBox="0 0 500 700">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="${c1}"/>
      <stop offset="50%" stop-color="${c2}"/>
      <stop offset="100%" stop-color="${c3}"/>
    </linearGradient>
    <radialGradient id="center" cx="50%" cy="50%" r="40%">
      <stop offset="0%" stop-color="${c2}" stop-opacity="0.95"/>
      <stop offset="70%" stop-color="${c2}" stop-opacity="0.6"/>
      <stop offset="100%" stop-color="${c2}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="glow" cx="50%" cy="35%" r="50%">
      <stop offset="0%" stop-color="rgba(255,255,255,0.2)"/>
      <stop offset="100%" stop-color="rgba(255,255,255,0)"/>
    </radialGradient>
    <filter id="soft" x="-2%" y="-2%" width="104%" height="104%">
      <feGaussianBlur in="SourceGraphic" stdDeviation="1.5"/>
    </filter>
  </defs>

  <!-- Background gradient -->
  <rect width="500" height="700" fill="url(#bg)"/>
  <rect width="500" height="700" fill="url(#glow)"/>

  <!-- Outer decorative border (double rule) -->
  <rect x="12" y="12" width="476" height="676" rx="8" fill="none"
        stroke="${borderColor}" stroke-width="2" opacity="0.5"/>
  <rect x="20" y="20" width="460" height="660" rx="6" fill="none"
        stroke="${borderColor}" stroke-width="0.8" opacity="0.35"/>

  <!-- Corner accents (L-brackets) -->
  <g stroke="${accentColor}" stroke-width="1.5" fill="none" opacity="0.6">
    <path d="M30,50 L30,30 L50,30"/>
    <path d="M450,30 L470,30 L470,50"/>
    <path d="M30,650 L30,670 L50,670"/>
    <path d="M450,670 L470,670 L470,650"/>
  </g>

  <!-- Inner ornamental frame -->
  <rect x="40" y="45" width="420" height="610" rx="12" fill="none"
        stroke="${borderColor}" stroke-width="0.6" opacity="0.25"
        stroke-dasharray="4,6"/>

  <!-- Clear center space for message (radial fade) -->
  <rect x="60" y="180" width="380" height="340" rx="16" fill="url(#center)"/>

  <!-- Floral frame elements -->
  ${floralElements}

  <!-- Subtle texture overlay -->
  <rect width="500" height="700" fill="url(#glow)" opacity="0.3"/>
</svg>`;
  return `data:image/svg+xml;base64,${btoa(svg)}`;
};

// ── Floral frame patterns (balanced, symmetrical, frame-around-edges) ──

/** Rose wreath frame — clusters at corners + sprays along edges */
const roseFrame = (ac: string) => `
  <g opacity="0.22" filter="url(#soft)">
    <!-- Top-left rose cluster -->
    <circle cx="65" cy="70" r="28" fill="none" stroke="${ac}" stroke-width="1.8"/>
    <circle cx="65" cy="70" r="15" fill="none" stroke="${ac}" stroke-width="1.2"/>
    <circle cx="50" cy="55" r="18" fill="none" stroke="${ac}" stroke-width="1.2"/>
    <circle cx="85" cy="55" r="14" fill="none" stroke="${ac}" stroke-width="1"/>
    <path d="M95,70 Q120,50 140,55" fill="none" stroke="${ac}" stroke-width="1" opacity="0.7"/>
    <path d="M65,98 Q50,120 55,140" fill="none" stroke="${ac}" stroke-width="1" opacity="0.7"/>

    <!-- Top-right rose cluster -->
    <circle cx="435" cy="70" r="28" fill="none" stroke="${ac}" stroke-width="1.8"/>
    <circle cx="435" cy="70" r="15" fill="none" stroke="${ac}" stroke-width="1.2"/>
    <circle cx="450" cy="55" r="18" fill="none" stroke="${ac}" stroke-width="1.2"/>
    <circle cx="415" cy="55" r="14" fill="none" stroke="${ac}" stroke-width="1"/>
    <path d="M405,70 Q380,50 360,55" fill="none" stroke="${ac}" stroke-width="1" opacity="0.7"/>
    <path d="M435,98 Q450,120 445,140" fill="none" stroke="${ac}" stroke-width="1" opacity="0.7"/>

    <!-- Bottom-left rose cluster -->
    <circle cx="65" cy="630" r="28" fill="none" stroke="${ac}" stroke-width="1.8"/>
    <circle cx="65" cy="630" r="15" fill="none" stroke="${ac}" stroke-width="1.2"/>
    <circle cx="50" cy="645" r="18" fill="none" stroke="${ac}" stroke-width="1.2"/>
    <circle cx="85" cy="645" r="14" fill="none" stroke="${ac}" stroke-width="1"/>
    <path d="M95,630 Q120,650 140,645" fill="none" stroke="${ac}" stroke-width="1" opacity="0.7"/>
    <path d="M65,602 Q50,580 55,560" fill="none" stroke="${ac}" stroke-width="1" opacity="0.7"/>

    <!-- Bottom-right rose cluster -->
    <circle cx="435" cy="630" r="28" fill="none" stroke="${ac}" stroke-width="1.8"/>
    <circle cx="435" cy="630" r="15" fill="none" stroke="${ac}" stroke-width="1.2"/>
    <circle cx="450" cy="645" r="18" fill="none" stroke="${ac}" stroke-width="1.2"/>
    <circle cx="415" cy="645" r="14" fill="none" stroke="${ac}" stroke-width="1"/>
    <path d="M405,630 Q380,650 360,645" fill="none" stroke="${ac}" stroke-width="1" opacity="0.7"/>
    <path d="M435,602 Q450,580 445,560" fill="none" stroke="${ac}" stroke-width="1" opacity="0.7"/>
  </g>

  <!-- Top center garland -->
  <g opacity="0.16" filter="url(#soft)">
    <path d="M160,40 Q200,20 250,30 Q300,20 340,40" fill="none" stroke="${ac}" stroke-width="1.5"/>
    <circle cx="200" cy="30" r="10" fill="none" stroke="${ac}" stroke-width="0.8"/>
    <circle cx="250" cy="25" r="12" fill="none" stroke="${ac}" stroke-width="1"/>
    <circle cx="300" cy="30" r="10" fill="none" stroke="${ac}" stroke-width="0.8"/>
  </g>

  <!-- Bottom center garland -->
  <g opacity="0.16" filter="url(#soft)">
    <path d="M160,660 Q200,680 250,670 Q300,680 340,660" fill="none" stroke="${ac}" stroke-width="1.5"/>
    <circle cx="200" cy="670" r="10" fill="none" stroke="${ac}" stroke-width="0.8"/>
    <circle cx="250" cy="675" r="12" fill="none" stroke="${ac}" stroke-width="1"/>
    <circle cx="300" cy="670" r="10" fill="none" stroke="${ac}" stroke-width="0.8"/>
  </g>

  <!-- Side vine sprays -->
  <g opacity="0.12">
    <path d="M30,200 Q40,250 35,300 Q30,350 35,400 Q40,450 30,500"
          fill="none" stroke="${ac}" stroke-width="1.2"/>
    <path d="M470,200 Q460,250 465,300 Q470,350 465,400 Q460,450 470,500"
          fill="none" stroke="${ac}" stroke-width="1.2"/>
  </g>`;

/** Leaf & botanical frame — minimal elegant leaves at corners + edges */
const leafFrame = (ac: string) => `
  <g opacity="0.2" filter="url(#soft)">
    <!-- Top-left leaves -->
    <path d="M40,70 Q60,40 90,60 Q60,55 40,70Z" fill="${ac}" opacity="0.3"/>
    <path d="M55,45 Q80,20 105,45 Q80,35 55,45Z" fill="${ac}" opacity="0.25"/>
    <path d="M30,90 Q45,65 70,80 Q45,75 30,90Z" fill="${ac}" opacity="0.2"/>

    <!-- Top-right leaves (mirrored) -->
    <path d="M460,70 Q440,40 410,60 Q440,55 460,70Z" fill="${ac}" opacity="0.3"/>
    <path d="M445,45 Q420,20 395,45 Q420,35 445,45Z" fill="${ac}" opacity="0.25"/>
    <path d="M470,90 Q455,65 430,80 Q455,75 470,90Z" fill="${ac}" opacity="0.2"/>

    <!-- Bottom-left leaves -->
    <path d="M40,630 Q60,660 90,640 Q60,645 40,630Z" fill="${ac}" opacity="0.3"/>
    <path d="M55,655 Q80,680 105,655 Q80,665 55,655Z" fill="${ac}" opacity="0.25"/>
    <path d="M30,610 Q45,635 70,620 Q45,625 30,610Z" fill="${ac}" opacity="0.2"/>

    <!-- Bottom-right leaves (mirrored) -->
    <path d="M460,630 Q440,660 410,640 Q440,645 460,630Z" fill="${ac}" opacity="0.3"/>
    <path d="M445,655 Q420,680 395,655 Q420,665 445,655Z" fill="${ac}" opacity="0.25"/>
    <path d="M470,610 Q455,635 430,620 Q455,625 470,610Z" fill="${ac}" opacity="0.2"/>
  </g>

  <!-- Top-center botanical arc -->
  <g opacity="0.14" filter="url(#soft)">
    <path d="M150,50 Q180,25 210,35 Q230,15 250,25 Q270,15 290,35 Q320,25 350,50"
          fill="none" stroke="${ac}" stroke-width="1.5"/>
    <path d="M190,38 Q195,28 205,35" fill="${ac}" opacity="0.2"/>
    <path d="M290,38 Q295,28 305,35" fill="${ac}" opacity="0.2"/>
  </g>

  <!-- Bottom-center botanical arc -->
  <g opacity="0.14" filter="url(#soft)">
    <path d="M150,650 Q180,675 210,665 Q230,685 250,675 Q270,685 290,665 Q320,675 350,650"
          fill="none" stroke="${ac}" stroke-width="1.5"/>
    <path d="M190,662 Q195,672 205,665" fill="${ac}" opacity="0.2"/>
    <path d="M290,662 Q295,672 305,665" fill="${ac}" opacity="0.2"/>
  </g>

  <!-- Side stems with small leaves -->
  <g opacity="0.1">
    <path d="M28,180 Q38,220 32,260 Q28,300 33,340 Q38,380 28,420 Q28,460 33,500 Q38,540 28,560"
          fill="none" stroke="${ac}" stroke-width="1"/>
    <path d="M472,180 Q462,220 468,260 Q472,300 467,340 Q462,380 472,420 Q472,460 467,500 Q462,540 472,560"
          fill="none" stroke="${ac}" stroke-width="1"/>
    <!-- Tiny leaf pairs along left stem -->
    <path d="M28,250 Q18,240 22,230" fill="none" stroke="${ac}" stroke-width="0.8"/>
    <path d="M32,250 Q42,240 38,230" fill="none" stroke="${ac}" stroke-width="0.8"/>
    <path d="M28,400 Q18,390 22,380" fill="none" stroke="${ac}" stroke-width="0.8"/>
    <path d="M32,400 Q42,390 38,380" fill="none" stroke="${ac}" stroke-width="0.8"/>
    <!-- Tiny leaf pairs along right stem -->
    <path d="M472,250 Q482,240 478,230" fill="none" stroke="${ac}" stroke-width="0.8"/>
    <path d="M468,250 Q458,240 462,230" fill="none" stroke="${ac}" stroke-width="0.8"/>
    <path d="M472,400 Q482,390 478,380" fill="none" stroke="${ac}" stroke-width="0.8"/>
    <path d="M468,400 Q458,390 462,380" fill="none" stroke="${ac}" stroke-width="0.8"/>
  </g>`;

/** Petal & bloom frame — scattered petals + blossoms framing edges */
const petalFrame = (ac: string) => `
  <g opacity="0.18" filter="url(#soft)">
    <!-- Top-left bloom cluster -->
    <ellipse cx="70" cy="75" rx="22" ry="32" transform="rotate(-25 70 75)" fill="${ac}" opacity="0.2"/>
    <ellipse cx="55" cy="60" rx="16" ry="26" transform="rotate(-50 55 60)" fill="${ac}" opacity="0.15"/>
    <ellipse cx="90" cy="58" rx="14" ry="22" transform="rotate(10 90 58)" fill="${ac}" opacity="0.15"/>
    <circle cx="70" cy="72" r="8" fill="${ac}" opacity="0.25"/>

    <!-- Top-right bloom cluster -->
    <ellipse cx="430" cy="75" rx="22" ry="32" transform="rotate(25 430 75)" fill="${ac}" opacity="0.2"/>
    <ellipse cx="445" cy="60" rx="16" ry="26" transform="rotate(50 445 60)" fill="${ac}" opacity="0.15"/>
    <ellipse cx="410" cy="58" rx="14" ry="22" transform="rotate(-10 410 58)" fill="${ac}" opacity="0.15"/>
    <circle cx="430" cy="72" r="8" fill="${ac}" opacity="0.25"/>

    <!-- Bottom-left bloom cluster -->
    <ellipse cx="70" cy="625" rx="22" ry="32" transform="rotate(25 70 625)" fill="${ac}" opacity="0.2"/>
    <ellipse cx="55" cy="640" rx="16" ry="26" transform="rotate(50 55 640)" fill="${ac}" opacity="0.15"/>
    <ellipse cx="90" cy="642" rx="14" ry="22" transform="rotate(-10 90 642)" fill="${ac}" opacity="0.15"/>
    <circle cx="70" cy="628" r="8" fill="${ac}" opacity="0.25"/>

    <!-- Bottom-right bloom cluster -->
    <ellipse cx="430" cy="625" rx="22" ry="32" transform="rotate(-25 430 625)" fill="${ac}" opacity="0.2"/>
    <ellipse cx="445" cy="640" rx="16" ry="26" transform="rotate(-50 445 640)" fill="${ac}" opacity="0.15"/>
    <ellipse cx="410" cy="642" rx="14" ry="22" transform="rotate(10 410 642)" fill="${ac}" opacity="0.15"/>
    <circle cx="430" cy="628" r="8" fill="${ac}" opacity="0.25"/>
  </g>

  <!-- Top garland of petals -->
  <g opacity="0.12">
    <ellipse cx="180" cy="38" rx="12" ry="18" transform="rotate(-15 180 38)" fill="${ac}"/>
    <ellipse cx="220" cy="30" rx="10" ry="16" transform="rotate(10 220 30)" fill="${ac}"/>
    <ellipse cx="250" cy="26" rx="14" ry="20" transform="rotate(0 250 26)" fill="${ac}"/>
    <ellipse cx="280" cy="30" rx="10" ry="16" transform="rotate(-10 280 30)" fill="${ac}"/>
    <ellipse cx="320" cy="38" rx="12" ry="18" transform="rotate(15 320 38)" fill="${ac}"/>
  </g>

  <!-- Bottom garland of petals -->
  <g opacity="0.12">
    <ellipse cx="180" cy="662" rx="12" ry="18" transform="rotate(15 180 662)" fill="${ac}"/>
    <ellipse cx="220" cy="670" rx="10" ry="16" transform="rotate(-10 220 670)" fill="${ac}"/>
    <ellipse cx="250" cy="674" rx="14" ry="20" transform="rotate(0 250 674)" fill="${ac}"/>
    <ellipse cx="280" cy="670" rx="10" ry="16" transform="rotate(10 280 670)" fill="${ac}"/>
    <ellipse cx="320" cy="662" rx="12" ry="18" transform="rotate(-15 320 662)" fill="${ac}"/>
  </g>

  <!-- Loose petals floating along sides -->
  <g opacity="0.08">
    <ellipse cx="35" cy="220" rx="10" ry="16" transform="rotate(-30 35 220)" fill="${ac}"/>
    <ellipse cx="30" cy="380" rx="8" ry="14" transform="rotate(20 30 380)" fill="${ac}"/>
    <ellipse cx="35" cy="480" rx="10" ry="16" transform="rotate(-10 35 480)" fill="${ac}"/>
    <ellipse cx="465" cy="220" rx="10" ry="16" transform="rotate(30 465 220)" fill="${ac}"/>
    <ellipse cx="470" cy="380" rx="8" ry="14" transform="rotate(-20 470 380)" fill="${ac}"/>
    <ellipse cx="465" cy="480" rx="10" ry="16" transform="rotate(10 465 480)" fill="${ac}"/>
  </g>`;

// ── Theme configurations ────────────────────────────────────

interface ThemeConfig {
  gradient: [string, string, string];
  border: string;
  accent: string;
  frame: 'rose' | 'leaf' | 'petal';
}

const THEME_CONFIGS: Record<string, ThemeConfig> = {
  romantic_red:       { gradient: ['#7A0B0B', '#9B1B1B', '#C62828'], border: 'rgba(255,200,200,0.5)', accent: 'rgba(255,180,180,0.6)', frame: 'rose' },
  blush_pink:         { gradient: ['#F5C6D0', '#F0AAC0', '#E68FAE'], border: 'rgba(180,80,120,0.35)', accent: 'rgba(200,100,140,0.5)', frame: 'petal' },
  lavender_dream:     { gradient: ['#A888C8', '#8B6BAE', '#6A4C93'], border: 'rgba(220,200,255,0.45)', accent: 'rgba(200,180,240,0.5)', frame: 'petal' },
  golden_sunset:      { gradient: ['#F5D060', '#E8A317', '#C8860C'], border: 'rgba(255,240,180,0.5)', accent: 'rgba(200,160,60,0.5)', frame: 'leaf' },
  ocean_blue:         { gradient: ['#1565C0', '#1E88E5', '#42A5F5'], border: 'rgba(180,220,255,0.45)', accent: 'rgba(150,200,255,0.5)', frame: 'leaf' },
  sage_green:         { gradient: ['#5C8A5C', '#4A7C59', '#3A6B48'], border: 'rgba(180,220,180,0.45)', accent: 'rgba(160,210,160,0.5)', frame: 'leaf' },
  ivory_white:        { gradient: ['#FEFCF5', '#F5EDE0', '#EBE0CF'], border: 'rgba(180,160,130,0.4)', accent: 'rgba(160,140,110,0.4)', frame: 'rose' },
  peach_coral:        { gradient: ['#FFCCAC', '#FFAB91', '#FF8A65'], border: 'rgba(180,100,70,0.35)', accent: 'rgba(200,120,80,0.4)', frame: 'petal' },
  midnight_navy:      { gradient: ['#0A1628', '#152238', '#1E3050'], border: 'rgba(140,170,220,0.35)', accent: 'rgba(160,190,240,0.4)', frame: 'rose' },
  earthy_terracotta:  { gradient: ['#C07050', '#A0522D', '#8B4226'], border: 'rgba(230,190,160,0.45)', accent: 'rgba(220,180,140,0.5)', frame: 'leaf' },
};

function getFrame(type: 'rose' | 'leaf' | 'petal', accent: string): string {
  switch (type) {
    case 'rose':  return roseFrame(accent);
    case 'leaf':  return leafFrame(accent);
    case 'petal': return petalFrame(accent);
  }
}

export const MOCK_BACKGROUNDS: Record<string, string> = Object.fromEntries(
  Object.entries(THEME_CONFIGS).map(([key, cfg]) => [
    key,
    premiumSvg(cfg.gradient, cfg.border, cfg.accent, getFrame(cfg.frame, cfg.accent)),
  ]),
);

// Auto-contrast text color for each theme
export const THEME_TEXT_COLORS: Record<string, string> = {
  romantic_red:      '#FFEAEA',
  blush_pink:        '#4A0E2E',
  lavender_dream:    '#FFFFFF',
  golden_sunset:     '#3E2723',
  ocean_blue:        '#FFFFFF',
  sage_green:        '#FFFFFF',
  ivory_white:       '#3E2723',
  peach_coral:       '#3E2723',
  midnight_navy:     '#E8D5B7',
  earthy_terracotta: '#FFF8F0',
};
