/**
 * PaymentScheduleMockData.ts — Mock Data for Payment Schedule
 *
 * Phase 3: Payment Schedule & Deposit Tracking
 */
import type { EventPaymentSchedule, EventFinancialSummaryData } from './PaymentScheduleTypes';
import { calculateScheduleStatus, calculateFinancialSummary } from './PaymentScheduleTypes';

// ─── Mock Payment Schedules ─────────────────────────────────

export const MOCK_PAYMENT_SCHEDULES: EventPaymentSchedule[] = [
  // Sharma-Patel Wedding (evt-001, prop-001) - Grand Total: ₹211,084
  // FULLY PAID
  {
    id: 'sched-001',
    eventId: 'evt-001',
    proposalId: 'prop-001',
    label: 'Booking Deposit',
    dueDate: '2026-01-20',
    amount: 63325,
    amountPaid: 63325,
    status: 'PAID',
    linkedPaymentIds: ['pay-001'],
    notes: 'Received via bank transfer',
    createdAt: '2026-01-15T10:00:00Z',
    updatedAt: '2026-01-20T14:30:00Z',
    paidAt: '2026-01-20T14:30:00Z',
  },
  {
    id: 'sched-002',
    eventId: 'evt-001',
    proposalId: 'prop-001',
    label: 'Mid Payment',
    dueDate: '2026-03-01',
    amount: 84434,
    amountPaid: 84434,
    status: 'PAID',
    linkedPaymentIds: ['pay-002', 'pay-003'],
    notes: 'Split into two card payments',
    createdAt: '2026-01-15T10:00:00Z',
    updatedAt: '2026-02-28T11:00:00Z',
    paidAt: '2026-02-28T11:00:00Z',
  },
  {
    id: 'sched-003',
    eventId: 'evt-001',
    proposalId: 'prop-001',
    label: 'Final Payment',
    dueDate: '2026-03-15',
    amount: 63325,
    amountPaid: 63325,
    status: 'PAID',
    linkedPaymentIds: ['pay-004'],
    createdAt: '2026-01-15T10:00:00Z',
    updatedAt: '2026-03-10T16:00:00Z',
    paidAt: '2026-03-10T16:00:00Z',
  },

  // TechCorp Annual Gala (evt-002, prop-002) - Grand Total: ₹81,715
  // PARTIAL - MID PAYMENT OVERDUE
  {
    id: 'sched-004',
    eventId: 'evt-002',
    proposalId: 'prop-002',
    label: 'Deposit',
    dueDate: '2026-02-07',
    amount: 40858,
    amountPaid: 40858,
    status: 'PAID',
    linkedPaymentIds: ['pay-005'],
    createdAt: '2026-02-05T09:00:00Z',
    updatedAt: '2026-02-07T10:00:00Z',
    paidAt: '2026-02-07T10:00:00Z',
  },
  {
    id: 'sched-005',
    eventId: 'evt-002',
    proposalId: 'prop-002',
    label: 'Final Payment',
    dueDate: '2026-02-25',
    amount: 40857,
    amountPaid: 20000,
    status: 'PARTIAL',
    linkedPaymentIds: ['pay-006'],
    notes: 'Partial payment received, balance pending',
    createdAt: '2026-02-05T09:00:00Z',
    updatedAt: '2026-02-20T15:00:00Z',
  },

  // Gupta Birthday (evt-003, prop-003) - Grand Total: ₹18,408
  // NO PAYMENTS YET
  {
    id: 'sched-006',
    eventId: 'evt-003',
    proposalId: 'prop-003',
    label: 'Deposit (50%)',
    dueDate: '2026-02-15',
    amount: 9204,
    amountPaid: 0,
    status: 'OVERDUE',
    linkedPaymentIds: [],
    createdAt: '2026-02-10T14:00:00Z',
    updatedAt: '2026-02-10T14:00:00Z',
  },
  {
    id: 'sched-007',
    eventId: 'evt-003',
    proposalId: 'prop-003',
    label: 'Final Payment',
    dueDate: '2026-02-20',
    amount: 9204,
    amountPaid: 0,
    status: 'PENDING',
    linkedPaymentIds: [],
    createdAt: '2026-02-10T14:00:00Z',
    updatedAt: '2026-02-10T14:00:00Z',
  },

  // Kapoor-Singh Wedding (evt-005, prop-004) - Grand Total: ₹129,800
  // DEPOSIT ONLY
  {
    id: 'sched-008',
    eventId: 'evt-005',
    proposalId: 'prop-004',
    label: 'Booking Deposit',
    dueDate: '2026-02-20',
    amount: 38940,
    amountPaid: 38940,
    status: 'PAID',
    linkedPaymentIds: ['pay-007'],
    createdAt: '2026-02-18T10:00:00Z',
    updatedAt: '2026-02-19T12:00:00Z',
    paidAt: '2026-02-19T12:00:00Z',
  },
  {
    id: 'sched-009',
    eventId: 'evt-005',
    proposalId: 'prop-004',
    label: 'Mid Payment',
    dueDate: '2026-03-25',
    amount: 51920,
    amountPaid: 0,
    status: 'PENDING',
    linkedPaymentIds: [],
    createdAt: '2026-02-18T10:00:00Z',
    updatedAt: '2026-02-18T10:00:00Z',
  },
  {
    id: 'sched-010',
    eventId: 'evt-005',
    proposalId: 'prop-004',
    label: 'Final Payment',
    dueDate: '2026-04-10',
    amount: 38940,
    amountPaid: 0,
    status: 'PENDING',
    linkedPaymentIds: [],
    createdAt: '2026-02-18T10:00:00Z',
    updatedAt: '2026-02-18T10:00:00Z',
  },
];

