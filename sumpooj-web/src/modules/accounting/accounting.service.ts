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

// Floraprise Accounting Mock Service
// Temporary mock layer until backend APIs are connected

// ---------------- DASHBOARD ----------------

export const getAccountingDashboardData = async () => {
  return {
    revenueToday: 1250,
    expensesToday: 180,
    profitToday: 1070,
    cashBalance: 3400,

    revenueTrend: [
      { day: "Mon", revenue: 200 },
      { day: "Tue", revenue: 320 },
      { day: "Wed", revenue: 280 },
      { day: "Thu", revenue: 400 },
      { day: "Fri", revenue: 500 },
      { day: "Sat", revenue: 620 },
      { day: "Sun", revenue: 450 }
    ],

    expenseTrend: [
      { day: "Mon", expense: 40 },
      { day: "Tue", expense: 60 },
      { day: "Wed", expense: 30 },
      { day: "Thu", expense: 50 },
      { day: "Fri", expense: 80 },
      { day: "Sat", expense: 120 },
      { day: "Sun", expense: 70 }
    ],

    topExpenseCategories: [
      { category: "Fuel", amount: 120 },
      { category: "Packaging", amount: 90 },
      { category: "Flowers Purchase", amount: 300 },
      { category: "Delivery", amount: 150 }
    ]
  };
};

// ---------------- LOCATIONS ----------------

export const locations = [
  { id: 1, name: "Main Store" },
  { id: 2, name: "Downtown Branch" }
]

// ---------------- ACCOUNTS ----------------

export function getAccounts() {
  return [
    { id: "cash", code: "1000", name: "Cash" },
    { id: "sales", code: "4000", name: "Sales Revenue" },
    { id: "expense", code: "5000", name: "Expenses" }
  ];
}

export const addAccount = async (data:any) => { console.log("addAccount", data) }
export const createAccount = async (data:any) => { console.log("createAccount", data) }
export const updateAccount = async (data:any) => { console.log("updateAccount", data) }

export const disableAccount = async (id:number) => { console.log("disableAccount", id) }
export const enableAccount = async (id:number) => { console.log("enableAccount", id) }
export const deleteAccount = async (id:number) => { console.log("deleteAccount", id) }

// ---------------- EXPENSES ----------------

let expenses: any[] = [];

export function getExpenses() {
  return expenses;
}

export const addExpense = async (data:any) => { console.log("addExpense", data) }
export const createExpense = async (data:any) => { console.log("createExpense", data) }
export const updateExpense = async (data:any) => { console.log("updateExpense", data) }

export const disableExpense = async (id:number) => { console.log("disableExpense", id) }
export const enableExpense = async (id:number) => { console.log("enableExpense", id) }
export const deleteExpense = async (id:number) => { console.log("deleteExpense", id) }

// ---------------- JOURNAL ----------------

export const getJournalEntries = async () => {
  return journalEntries;
};

export const addJournalEntry = async (data: JournalEntry) => {
  journalEntries.push(data);
};

export function postJournalEntry(entry: JournalEntry) {
  journalEntries.push(entry);
}

// ---------------- PROFIT & LOSS ----------------

export const getProfitLoss = async () => ({
  revenue: 12000,
  cogs: 4500,
  expenses: 3000,
  grossProfit: 7500,
  netProfit: 4500
})

// Alias used by ProfitLossReport page
export const getProfitLossReportData = async () => {
  return getProfitLoss();
};

// ---------------- TAX ----------------

export const getTaxSummary = async () => [
  {
    taxType: "Sales Tax",
    rate: 8,
    taxableAmount: 10000,
    taxAmount: 800
  }

]

// Alias used by TaxReport page
export const getTaxSummaryData = async () => {
  return getTaxSummary();
};

// ---------------- LEDGER ----------------

export const getLedger = async () => {
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