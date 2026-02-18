/**
 * SimplifiedLabels.ts — Low-Tech Friendly Label Mappings
 *
 * Converts technical terms to simple, understandable language
 * for users with limited computer knowledge.
 */

// ─── Technical Term to Simple Label Mapping ─────────────────

export const SIMPLE_LABELS: Record<string, string> = {
  // Order & Fulfillment
  'Fulfillment Status': 'Order Stage',
  'fulfillment_status': 'Order Stage',
  'ORDER_PLACED': 'New Order',
  'CONFIRMED': 'Confirmed',
  'IN_PRODUCTION': 'Being Made',
  'READY_FOR_PICKUP': 'Ready to Collect',
  'READY_FOR_DELIVERY': 'Ready to Deliver',
  'OUT_FOR_DELIVERY': 'On the Way',
  'DELIVERED': 'Delivered',
  'PICKED_UP': 'Collected',
  'COMPLETED': 'Done',
  'CANCELLED': 'Cancelled',

  // Payment
  'Payment Status': 'Paid?',
  'payment_status': 'Paid?',
  'PENDING': 'Not Paid',
  'PARTIALLY_PAID': 'Part Paid',
  'PAID': 'Paid in Full',
  'REFUNDED': 'Money Returned',
  'REFUND_PENDING': 'Refund Waiting',

  // Financial Terms
  'COGS': 'Cost of Goods',
  'cogs': 'Cost of Goods',
  'Cost of Goods Sold': 'Cost of Goods',
  'Gross Margin': 'Profit Before Costs',
  'Net Margin': 'Final Profit',
  'Net Profit': 'Total Profit',
  'Commission %': 'Platform Fee',
  'commission_rate': 'Platform Fee',
  'Processing Fee': 'Card Fee',
  'AOV': 'Average Order',
  'Average Order Value': 'Average Sale Amount',

  // Inventory
  'FIFO': 'First In, First Out',
  'FIFO Costing': 'Oldest Stock First',
  'SKU': 'Product Code',
  'sku': 'Product Code',
  'Batch Number': 'Stock Batch',
  'Lot Number': 'Stock Batch',
  'Stock Keeping Unit': 'Product Code',
  'Reorder Point': 'Low Stock Alert',
  'Safety Stock': 'Minimum Stock',
  'Lead Time': 'Delivery Wait Time',
  'Shrinkage': 'Lost Stock',
  'Wastage': 'Waste',
  'Adjustment': 'Stock Change',

  // Order Sources
  'WALK_IN': 'Walk-In',
  'PHONE': 'Phone Order',
  'WEBSITE': 'Website',
  'BLOOMNATION': 'BloomNation',
  'FTD': 'FTD Network',

  // General UI
  'Submit': 'Save',
  'Execute': 'Do It',
  'Process': 'Complete',
  'Initialize': 'Start',
  'Configure': 'Set Up',
  'Parameters': 'Settings',
  'Validation': 'Check',
  'Authentication': 'Login',
  'Authorization': 'Access',
  'Synchronize': 'Update',
  'Query': 'Search',
  'Filter': 'Show Only',
  'Pagination': 'Pages',
  'Export': 'Download',
  'Import': 'Upload',

  // Actions
  'Void': 'Cancel',
  'Refund': 'Return Money',
  'Reconcile': 'Match Up',
  'Archive': 'Hide Old Items',
  'Purge': 'Delete Forever',

  // Dates & Times
  'ETA': 'Expected Time',
  'SLA': 'Delivery Promise',
  'Turnaround Time': 'How Long It Takes',
};

// ─── Error Message Simplification ───────────────────────────

export const SIMPLE_ERRORS: Record<string, string> = {
  'Network Error': 'Could not connect. Check your internet.',
  'Unauthorized': 'Please log in again.',
  '401': 'Please log in again.',
  '403': 'You don\'t have permission to do this.',
  '404': 'This item was not found.',
  '500': 'Something went wrong. Please try again.',
  'Validation Error': 'Please check the information you entered.',
  'Required field': 'This field is required.',
  'Invalid format': 'Please enter this correctly.',
  'Connection timeout': 'The system is slow. Please wait and try again.',
  'Insufficient inventory': 'Not enough stock available.',
  'Duplicate entry': 'This already exists.',
};

// ─── Tooltip Help Text ──────────────────────────────────────

export const HELP_TEXT: Record<string, string> = {
  // Orders
  'order_source': 'Where the order came from - walk-in, phone, or online.',
  'order_type': 'What kind of order - delivery, pickup, etc.',
  'delivery_date': 'When the customer wants their flowers.',
  'delivery_time': 'What time to deliver - morning, afternoon, or evening.',
  'special_instructions': 'Any extra notes about this order.',

  // Products
  'product_search': 'Type to find products by name or code.',
  'product_price': 'How much to charge the customer.',
  'product_cost': 'How much we paid for this item.',

  // Inventory
  'batch_number': 'Helps track which delivery this came from.',
  'expiry_date': 'When this item needs to be used by.',
  'quantity': 'How many items.',
  'unit_cost': 'Price per single item.',

  // Payments
  'payment_method': 'How the customer is paying - cash, card, etc.',
  'amount_due': 'Total amount the customer needs to pay.',
  'change_due': 'Money to give back to the customer.',

  // Reports
  'date_range': 'Choose the time period for this report.',
  'profit_margin': 'How much profit we make as a percentage.',
  'commission': 'Fee charged by online platforms like BloomNation.',
};

