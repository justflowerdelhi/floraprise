export interface Category {
  id: string;
  name: string;
  slug: string;
  subcategories?: {
    id: string;
    name: string;
    slug: string;
  }[];
}

export const categories: Category[] = [
  {
    id: "1",
    name: "Art & Craft",
    slug: "art-craft",
    subcategories: [
      { id: "1-1", name: "DIY Kits", slug: "diy-kits" },
      { id: "1-2", name: "Craft Tools", slug: "craft-tools" },
      { id: "1-3", name: "Glitter & Embellishments", slug: "glitter-embellishments" },
    ],
  },
  {
    id: "2",
    name: "Home & Festive Decor",
    slug: "home-festive-decor",
    subcategories: [
      { id: "2-1", name: "Festival Decorations", slug: "festival-decorations" },
      { id: "2-2", name: "Wall Decor", slug: "wall-decor" },
    ],
  },
  {
    id: "3",
    name: "Gift Packaging",
    slug: "gift-packaging",
    subcategories: [
      { id: "3-1", name: "Gift Wraps", slug: "gift-wraps" },
      { id: "3-2", name: "Gift Boxes", slug: "gift-boxes" },
    ],
  },
  {
    id: "4",
    name: "Paper Craft",
    slug: "paper-craft",
    subcategories: [
      { id: "4-1", name: "Craft Papers", slug: "craft-papers" },
      { id: "4-2", name: "Origami", slug: "origami" },
    ],
  },
  {
    id: "5",
    name: "Birthday Supplies",
    slug: "birthday-supplies",
    subcategories: [
      { id: "5-1", name: "Balloons", slug: "balloons" },
      { id: "5-2", name: "Cake Toppers", slug: "cake-toppers" },
      { id: "5-3", name: "Return Gifts", slug: "return-gifts" },
    ],
  },
  {
    id: "6",
    name: "Pipecleaners Craft",
    slug: "pipecleaners",
    subcategories: [
      { id: "6-1", name: "Mixed Shades", slug: "mixed-shades" },
      { id: "6-2", name: "Glitter Pipe Cleaners", slug: "glitter-pipe-cleaners" },
    ],
  },
];