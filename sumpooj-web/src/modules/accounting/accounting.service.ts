import type { JournalEntry, LedgerRow } from "./types";
import { postAccountingEvent } from "./accountingEvents";

/* ---------------- STORAGE ---------------- */

let journalEntries: JournalEntry[] = [];
let expenses: any[] = [];

/* ---------------- ACCOUNTS ---------------- */

export const accounts = [
  { id: "cash", code: "1000", name: "Cash", type: "Asset" },
  { id: "inventory", code: "1200", name: "Inventory", type: "Asset" },
  { id: "sales", code: "4000", name: "Sales Revenue", type: "Income" },
  { id: "expense", code: "5000", name: "Expenses", type: "Expense" },
  { id: "cogs", code: "5001", name: "Cost of Goods Sold", type: "Expense" },
  { id: "taxPayable", code: "2100", name: "Tax Payable", type: "Liability" }
];

export function getAccounts() {
  return accounts;
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
};

export const getJournalEntries = () => journalEntries;

/* ---------------- EXPENSES ---------------- */

export function addExpense(data: any) {

  const expense = { id: "EXP-" + Date.now(), ...data };
  expenses.push(expense);

  postAccountingEvent("EXPENSE", {
    amount: data.amount,
    location: data.location || "Main"
  });

  return expense;
}

export const getExpenses = () => expenses;

/* ---------------- TRIAL BALANCE ---------------- */

export function getTrialBalance() {

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

/* ---------------- LEDGER ---------------- */

export function getAccountLedgerData({ accountId }: any): LedgerRow[] {

  let balance = 0;

  return journalEntries
    .flatMap(entry =>
      entry.lines
        .filter(line => line.accountId === accountId)
        .map(line => {
          balance += (line.debit || 0) - (line.credit || 0);
          return {
            date: entry.date,
            reference: entry.reference,
            description: entry.description,
            debit: line.debit || 0,
            credit: line.credit || 0,
            balance
          };
        })
    );
}

/* ---------------- PROFIT & LOSS ---------------- */

export function getProfitLossReportData() {

  const trial = getTrialBalance();

  let revenue = 0;
  let expenses = 0;

  trial.forEach((row: any) => {

    if (row.code.startsWith("4")) revenue += row.credit - row.debit;
    if (row.code.startsWith("5")) expenses += row.debit - row.credit;

  });

  return {
    totalRevenue: revenue,
    totalExpenses: expenses,
    grossProfit: revenue,
    netProfit: revenue - expenses
  };
}

/* ---------------- DASHBOARD ---------------- */

export function getAccountingDashboardData() {

  const pnl = getProfitLossReportData();

  return {
    revenue: pnl.totalRevenue,
    expenses: pnl.totalExpenses,
    grossProfit: pnl.grossProfit,
    netProfit: pnl.netProfit,
    taxPayable: 0
  };
}

/* ---------------- DAILY SUMMARY ---------------- */

export function getDailyFinancialSummary() {

  const pnl = getProfitLossReportData();
  const cash = getTrialBalance().find((a: any) => a.code === "1000");

  return {
    salesToday: pnl.totalRevenue,
    expensesToday: pnl.totalExpenses,
    profitToday: pnl.netProfit,
    cashInDrawer: (cash?.debit || 0) - (cash?.credit || 0)
  };
}

// ---------------- TAX SUMMARY ----------------

export function getTaxSummaryData() {
  return [
    {
      taxType: "GST",
      taxableAmount: 0,
      taxAmount: 0
    }
  ];
}