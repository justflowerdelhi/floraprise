import { createJournalEntry } from "./accounting.service";

export type AccountingEventType =
  | "SALE"
  | "EXPENSE"
  | "PURCHASE"
  | "INVENTORY_ADJUSTMENT"
  | "REFUND"
  | "INVENTORY_SALE";

export function postAccountingEvent(type: AccountingEventType, payload: any) {

  const date = new Date().toISOString().slice(0,10);

  switch (type) {

    // ---------------- SALE ----------------
    case "SALE": {

      const { amount, location } = payload;

      createJournalEntry({
        date,
        reference: "SALE",
        description: "POS Sale",
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

      break;
    }

    // ---------------- EXPENSE ----------------
    case "EXPENSE": {

      const { amount, location } = payload;

      createJournalEntry({
        date,
        reference: "EXPENSE",
        description: "Expense Payment",
        location,
        lines: [
          {
            accountId: "expense",
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

      break;
    }

    // ---------------- INVENTORY_SALE ----------------
    case "INVENTORY_SALE": {
      const { cost, location } = payload;
      createJournalEntry({
        date,
        reference: "SALE",
        description: "Cost of Goods Sold",
        location,
        lines: [
          { accountId: "cogs", debit: cost, credit: 0 },
          { accountId: "inventory", debit: 0, credit: cost }
        ]
      });
      break;
    }

    default:
      console.warn("Unknown accounting event:", type);
  }

}