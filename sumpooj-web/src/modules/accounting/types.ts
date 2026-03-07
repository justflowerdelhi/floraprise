// Journal line inside a journal entry
export interface JournalLine {
  accountId: string
  debit: number
  credit: number
}

// Journal entry
export interface JournalEntry {
  id: string
  date: string
  reference: string
  description: string
  location: string
  lines: JournalLine[]
}

// Ledger row (derived from journal)
export interface LedgerRow {
  date: string
  reference: string
  description: string
  debit: number
  credit: number
  balance: number
}