/**
 * PaymentScheduleTypes.ts — Payment Schedule & Deposit Tracking
 *
 * Phase 3: Structured deposit and installment tracking for wedding events.
 * Integrates with existing Payment model.
 */

// ─── Payment Schedule Status ────────────────────────────────

export type PaymentScheduleStatus = 'PENDING' | 'PAID' | 'OVERDUE' | 'PARTIAL';

export const PAYMENT_SCHEDULE_STATUSES: PaymentScheduleStatus[] = ['PENDING', 'PAID', 'OVERDUE', 'PARTIAL'];

// ─── Payment Schedule Item ──────────────────────────────────

export interface EventPaymentSchedule {
  id: string;
  eventId: string;
  proposalId: string;
  label: string; // e.g., "Deposit", "Mid Payment", "Final Payment"
  dueDate: string;
  amount: number;
  amountPaid: number; // Track partial payments
  status: PaymentScheduleStatus;
  linkedPaymentIds: string[]; // Links to Payment records
  notes?: string;
  createdAt: string;
  updatedAt: string;
  paidAt?: string;
}

// ─── Payment Plan Template ──────────────────────────────────

export type PaymentPlanType = 'CUSTOM' | 'STANDARD_30_40_30' | 'TWO_PART_50_50' | 'FULL_UPFRONT';

export interface PaymentPlanTemplate {
  type: PaymentPlanType;
  label: string;
  description: string;
  milestones: {
    label: string;
    percentage: number;
    daysBeforeEvent: number; // Negative = days before event
  }[];
}

export const PAYMENT_PLAN_TEMPLATES: PaymentPlanTemplate[] = [
  {
    type: 'STANDARD_30_40_30',
    label: 'Standard (30/40/30)',
    description: '30% Deposit → 40% Mid Payment → 30% Final',
    milestones: [
      { label: 'Booking Deposit', percentage: 30, daysBeforeEvent: 60 },
      { label: 'Mid Payment', percentage: 40, daysBeforeEvent: 14 },
      { label: 'Final Payment', percentage: 30, daysBeforeEvent: 0 },
    ],
  },
  {
    type: 'TWO_PART_50_50',
    label: 'Two-Part (50/50)',
    description: '50% Deposit → 50% Final',
    milestones: [
      { label: 'Deposit', percentage: 50, daysBeforeEvent: 30 },
      { label: 'Final Payment', percentage: 50, daysBeforeEvent: 0 },
    ],
  },
  {
    type: 'FULL_UPFRONT',
    label: 'Full Upfront',
    description: '100% at booking',
    milestones: [{ label: 'Full Payment', percentage: 100, daysBeforeEvent: 60 }],
  },
];

// ─── Status Configuration ───────────────────────────────────

export interface PaymentScheduleStatusConfig {
  label: string;
  color: string;
  bgColor: string;
  icon: string;
}

export const PAYMENT_SCHEDULE_STATUS_CONFIG: Record<PaymentScheduleStatus, PaymentScheduleStatusConfig> = {
  PENDING: {
    label: 'Pending',
    color: '#ff9800',
    bgColor: 'rgba(255, 152, 0, 0.12)',
    icon: 'Schedule',
  },
  PAID: {
    label: 'Paid',
    color: '#4caf50',
    bgColor: 'rgba(76, 175, 80, 0.12)',
    icon: 'CheckCircle',
  },
  OVERDUE: {
    label: 'Overdue',
    color: '#f44336',
    bgColor: 'rgba(244, 67, 54, 0.12)',
    icon: 'Warning',
  },
  PARTIAL: {
    label: 'Partial',
    color: '#2196f3',
    bgColor: 'rgba(33, 150, 243, 0.12)',
    icon: 'PieChart',
  },
};

// ─── Financial Summary Interface ────────────────────────────

export interface EventFinancialSummaryData {
  eventId: string;
  proposalId: string;
  proposalGrandTotal: number;
  totalPaid: number;
  balanceRemaining: number;
  depositPaid: boolean;
  nextDuePayment: EventPaymentSchedule | null;
  overduePayments: EventPaymentSchedule[];
  scheduleItems: EventPaymentSchedule[];
  paymentProgress: number; // 0-100%
}

// ─── Warning Types ──────────────────────────────────────────

export type PaymentWarningType =
  | 'NO_DEPOSIT'
  | 'OVERDUE_PAYMENT'
  | 'EVENT_NEAR_UNPAID'
  | 'DEPOSIT_REQUIRED_FOR_CONFIRM';

export interface PaymentWarning {
  type: PaymentWarningType;
  severity: 'warning' | 'error';
  message: string;
  actionLabel?: string;
}

// ─── Utility Functions ──────────────────────────────────────

/**
 * Calculate payment schedule status based on due date and amount paid
 */
export const calculateScheduleStatus = (
  dueDate: string,
  amount: number,
  amountPaid: number
): PaymentScheduleStatus => {
  if (amountPaid >= amount) return 'PAID';
  if (amountPaid > 0) return 'PARTIAL';

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const due = new Date(dueDate);
  due.setHours(0, 0, 0, 0);

  return due < today ? 'OVERDUE' : 'PENDING';
};

/**
 * Generate payment schedule from template
 */
