
"use client";

import { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { Product } from "../data/products";



export interface CartItem extends Product {
  id: string; // ensure cart items always carry a unique identifier
  variantId?: string;
  variantName?: string;
  quantity: number;
}

interface CartContextType {
  cart: CartItem[];
  addToCart: (item: CartItem) => void;
  removeFromCart: (id: string, variantId?: string) => void;
  updateQuantity: (id: string, variantId: string | undefined, quantity: number) => void;
  clearCart: () => void;
  subtotal: number;
  shipping: number;
  discount: number;
  couponCode: string;
  setCouponCode: (code: string) => void;
  couponDiscount: number;
  setCouponDiscount: (amount: number) => void;
  total: number;
  paymentMethod: "cod" | "prepaid";
  setPaymentMethod: (method: "cod" | "prepaid") => void;
  increaseQty: (id: string, variantId?: string) => void;
  decreaseQty: (id: string, variantId?: string) => void;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export function CartProvider({ children }: { children: ReactNode }) {
  const [cart, setCart] = useState<CartItem[]>([]);

  // Must be defined here so setCart is in scope
  const increaseQty = (id: string, variantId?: string) => {
    setCart((prev) =>
      prev.map((item) =>
        item.id === id && item.variantId === variantId
          ? { ...item, quantity: item.quantity + 1 }
          : item
      )
    );
  };

  const decreaseQty = (id: string, variantId?: string) => {
    setCart((prev) =>
      prev
        .map((item) =>
          item.id === id && item.variantId === variantId
            ? { ...item, quantity: item.quantity - 1 }
            : item
        )
        .filter((item) => item.quantity > 0)
    );
  };

  // Load cart from localStorage on mount
  useEffect(() => {
    const stored = localStorage.getItem("cart");
    if (stored) setCart(JSON.parse(stored));
  }, []);

  // Save cart to localStorage whenever it changes
  useEffect(() => {
    localStorage.setItem("cart", JSON.stringify(cart));
  }, [cart]);
  const [couponCode, setCouponCode] = useState("");
  const [couponDiscount, setCouponDiscount] = useState(0);
  const [paymentMethod, setPaymentMethod] = useState<"cod" | "prepaid">("cod");

  const addToCart = (item: CartItem) => {
    setCart((prev: CartItem[]) => {
      const existing = prev.find(
        (p) =>
          p.id === item.id &&
          p.variantId === item.variantId
      );

      if (existing) {
        return prev.map((p) =>
          p.id === item.id &&
          p.variantId === item.variantId
            ? { ...p, quantity: p.quantity + (item.quantity || 1) }
            : p
        );
      }

      return [...prev, { ...item, quantity: item.quantity || 1 }];
    });
  };

  const removeFromCart = (id: string, variantId?: string) => {
    setCart(cart.filter((item) => !(item.id === id && item.variantId === variantId)));
  };

  const updateQuantity = (id: string, variantId: string | undefined, quantity: number) => {
    setCart(
      cart.map((item) =>
        item.id === id && item.variantId === variantId ? { ...item, quantity } : item
      )
    );
  };

  const subtotal = cart.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0
  );

  const discount =
    paymentMethod === "prepaid" ? subtotal * 0.05 : 0;

  const shipping = subtotal >= 200 ? 0 : subtotal > 0 ? 49 : 0;

  const total = subtotal - discount - couponDiscount + shipping;

  const clearCart = () => {
    setCart([]);
    setCouponCode("");
    setCouponDiscount(0);
  };

  return (
    <CartContext.Provider
      value={{
        cart,
        addToCart,
        removeFromCart,
        updateQuantity,
        clearCart,
        subtotal,
        shipping,
        discount,
        couponCode,
        setCouponCode,
        couponDiscount,
        setCouponDiscount,
        total,
        paymentMethod,
        setPaymentMethod,
        increaseQty,
        decreaseQty,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) throw new Error("CartContext must be used inside CartProvider");
  return context;
};