/**
 * Smart Bouquet Name Generator
 * Generates florist-friendly names based on selected flowers
 */

interface BouquetComponent {
  productName: string;
  quantity: number;
}

export const generateBouquetName = (components: BouquetComponent[]) => {
  if (!components.length) return "Custom Bouquet";

  // Sort by quantity (largest first)
  const sorted = [...components].sort((a, b) => b.quantity - a.quantity);

  const main = sorted[0];
  const second = sorted[1];

  // Example: "10 Red Rose Bouquet"
  if (!second) {
    return `${main.quantity} ${main.productName} Bouquet`;
  }

  // Example: "Red Rose & Lily Bouquet"
  if (sorted.length === 2) {
    return `${main.productName} & ${second.productName} Bouquet`;
  }

  // Example: "Mixed Rose Bouquet"
  return `Mixed ${main.productName} Bouquet`;
};
