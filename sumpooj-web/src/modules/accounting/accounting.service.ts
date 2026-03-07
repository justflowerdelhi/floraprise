
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

export const getAccounts = async () => {
  const res = await api.get('/accounting/accounts');
  return res.data;
};

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

export const getExpenses = async () => {
  const res = await api.get('/accounting/expenses');
  return res.data;
};

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
  const res = await api.get('/accounting/journal');
  return res.data;
};

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
  const res = await api.get('/accounting/ledger');
  return res.data;
};

export const getAccountLedgerData = async (accountId?: string) => {
  const res = await api.get('/accounting/ledger', { params: accountId ? { accountId } : {} });
  return res.data;
};