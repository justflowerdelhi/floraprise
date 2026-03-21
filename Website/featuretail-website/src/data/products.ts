type Category =
  | string
  | {
      slug?: string;
    };

export interface Product {
  id: string;
  name: string;
  slug: string;
  price: number;
  images: (string | { url: string })[];
  category?: Category;
  stock: number;
  tags?: string[];
  createdAt: string;
  description: string;
  features?: string[];
}

export const products: Product[] = [
  {
    id: "1",
    name: "Colorful Pipe Cleaners - Mixed Shades",
    slug: "pipe-cleaners-mixed",
    price: 149,
    images: ["/products/pipecleaner.jpg"],
    category: "pipecleaners",
    stock: 50,
    tags: ["home", "best-seller"],
    createdAt: "2026-03-01",
    description:
      "High-quality colorful pipe cleaners perfect for DIY crafts, school projects, decorations and creative art activities.",
    features: [
      "Soft and flexible material",
      "Bright mixed colors",
      "Ideal for school projects",
      "Pack of 100 pieces",
    ],
  },
  {
    id: "2",
    name: "Birthday Balloon Decoration Set",
    slug: "birthday-balloon-set",
    price: 299,
    images: ["/products/balloons.jpg"],
    category: "birthday-supplies",
    stock: 40,
    tags: ["best-seller"],
    createdAt: "2026-03-02",
    description: "Complete birthday balloon decoration set for quick and colorful party setups.",
    features: [
      "Assorted balloons and ribbons",
      "Easy setup for home parties",
      "Bright festive colors",
      "Great for birthdays and events",
    ],
  },
  {
    id: "3",
    name: "Premium Gift Wrap Paper Pack",
    slug: "gift-wrap-pack",
    price: 199,
    images: ["/products/giftwrap.jpg"],
    category: "gift-packaging",
    stock: 30,
    tags: ["new", "home"],
    createdAt: "2026-03-03",
    description: "Premium gift wrap paper pack to elevate the look of your presents.",
    features: [
      "High-quality finish",
      "Multiple designs",
      "Vibrant prints",
      "Tear-resistant paper",
    ],
  },
  {
    id: "4",
    name: "DIY Craft Starter Kit",
    slug: "diy-craft-kit",
    price: 349,
    images: ["/products/diykit.jpg"],
    category: "art-craft",
    stock: 25,
    tags: ["new"],
    createdAt: "2026-03-04",
    description: "DIY craft starter kit with essential tools and materials for beginners and hobbyists.",
    features: [
      "Curated assortment of tools",
      "Beginner-friendly materials",
      "Great for gifting",
      "Includes idea inspirations",
    ],
  },
];