export const generatePaymentSchedule = (
  eventId: string,
  proposalId: string,
  grandTotal: number,
  eventDate: string,
  template: PaymentPlanTemplate
): EventPaymentSchedule[] => {
  const eventDateObj = new Date(eventDate);
  const now = new Date().toISOString();

  return template.milestones.map((milestone, index) => {
    const dueDate = new Date(eventDateObj);
    dueDate.setDate(dueDate.getDate() - milestone.daysBeforeEvent);

    // Ensure due date is not in the past for new schedules
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (dueDate < today) {
      dueDate.setTime(today.getTime());
      dueDate.setDate(today.getDate() + 7); // Give 7 days grace
    }

    const amount = Math.round((grandTotal * milestone.percentage) / 100);

    return {
      id: `sched-${Date.now()}-${index}`,
      eventId,
      proposalId,
      label: milestone.label,
      dueDate: dueDate.toISOString().split('T')[0],
      amount,
      amountPaid: 0,
      status: 'PENDING' as PaymentScheduleStatus,
      linkedPaymentIds: [],
      createdAt: now,
      updatedAt: now,
    };
  });
};

/**
 * Create a custom payment schedule item
 */
export const createCustomScheduleItem = (
  eventId: string,
  proposalId: string,
  label: string,
  dueDate: string,
  amount: number
): EventPaymentSchedule => {
  const now = new Date().toISOString();
  return {
    id: `sched-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    eventId,
    proposalId,
    label,
    dueDate,
    amount,
    amountPaid: 0,
    status: calculateScheduleStatus(dueDate, amount, 0),
    linkedPaymentIds: [],
    createdAt: now,
    updatedAt: now,
  };
};

/**
 * Calculate financial summary for an event
 */
export const calculateFinancialSummary = (
  eventId: string,
  proposalId: string,
  proposalGrandTotal: number,
  scheduleItems: EventPaymentSchedule[]
): EventFinancialSummaryData => {
  const totalPaid = scheduleItems.reduce((sum, item) => sum + item.amountPaid, 0);
  const balanceRemaining = proposalGrandTotal - totalPaid;
  const paymentProgress = proposalGrandTotal > 0 ? (totalPaid / proposalGrandTotal) * 100 : 0;

  // Check if deposit (first payment) is paid
  const depositItem = scheduleItems[0];
  const depositPaid = depositItem ? depositItem.status === 'PAID' : false;

  // Find next due payment
  const pendingItems = scheduleItems
    .filter((item) => item.status === 'PENDING' || item.status === 'PARTIAL')
    .sort((a, b) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime());
  const nextDuePayment = pendingItems[0] || null;

  // Find overdue payments
  const overduePayments = scheduleItems.filter((item) => item.status === 'OVERDUE');

  return {
    eventId,
    proposalId,
    proposalGrandTotal,
    totalPaid,
    balanceRemaining,
    depositPaid,
    nextDuePayment,
    overduePayments,
    scheduleItems,
    paymentProgress,
  };
};

/**
 * Generate payment warnings for an event
 */
export const generatePaymentWarnings = (
  summary: EventFinancialSummaryData,
  eventDate: string,
  eventStatus: string
): PaymentWarning[] => {
  const warnings: PaymentWarning[] = [];
  const today = new Date();
  const event = new Date(eventDate);
  const daysUntilEvent = Math.ceil((event.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));

  // No deposit warning
  if (!summary.depositPaid && summary.scheduleItems.length > 0) {
    warnings.push({
      type: 'NO_DEPOSIT',
      severity: 'warning',
      message: 'Deposit not yet received',
      actionLabel: 'Record Deposit',
    });
  }

  // Overdue payment warning
  if (summary.overduePayments.length > 0) {
    const totalOverdue = summary.overduePayments.reduce(
      (sum, p) => sum + (p.amount - p.amountPaid),
      0
    );
    warnings.push({
      type: 'OVERDUE_PAYMENT',
      severity: 'error',
      message: `${summary.overduePayments.length} overdue payment(s): ₹${totalOverdue.toLocaleString()}`,
      actionLabel: 'View Overdue',
    });
  }

  // Event near but unpaid warning
  if (daysUntilEvent <= 7 && summary.balanceRemaining > 0) {
    warnings.push({
      type: 'EVENT_NEAR_UNPAID',
      severity: 'error',
      message: `Event in ${daysUntilEvent} days with ₹${summary.balanceRemaining.toLocaleString()} unpaid`,
      actionLabel: 'Collect Balance',
    });
  }

  // Prevent event confirmation without deposit
  if (eventStatus === 'INQUIRY' || eventStatus === 'QUOTE_SENT') {
    if (!summary.depositPaid) {
      warnings.push({
        type: 'DEPOSIT_REQUIRED_FOR_CONFIRM',
        severity: 'warning',
        message: 'Deposit required before confirming event',
      });
    }
  }

  return warnings;
};

// ─── API Payload Examples ───────────────────────────────────

/**
 * Create Payment Schedule:
 * POST /api/events/{eventId}/payment-schedule
 * {
 *   proposalId: "prop-001",
 *   items: [
 *     { label: "Deposit", dueDate: "2026-02-01", amount: 50000 },
 *     { label: "Mid Payment", dueDate: "2026-03-01", amount: 80000 },
 *     { label: "Final", dueDate: "2026-03-14", amount: 60000 }
 *   ]
 * }
 *
 * Record Payment Against Schedule:
 * POST /api/payment-schedule/{scheduleId}/payments
 * {
 *   paymentId: "pay-123",
 *   amount: 50000
 * }
 *
 * Get Event Financial Summary:
 * GET /api/events/{eventId}/financial-summary
 * Response: EventFinancialSummaryData
 */
