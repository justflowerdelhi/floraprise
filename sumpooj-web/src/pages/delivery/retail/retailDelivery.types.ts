/**
 * retailDelivery.types.ts — Type definitions and utility helpers for Floraprise Retail Delivery
 */

export interface RetailDeliveryItem {
  deliveryId: string;
  orderId: string;
  orderNumber: string;
  customerName: string;
  phone?: string | null;
  recipientName: string;
  recipientPhone?: string | null;
  deliveryDate: string;
  timeSlot: string;
  address: string;
  postalCode?: string | null;
  cardMessage?: string | null;
  deliveryPriority: string;
  deliveryFee: number;
  totalAmount: number;
  paymentStatus: string;
  status: string; // 'Scheduled' | 'OutForDelivery' | 'Delivered' | 'Failed' | 'Cancelled'
  deliveryPersonId?: string | null;
  deliveryPersonName?: string | null;
  itemCount: number;
  itemsSummary: string;
}

export interface RetailDeliveryDriver {
  id: string;
  name: string;
  phone?: string | null;
  role: string;
  isDeliveryRole: boolean;
}

export type DeliveryFilterStatus = 'ALL' | 'SCHEDULED' | 'OUT_FOR_DELIVERY' | 'DELIVERED';
export type DeliveryDateFilter = 'TODAY' | 'TOMORROW' | 'ALL_ACTIVE';

/**
 * Generates a WhatsApp click-to-chat URL for quick driver/dispatcher updates to recipient or customer.
 * Formats 10-digit Indian numbers with country code 91 if needed.
 */
export function generateWhatsAppLink(
  phone?: string | null,
  recipientName?: string,
  orderNumber?: string
): string {
  if (!phone) return '';
  const digits = phone.replace(/\D/g, '');
  if (!digits) return '';
  const normalizedPhone = digits.length === 10 ? `91${digits}` : digits;
  const name = recipientName ? ` ${recipientName}` : '';
  const orderInfo = orderNumber ? ` for Order #${orderNumber}` : '';
  const message = `Hello${name}, your Floraprise delivery${orderInfo} is being coordinated. Please let us know if you have any delivery instructions!`;
  return `https://wa.me/${normalizedPhone}?text=${encodeURIComponent(message)}`;
}

/**
 * Generates a Google Maps search URL from delivery address and postal code.
 */
export function generateGoogleMapsLink(address: string, postalCode?: string | null): string {
  const query = [address, postalCode].filter(Boolean).join(', ');
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}`;
}
