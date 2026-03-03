export interface Product {
  id: string;
  name: string;
  slug: string;
  price: number;
  image: string;
  category: string;
  stock: number;
  isBestSeller: boolean;
  salesCount?: number; // reserved for analytics
  createdAt: string; // used to sort New Arrivals
}

export const products: Product[] = [
  {
    id: "1",
    name: "Colorful Pipe Cleaners - Mixed Shades (100 pcs)",
    slug: "pipe-cleaners-mixed-100",
    price: 149,
    image: "/products/pipecleaner.jpg",
    category: "pipecleaners",
    stock: 50,
    isBestSeller: true,
    salesCount: 120,
    createdAt: "2026-03-01",
  },
  {
    id: "2",
    name: "Birthday Balloon Decoration Set",
    slug: "birthday-balloon-set",
    price: 299,
    image: "/products/balloons.jpg",
    category: "birthday-supplies",
    stock: 40,
    isBestSeller: true,
    salesCount: 90,
    createdAt: "2026-03-02",
  },
  {
    id: "3",
    name: "Premium Gift Wrap Paper Pack (10 sheets)",
    slug: "gift-wrap-pack-10",
    price: 199,
    image: "/products/giftwrap.jpg",
    category: "gift-packaging",
    stock: 30,
    isBestSeller: false,
    salesCount: 30,
    createdAt: "2026-03-03",
  },
  {
    id: "4",
    name: "DIY Art & Craft Starter Kit",
    slug: "diy-craft-kit",
    price: 349,
    image: "/products/diykit.jpg",
    category: "art-craft",
    stock: 25,
    isBestSeller: false,
    salesCount: 10,
    createdAt: "2026-03-04",
  },
];