// ─── Mock Payment Records (linked payments) ─────────────────

export interface MockPaymentRecord {
  id: string;
  scheduleId: string;
  method: 'CASH' | 'CARD' | 'BANK_TRANSFER' | 'UPI';
  amount: number;
  reference?: string;
  recordedAt: string;
  recordedBy: string;
}

export const MOCK_PAYMENT_RECORDS: MockPaymentRecord[] = [
  // Sharma-Patel Wedding payments
  {
    id: 'pay-001',
    scheduleId: 'sched-001',
    method: 'BANK_TRANSFER',
    amount: 63325,
    reference: 'NEFT-78234567',
    recordedAt: '2026-01-20T14:30:00Z',
    recordedBy: 'Raj Kumar',
  },
  {
    id: 'pay-002',
    scheduleId: 'sched-002',
    method: 'CARD',
    amount: 50000,
    reference: 'TXN-892345',
    recordedAt: '2026-02-28T10:30:00Z',
    recordedBy: 'Meera Patel',
  },
  {
    id: 'pay-003',
    scheduleId: 'sched-002',
    method: 'CARD',
    amount: 34434,
    reference: 'TXN-892346',
    recordedAt: '2026-02-28T11:00:00Z',
    recordedBy: 'Meera Patel',
  },
  {
    id: 'pay-004',
    scheduleId: 'sched-003',
    method: 'UPI',
    amount: 63325,
    reference: 'UPI-930274829',
    recordedAt: '2026-03-10T16:00:00Z',
    recordedBy: 'Raj Kumar',
  },

  // TechCorp payments
  {
    id: 'pay-005',
    scheduleId: 'sched-004',
    method: 'BANK_TRANSFER',
    amount: 40858,
    reference: 'RTGS-293847',
    recordedAt: '2026-02-07T10:00:00Z',
    recordedBy: 'Ananya Sharma',
  },
  {
    id: 'pay-006',
    scheduleId: 'sched-005',
    method: 'UPI',
    amount: 20000,
    reference: 'UPI-102938475',
    recordedAt: '2026-02-20T15:00:00Z',
    recordedBy: 'Ananya Sharma',
  },

  // Kapoor-Singh payments
  {
    id: 'pay-007',
    scheduleId: 'sched-008',
    method: 'BANK_TRANSFER',
    amount: 38940,
    reference: 'NEFT-4829374',
    recordedAt: '2026-02-19T12:00:00Z',
    recordedBy: 'Raj Kumar',
  },
];

// ─── Helper Functions ───────────────────────────────────────

/**
 * Get payment schedules for a specific event
 */
export const getSchedulesForEvent = (eventId: string): EventPaymentSchedule[] => {
  return MOCK_PAYMENT_SCHEDULES.filter((s) => s.eventId === eventId).map((s) => ({
    ...s,
    status: calculateScheduleStatus(s.dueDate, s.amount, s.amountPaid),
  }));
};

/**
 * Get financial summary for an event
 */
export const getEventFinancialSummary = (
  eventId: string,
  proposalId: string,
  proposalGrandTotal: number
): EventFinancialSummaryData => {
  const schedules = getSchedulesForEvent(eventId);
  return calculateFinancialSummary(eventId, proposalId, proposalGrandTotal, schedules);
};

/**
 * Get payments for a specific schedule
 */
export const getPaymentsForSchedule = (scheduleId: string): MockPaymentRecord[] => {
  return MOCK_PAYMENT_RECORDS.filter((p) => p.scheduleId === scheduleId);
};

// ─── Financial Summary Examples ─────────────────────────────

export const MOCK_FINANCIAL_SUMMARIES: Record<string, EventFinancialSummaryData> = {
  'evt-001': calculateFinancialSummary(
    'evt-001',
    'prop-001',
    211084,
    MOCK_PAYMENT_SCHEDULES.filter((s) => s.eventId === 'evt-001')
  ),
  'evt-002': calculateFinancialSummary(
    'evt-002',
    'prop-002',
    81715,
    MOCK_PAYMENT_SCHEDULES.filter((s) => s.eventId === 'evt-002')
  ),
  'evt-003': calculateFinancialSummary(
    'evt-003',
    'prop-003',
    18408,
    MOCK_PAYMENT_SCHEDULES.filter((s) => s.eventId === 'evt-003')
  ),
  'evt-005': calculateFinancialSummary(
    'evt-005',
    'prop-004',
    129800,
    MOCK_PAYMENT_SCHEDULES.filter((s) => s.eventId === 'evt-005')
  ),
};
