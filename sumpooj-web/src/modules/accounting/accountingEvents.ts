import { createJournalEntry } from "./accounting.service";
import type { JournalEntry } from "./types";

export function postAccountingEvent(type: string, payload: any) {

  const date = new Date().toISOString().slice(0, 10);

  if (type === "SALE") {

    createJournalEntry({
      id: "JE-" + Date.now(),
      date,
      reference: "SALE",
      description: "POS Sale",
      location: payload.location || "Main",
      lines: [
        {
          accountId: "cash",
          debit: payload.amount,
          credit: 0
        },
        {
          accountId: "sales",
          debit: 0,
          credit: payload.amount
        }
      ]
    });

  }

  if (type === "EXPENSE") {

    createJournalEntry({
      id: "JE-" + Date.now(),
      date,
      reference: "EXPENSE",
      description: "Expense Payment",
      location: payload.location || "Main",
      lines: [
        {
          accountId: "expense",
          debit: payload.amount,
          credit: 0
        },
        {
          accountId: "cash",
          debit: 0,
          credit: payload.amount
        }
      ]
    });

  }

}