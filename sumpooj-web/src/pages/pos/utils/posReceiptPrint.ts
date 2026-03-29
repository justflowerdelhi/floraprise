export interface PosReceiptItem {
  name: string;
  quantity: number;
  unitPrice: number;
}

export interface PosReceiptPayment {
  method: string;
  amount: number;
}

export interface PrintPosReceiptInput {
  orderNumber?: string;
  orderId?: string;
  customerName?: string;
  customerPhone?: string;
  items: PosReceiptItem[];
  payments: PosReceiptPayment[];
  subtotal: number;
  discount: number;
  deliveryFee: number;
  grandTotal: number;
  paidTotal: number;
  balanceDue?: number;
  printedAt?: Date;
}

export type PosReceiptPrintMode = 'AUTO' | 'ASK' | 'PDF';

const POS_RECEIPT_PRINT_MODE_KEY = 'pos:receiptPrintMode';

const money = (value: number) =>
  new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: 2,
  }).format(Number.isFinite(value) ? value : 0);

const text = (value?: string | null) => {
  const str = (value ?? '').trim();
  if (!str) return '-';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\"/g, '&quot;')
    .replace(/'/g, '&#39;');
};

const methodLabel = (method: string) => {
  switch ((method || '').toUpperCase()) {
    case 'CASH':
      return 'Cash';
    case 'CARD':
      return 'Card';
    case 'UPI':
      return 'UPI';
    case 'STORE_CREDIT':
      return 'Store Credit';
    case 'GIFT_CARD':
      return 'Gift Card';
    default:
      return method || 'Payment';
  }
};

// ─── HTML Builder (private) ─────────────────────────────────────────────────

const buildReceiptHtml = (input: PrintPosReceiptInput): string => {
  const printedAt = input.printedAt ?? new Date();
  const orderRef = text(input.orderNumber || input.orderId || 'N/A');

  const itemRows = input.items
    .map((item) => {
      const lineTotal = item.quantity * item.unitPrice;
      return `
        <tr>
          <td class="name">${text(item.name)}</td>
          <td class="qty">${item.quantity}</td>
          <td class="amt">${money(lineTotal)}</td>
        </tr>
      `;
    })
    .join('');

  const paymentRows = input.payments
    .map(
      (payment) => `
        <tr>
          <td>${text(methodLabel(payment.method))}</td>
          <td class="amt">${money(payment.amount)}</td>
        </tr>
      `,
    )
    .join('');
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>POS Receipt</title>
  <style>
    @page { margin: 8mm; }
    body {
      font-family: 'Courier New', monospace;
      color: #111;
      margin: 0;
      padding: 0;
      font-size: 12px;
    }
    .receipt {
      max-width: 78mm;
      margin: 0 auto;
    }
    h1 {
      margin: 0;
      font-size: 16px;
      text-align: center;
    }
    .meta {
      text-align: center;
      margin: 4px 0 10px;
      line-height: 1.4;
      font-size: 11px;
    }
    .section { margin-top: 8px; }
    .divider {
      border-top: 1px dashed #000;
      margin: 8px 0;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 12px;
    }
    td {
      padding: 2px 0;
      vertical-align: top;
    }
    .qty {
      width: 26px;
      text-align: center;
    }
    .amt {
      width: 90px;
      text-align: right;
      white-space: nowrap;
    }
    .totals td { padding: 1px 0; }
    .totals .grand td {
      font-weight: 700;
      font-size: 13px;
      padding-top: 4px;
    }
    .footer {
      margin-top: 10px;
      text-align: center;
      font-size: 11px;
      line-height: 1.4;
    }
  </style>
</head>
<body>
  <div class="receipt">
    <h1>FloraPrice</h1>
    <div class="meta">
      <div>Tax Invoice / Receipt</div>
      <div>Order: ${orderRef}</div>
      <div>${text(printedAt.toLocaleString('en-IN'))}</div>
      <div>Customer: ${text(input.customerName)}</div>
      <div>Phone: ${text(input.customerPhone)}</div>
    </div>

    <div class="divider"></div>

    <table>
      <tbody>
        ${itemRows}
      </tbody>
    </table>

    <div class="divider"></div>

    <table class="totals">
      <tbody>
        <tr><td>Subtotal</td><td class="amt">${money(input.subtotal)}</td></tr>
        <tr><td>Discount</td><td class="amt">-${money(input.discount)}</td></tr>
        <tr><td>Delivery</td><td class="amt">${money(input.deliveryFee)}</td></tr>
        <tr class="grand"><td>Total</td><td class="amt">${money(input.grandTotal)}</td></tr>
        <tr><td>Paid</td><td class="amt">${money(input.paidTotal)}</td></tr>
        <tr><td>Balance</td><td class="amt">${money(input.balanceDue ?? Math.max(0, input.grandTotal - input.paidTotal))}</td></tr>
      </tbody>
    </table>

    <div class="section">
      <table>
        <tbody>
          ${paymentRows}
        </tbody>
      </table>
    </div>

    <div class="divider"></div>
    <div class="footer">
      <div>Thank you for shopping with FloraPrice</div>
      <div>If no printer is connected, choose Save as PDF in print dialog.</div>
    </div>
  </div>
</body>
</html>`;
};

// ─── Fallback: iframe print ──────────────────────────────────────────────────
// Used when window.open() is blocked by the browser popup blocker.
// printPosReceipt() still blocks the main thread while the print dialog is open,
// but uses srcdoc (async content load) to avoid the synchronous doc.write stall.

export const printPosReceipt = (input: PrintPosReceiptInput): void => {
  if (typeof window === 'undefined' || typeof document === 'undefined') return;

  const html = buildReceiptHtml(input);

  const iframe = document.createElement('iframe');
  iframe.style.position = 'fixed';
  iframe.style.right = '0';
  iframe.style.bottom = '0';
  iframe.style.width = '0';
  iframe.style.height = '0';
  iframe.style.border = '0';
  iframe.setAttribute('aria-hidden', 'true');

  const cleanup = () => {
    if (document.body.contains(iframe)) {
      document.body.removeChild(iframe);
    }
  };

  // Use onload so print() fires only after the iframe content is fully rendered.
  iframe.addEventListener('load', () => {
    setTimeout(() => {
      try {
        iframe.contentWindow?.focus();
        iframe.contentWindow?.print();
      } finally {
        if (iframe.contentWindow) {
          iframe.contentWindow.addEventListener('afterprint', cleanup, { once: true });
          setTimeout(cleanup, 30_000); // safety fallback
        } else {
          cleanup();
        }
      }
    }, 100);
  }, { once: true });

  document.body.appendChild(iframe);
  // srcdoc triggers async content load — does not block the main thread on parse
  iframe.srcdoc = html;
};

// ─── Primary print path: separate window ────────────────────────────────────

/**
 * Opens a blank popup window while still in the synchronous user-gesture call
 * stack (i.e. BEFORE any `await`). Popup blockers only fire after the first
 * `await`, so this is safe as long as it's called before any async operation.
 *
 * Returns null if popups are blocked.
 */
export const openReceiptWindow = (): Window | null => {
  if (typeof window === 'undefined') return null;
  const win = window.open(
    'about:blank',
    '_blank',
    'width=520,height=720,menubar=0,toolbar=0,location=0,scrollbars=1,resizable=1',
  );
  if (win) {
    win.document.write(
      '<html><body style="font-family:sans-serif;display:flex;align-items:center;' +
      'justify-content:center;height:100vh;margin:0;color:#888">' +
      '<p style="font-size:14px">Preparing receipt\u2026</p></body></html>',
    );
  }
  return win;
};

/**
 * Writes receipt HTML into a pre-opened window and triggers print there.
 * The main POS page is NEVER blocked regardless of mode.
 *
 * - AUTO / PDF : prints automatically after a short render delay.
 * - ASK        : shows the receipt with a Print / Skip bar — user decides.
 */
export const printInWindow = (
  win: Window,
  input: PrintPosReceiptInput,
  mode: PosReceiptPrintMode = 'AUTO',
): void => {
  const receiptHtml = buildReceiptHtml(input);

  if (mode === 'ASK') {
    // For ASK mode embed the receipt below a sticky "Print / Skip" bar.
    // The main page stays fully responsive — the user decides in the popup.
    const askHtml = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Print Receipt?</title>
  <style>
    .bar {
      position: fixed; top: 0; left: 0; right: 0;
      display: flex; align-items: center; gap: 10px;
      background: #5b21b6; color: #fff; padding: 10px 16px;
      font-family: sans-serif; font-size: 13px; z-index: 100;
    }
    .bar span { flex: 1; }
    .bar button {
      padding: 7px 18px; border: none; border-radius: 5px;
      cursor: pointer; font-size: 13px;
    }
    .bar .y { background: #fff; color: #5b21b6; font-weight: 700; }
    .bar .n { background: rgba(255,255,255,0.2); color: #fff; }
    body { margin-top: 48px; }
    @media print { .bar { display: none !important; } body { margin-top: 0 !important; } }
  </style>
</head>
<body>
  <div class="bar">
    <span>&#10003; Order saved! Print this receipt?</span>
    <button class="y" onclick="window.print()">&#128424; Print / Save PDF</button>
    <button class="n" onclick="window.close()">Skip</button>
  </div>
  ${receiptHtml.replace(/^[\s\S]*?<body[^>]*>/, '').replace(/<\/body>[\s\S]*$/, '')}
</body>
</html>`;
    win.document.open();
    win.document.write(askHtml);
    win.document.close();
  } else {
    // AUTO / PDF — write full receipt and auto-print after a short delay
    win.document.open();
    win.document.write(receiptHtml);
    win.document.close();
    setTimeout(() => {
      win.focus();
      win.print();
    }, 300);
  }
};

// ─── localStorage helpers ────────────────────────────────────────────────────

export const getPosReceiptPrintMode = (): PosReceiptPrintMode => {
  if (typeof window === 'undefined') return 'AUTO';

  try {
    const value = window.localStorage.getItem(POS_RECEIPT_PRINT_MODE_KEY);
    if (value === 'ASK' || value === 'PDF' || value === 'AUTO') return value;
  } catch {
    // ignore storage access errors
  }

  return 'AUTO';
};

export const setPosReceiptPrintMode = (mode: PosReceiptPrintMode): void => {
  if (typeof window === 'undefined') return;

  try {
    window.localStorage.setItem(POS_RECEIPT_PRINT_MODE_KEY, mode);
  } catch {
    // ignore storage access errors
  }
};

// Kept for backward compatibility — prefer openReceiptWindow + printInWindow.
export const triggerPosReceiptPrint = (
  input: PrintPosReceiptInput,
): { attempted: boolean; mode: PosReceiptPrintMode } => {
  const mode = getPosReceiptPrintMode();
  printPosReceipt(input);
  return { attempted: true, mode };
};
