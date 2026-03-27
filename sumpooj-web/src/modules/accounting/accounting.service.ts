import type { JournalEntry, LedgerRow } from "./types";
import { postAccountingEvent } from "./accountingEvents";
import api from '../../api/axios';

/* ---------------- STORAGE (local event journal for same-session view) ---- */

let journalEntries: JournalEntry[] = [];

/* ---------------- ACCOUNTS ---------------- */

export const accounts = [
  { id: "cash", code: "1000", name: "Cash", type: "Asset" },
  { id: "inventory", code: "1200", name: "Inventory", type: "Asset" },
  { id: "sales", code: "4000", name: "Sales Revenue", type: "Income" },
  { id: "expense", code: "5000", name: "Expenses", type: "Expense" },
  { id: "cogs", code: "5001", name: "Cost of Goods Sold", type: "Expense" },
  { id: "taxPayable", code: "2100", name: "Tax Payable", type: "Liability" }
];

export async function getAccounts() {
  try {
    const res = await api.get('/accounting/accounts');
    return res.data;
  } catch {
    return accounts;
  }
}

/* ---------------- TAX TYPES ---------------- */

export const taxTypes = [
  { value: "GST", label: "GST" },
  { value: "VAT", label: "VAT" },
  { value: "SALES_TAX", label: "Sales Tax" }
];

/* ---------------- JOURNAL ---------------- */

export const createJournalEntry = (entry: JournalEntry) => {
  journalEntries.push(entry);
  // Also persist to backend
  api.post('/accounting/journal', {
    date: entry.date,
    reference: entry.reference,
    referenceType: entry.reference,
    description: entry.description,
    debit: entry.lines.reduce((s, l) => s + (l.debit || 0), 0),
    credit: entry.lines.reduce((s, l) => s + (l.credit || 0), 0),
    accountId: entry.lines[0]?.accountId || null,
  }).catch(() => {});
};

export async function getJournalEntries() {
  const res = await api.get('/accounting/journal');
  return res.data;
}

/* ---------------- EXPENSES ---------------- */

export async function addExpense(data: any) {
  postAccountingEvent("EXPENSE", {
    amount: data.amount,
    location: data.location || "Main"
  });

  const description = [data.vendor, data.notes].filter(Boolean).join(' | ') || undefined;
  const res = await api.post('/accounting/expenses', {
    category: data.category || 'Other',
    amount: data.amount,
    description,
    expenseDate: data.date,
  });
  return res.data;
}

export async function getExpenses() {
  try {
    const res = await api.get('/accounting/expenses');
    return res.data;
  } catch {
    return [];
  }
}

/* ---------------- TRIAL BALANCE ---------------- */

export async function getTrialBalance() {
  try {
    const res = await api.get('/accounting/trial-balance');
    return res.data;
  } catch {
    // Fallback: compute from local journal
    const balances: any = {};
    journalEntries.forEach(entry => {
      entry.lines.forEach(line => {
        if (!balances[line.accountId]) {
          balances[line.accountId] = { accountId: line.accountId, debit: 0, credit: 0 };
        }
        balances[line.accountId].debit += line.debit || 0;
        balances[line.accountId].credit += line.credit || 0;
      });
    });
    return Object.values(balances).map((row: any) => {
      const account = accounts.find(a => a.id === row.accountId);
      return { ...row, code: account?.code || "", name: account?.name || "" };
    });
  }
}

/* ---------------- LEDGER ---------------- */

export async function getAccountLedgerData({ accountId }: any): Promise<LedgerRow[]> {
  try {
    const res = await api.get('/accounting/ledger', { params: accountId ? { accountId } : {} });
    return res.data;
  } catch {
    let balance = 0;
    return journalEntries
      .flatMap(entry =>
        entry.lines
          .filter(line => line.accountId === accountId)
          .map(line => {
            balance += (line.debit || 0) - (line.credit || 0);
            return { date: entry.date, reference: entry.reference, description: entry.description, debit: line.debit || 0, credit: line.credit || 0, balance };
          })
      );
  }
}

/* ---------------- PROFIT & LOSS ---------------- */

export async function getProfitLossReportData() {
  try {
    const res = await api.get('/accounting/profit-loss');
    const d = res.data;
    return { totalRevenue: d.revenue, totalExpenses: d.expenses, cogs: d.cogs, grossProfit: d.grossProfit, netProfit: d.netProfit };
  } catch {
    return { totalRevenue: 0, totalExpenses: 0, cogs: 0, grossProfit: 0, netProfit: 0 };
  }
}

/* ---------------- DASHBOARD ---------------- */

export async function getAccountingDashboardData() {
  try {
    const res = await api.get('/accounting/dashboard');
    const d = res.data;
    return { revenue: d.revenueToday, expenses: d.expensesToday, grossProfit: d.profitToday, netProfit: d.profitToday, taxPayable: 0 };
  } catch {
    return { revenue: 0, expenses: 0, grossProfit: 0, netProfit: 0, taxPayable: 0 };
  }
}

/* ---------------- DAILY SUMMARY ---------------- */

export async function getDailyFinancialSummary() {
  try {
    const res = await api.get('/accounting/dashboard');
    const d = res.data;
    return { salesToday: d.revenueToday, expensesToday: d.expensesToday, profitToday: d.profitToday, cashInDrawer: d.cashBalance };
  } catch {
    return { salesToday: 0, expensesToday: 0, profitToday: 0, cashInDrawer: 0 };
  }
}

// ---------------- TAX SUMMARY ----------------

export async function getTaxSummaryData() {
  try {
    const res = await api.get('/accounting/tax-summary');
    return res.data;
  } catch {
    return [{ taxType: "GST", taxableAmount: 0, taxAmount: 0 }];
  }
}