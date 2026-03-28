/**
 * Smart Bouquet Name Generator
 * Generates florist-friendly names based on selected flowers
 */

interface BouquetComponent {
  productName: string;
  quantity: number;
}

export const generateBouquetName = (components: BouquetComponent[]) => {
  const stamp = new Date().toISOString().slice(11, 16).replace(':', '');
  if (!components.length) return `Custom Bouquet ${stamp}`;

  // Sort by quantity (largest first)
  const sorted = [...components].sort((a, b) => b.quantity - a.quantity);

  const main = sorted[0];
  const second = sorted[1];

  // Example: "10 Red Rose Bouquet"
  if (!second) {
    return `${main.quantity} ${main.productName} Bouquet ${stamp}`;
  }

  // Example: "Red Rose & Lily Bouquet"
  if (sorted.length === 2) {
    return `${main.quantity} ${main.productName} + ${second.productName} ${stamp}`;
  }

  // Example: "Mixed Rose Bouquet"
  return `${main.quantity} ${main.productName} Mixed Bouquet ${stamp}`;
};
