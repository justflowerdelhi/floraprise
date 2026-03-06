
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

export const getAccounts = async () => [
  { id: 1, code: "1001", name: "Cash", type: "Asset", isActive: true },
  { id: 2, code: "4001", name: "Retail Sales", type: "Income", isActive: true },
  { id: 3, code: "5001", name: "Fuel Expense", type: "Expense", isActive: true }
]

export const addAccount = async (data:any) => { console.log("addAccount", data) }
export const createAccount = async (data:any) => { console.log("createAccount", data) }
export const updateAccount = async (data:any) => { console.log("updateAccount", data) }

export const disableAccount = async (id:number) => { console.log("disableAccount", id) }
export const enableAccount = async (id:number) => { console.log("enableAccount", id) }
export const deleteAccount = async (id:number) => { console.log("deleteAccount", id) }

// ---------------- EXPENSES ----------------

export const getExpenses = async () => [
  { id: 1, category: "Fuel", amount: 30 },
  { id: 2, category: "Packaging", amount: 20 }
]

export const addExpense = async (data:any) => { console.log("addExpense", data) }
export const createExpense = async (data:any) => { console.log("createExpense", data) }
export const updateExpense = async (data:any) => { console.log("updateExpense", data) }

export const disableExpense = async (id:number) => { console.log("disableExpense", id) }
export const enableExpense = async (id:number) => { console.log("enableExpense", id) }
export const deleteExpense = async (id:number) => { console.log("deleteExpense", id) }

// ---------------- JOURNAL ----------------

export const getJournalEntries = async () => [
  {
    id: 1,
    date: "2026-03-12",
    reference: "Sale #1021",
    description: "Retail sale",
    debit: 150,
    credit: 0
  }
]

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

export const getLedger = async () => [
  {
    date: "2026-03-12",
    reference: "Sale #1021",
    description: "Retail Sale",
    debit: 150,
    credit: 0,
    balance: 150
  }
]

export const getAccountLedgerData = async () => [
  {
    date: "2026-03-12",
    reference: "Sale #1021",
    description: "Retail Sale",
    debit: 150,
    credit: 0,
    balance: 150
  },
  {
    date: "2026-03-12",
    reference: "Expense #201",
    description: "Fuel Expense",
    debit: 0,
    credit: 30,
    balance: 120
  }
]