// ─── Action Button Labels ───────────────────────────────────

export const ACTION_LABELS: Record<string, string> = {
  'save_draft': 'Save for Later',
  'submit_order': 'Complete Order',
  'process_payment': 'Take Payment',
  'print_receipt': 'Print Receipt',
  'send_confirmation': 'Send to Customer',
  'update_status': 'Update Stage',
  'cancel_order': 'Cancel Order',
  'refund_order': 'Return Money',
  'add_to_cart': 'Add to Order',
  'remove_from_cart': 'Remove',
  'apply_discount': 'Add Discount',
  'clear_cart': 'Start Over',
};

// ─── Empty State Messages ───────────────────────────────────

export const EMPTY_STATES: Record<string, { title: string; message: string; action?: string }> = {
  'orders': {
    title: 'No Orders Yet',
    message: 'No orders to show. Start by creating a new order.',
    action: '+ New Order',
  },
  'cart': {
    title: 'Cart is Empty',
    message: 'Search for products to add to this order.',
    action: 'Search Products',
  },
  'inventory': {
    title: 'No Stock Found',
    message: 'No items match your search. Try different words.',
  },
  'customers': {
    title: 'No Customers Found',
    message: 'No customers match your search.',
    action: '+ Add Customer',
  },
  'deliveries': {
    title: 'No Deliveries Today',
    message: 'No deliveries scheduled for today. Check another date.',
  },
  'search_results': {
    title: 'No Results',
    message: 'Nothing found. Try different search words.',
  },
  'external_orders': {
    title: 'All Caught Up!',
    message: 'No new online orders waiting. Great job!',
  },
};

// ─── Utility Functions ──────────────────────────────────────

/**
 * Get simplified label for a technical term
 */
export const getSimpleLabel = (key: string): string => {
  return SIMPLE_LABELS[key] ?? key;
};

/**
 * Get user-friendly error message
 */
export const getSimpleError = (error: string): string => {
  // Check exact match first
  if (SIMPLE_ERRORS[error]) return SIMPLE_ERRORS[error];

  // Check if error contains known patterns
  for (const [pattern, message] of Object.entries(SIMPLE_ERRORS)) {
    if (error.toLowerCase().includes(pattern.toLowerCase())) {
      return message;
    }
  }

  return 'Something went wrong. Please try again.';
};

/**
 * Get help text for a field
 */
export const getHelpText = (fieldKey: string): string | undefined => {
  return HELP_TEXT[fieldKey];
};

/**
 * Get action button label
 */
export const getActionLabel = (action: string): string => {
  return ACTION_LABELS[action] ?? action;
};

/**
 * Get empty state content
 */
export const getEmptyState = (context: string) => {
  return EMPTY_STATES[context] ?? {
    title: 'Nothing Here',
    message: 'No data to display.',
  };
};

// ─── Status Color Mapping ───────────────────────────────────

export const STATUS_COLORS: Record<string, { bg: string; text: string; label: string }> = {
  // Order Status - Green = Good, Red = Attention, Yellow = In Progress
  'ORDER_PLACED': { bg: '#fff3e0', text: '#e65100', label: '🆕 New' },
  'CONFIRMED': { bg: '#e3f2fd', text: '#1565c0', label: '✓ Confirmed' },
  'IN_PRODUCTION': { bg: '#fff8e1', text: '#f57f17', label: '🌸 Making' },
  'READY_FOR_PICKUP': { bg: '#e8f5e9', text: '#2e7d32', label: '📦 Ready' },
  'READY_FOR_DELIVERY': { bg: '#e8f5e9', text: '#2e7d32', label: '🚚 Ready' },
  'OUT_FOR_DELIVERY': { bg: '#e1f5fe', text: '#0277bd', label: '🚗 On Way' },
  'DELIVERED': { bg: '#c8e6c9', text: '#1b5e20', label: '✅ Delivered' },
  'PICKED_UP': { bg: '#c8e6c9', text: '#1b5e20', label: '✅ Collected' },
  'COMPLETED': { bg: '#c8e6c9', text: '#1b5e20', label: '✅ Done' },
  'CANCELLED': { bg: '#ffebee', text: '#c62828', label: '❌ Cancelled' },

  // Payment Status
  'PENDING': { bg: '#fff3e0', text: '#e65100', label: '⏳ Not Paid' },
  'PARTIALLY_PAID': { bg: '#fff8e1', text: '#f57f17', label: '💰 Part Paid' },
  'PAID': { bg: '#c8e6c9', text: '#1b5e20', label: '✅ Paid' },
  'REFUNDED': { bg: '#f3e5f5', text: '#6a1b9a', label: '↩️ Refunded' },
};
