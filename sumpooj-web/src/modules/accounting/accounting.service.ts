export function getTrialBalance() {
  const balance: any = {};
  journalEntries.forEach(entry => {
    entry.lines.forEach(line => {
      if (!balance[line.accountId])
        balance[line.accountId] = 0;
      balance[line.accountId] += line.debit - line.credit;
    });
  });
  return balance;
}
export function postExpense({
  amount,
  expenseAccount,
  location,
  reference
}: any) {
  createJournalEntry({
    date: new Date().toISOString().slice(0,10),
    reference,
    description: "Expense",
    location,
    lines: [
      {
        accountId: expenseAccount,
        debit: amount,
        credit: 0
      },
      {
        accountId: "cash",
        debit: 0,
        credit: amount
      }
    ]
  });
}
export function postWalkInSale({
  amount,
  location
}: any) {
  createJournalEntry({
    date: new Date().toISOString().slice(0,10),
    reference: "SALE-" + Date.now(),
    description: "Walk-in sale",
    location,
    lines: [
      {
        accountId: "cash",
        debit: amount,
        credit: 0
      },
      {
        accountId: "sales",
        debit: 0,
        credit: amount
      }
    ]
  });
}
import type { JournalEntry, LedgerRow } from "./types";

// ---------------- REFERENCE TYPES ----------------

export const referenceTypes = [
  { value: "SALE", label: "Sale Order" },
  { value: "EXPENSE", label: "Expense" },
  { value: "PURCHASE", label: "Purchase Order" },
  { value: "ADJUSTMENT", label: "Inventory Adjustment" },
  { value: "OTHER", label: "Other" }
];

// ---------------- TAX TYPES ----------------

export const taxTypes = [
  { value: "SALES_TAX", label: "Sales Tax" },
  { value: "GST", label: "GST" },
  { value: "VAT", label: "VAT" },
  { value: "SERVICE_TAX", label: "Service Tax" }
];

// Floraprise Accounting Service — wired to backend APIs

import api from '../../api/axios';

// ---------------- LOCATIONS ----------------

export const locations = [
  { id: 1, name: "Main Store" },
  { id: 2, name: "Downtown Branch" }
]

// ---------------- DASHBOARD ----------------

export const getAccountingDashboardData = async () => {
  const res = await api.get('/accounting/dashboard');
  return res.data;
};

// ---------------- ACCOUNTS ----------------

<<<<<<< HEAD
export function getAccounts() {
  return [
    { id: "cash", code: "1000", name: "Cash" },
    { id: "sales", code: "4000", name: "Sales Revenue" },
    { id: "expense", code: "5000", name: "Expenses" }
  ];
}
=======
export const getAccounts = async () => {
  const res = await api.get('/accounting/accounts');
  return res.data;
};
>>>>>>> 6132b76c6fe162bd9d1045805a855f1ebaf7223c

export const addAccount = async (data: any) => {
  const res = await api.post('/accounting/accounts', data);
  return res.data;
};
export const createAccount = addAccount;

export const updateAccount = async (data: any) => {
  const res = await api.put(`/accounting/accounts/${data.id}`, data);
  return res.data;
};

export const disableAccount = async (id: number | string) => {
  await api.put(`/accounting/accounts/${id}/disable`);
};

export const enableAccount = async (id: number | string) => {
  await api.put(`/accounting/accounts/${id}/enable`);
};

export const deleteAccount = disableAccount;

// ---------------- EXPENSES ----------------

<<<<<<< HEAD
let expenses: any[] = [];

export function getExpenses() {
  return expenses;
}
=======
export const getExpenses = async () => {
  const res = await api.get('/accounting/expenses');
  return res.data;
};
>>>>>>> 6132b76c6fe162bd9d1045805a855f1ebaf7223c

export const addExpense = async (data: any) => {
  const res = await api.post('/accounting/expenses', data);
  return res.data;
};
export const createExpense = addExpense;

export const updateExpense = async (data: any) => {
  const res = await api.put(`/accounting/expenses/${data.id}`, data);
  return res.data;
};

export const disableExpense = async (id: number | string) => {
  await api.put(`/accounting/expenses/${id}/disable`);
};
export const enableExpense = disableExpense;
export const deleteExpense = disableExpense;

// ---------------- JOURNAL ----------------

export const getJournalEntries = async () => {
<<<<<<< HEAD
  return journalEntries;
};

export const addJournalEntry = async (data: JournalEntry) => {
  journalEntries.push(data);
};

export function postJournalEntry(entry: JournalEntry) {
  journalEntries.push(entry);
}
=======
  const res = await api.get('/accounting/journal');
  return res.data;
};
>>>>>>> 6132b76c6fe162bd9d1045805a855f1ebaf7223c

// ---------------- PROFIT & LOSS ----------------

export const getProfitLoss = async () => {
  const res = await api.get('/accounting/profit-loss');
  return res.data;
};

export const getProfitLossReportData = getProfitLoss;

// ---------------- TAX ----------------

export const getTaxSummary = async () => {
  const res = await api.get('/accounting/tax-summary');
  return res.data;
};

export const getTaxSummaryData = getTaxSummary;

// ---------------- LEDGER ----------------

export const getLedger = async () => {
<<<<<<< HEAD
  return ledgerRows;
};

export function getAccountLedgerData({
  accountId,
  dateFrom,
  dateTo,
  location
}: any): LedgerRow[] {

  let rows: LedgerRow[] = [];
  let balance = 0;

  journalEntries.forEach(entry => {
    if (location && entry.location !== location) return;

    entry.lines.forEach(line => {
      if (line.accountId !== accountId) return;

      balance += line.debit - line.credit;

      rows.push({
        date: entry.date,
        reference: entry.reference,
        description: entry.description,
        debit: line.debit,
        credit: line.credit,
        balance
      });
    });
  });

  return rows;
}

let journalEntries: JournalEntry[] = [];
let ledgerRows: LedgerRow[] = [];

journalEntries.push({
  id: "J1",
  date: "2026-03-07",
  reference: "SALE-1001",
  description: "Walk-in sale",
  location: "Main",
  lines: [
    {
      accountId: "cash",
      debit: 120,
      credit: 0
    }
  ]
});

export function createJournalEntry({
  date,
  reference,
  description,
  location,
  lines
}: any) {
  const entry = {
    id: "J" + Date.now(),
    date,
    reference,
    description,
    location,
    lines
  };
  journalEntries.push(entry);
  return entry;
}
journalEntries.push({
  id: "J1",
  date: "2026-03-07",
  reference: "SALE-1001",
  description: "Walk-in sale",
  location: "Main",
  lines: [
    {
      accountId: "cash",
      debit: 120,
      credit: 0
    },
    {
      accountId: "sales",
      debit: 0,
      credit: 120
    }
  ]
});
=======
  const res = await api.get('/accounting/ledger');
  return res.data;
};

export const getAccountLedgerData = async (accountId?: string) => {
  const res = await api.get('/accounting/ledger', { params: accountId ? { accountId } : {} });
  return res.data;
};
>>>>>>> 6132b76c6fe162bd9d1045805a855f1ebaf7223c
