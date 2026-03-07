using System;

namespace FlorapriseERP.Accounting
{
    public enum ExpenseCategory
    {
        Utilities,
        Rent,
        Supplies,
        Travel,
        Marketing,
        Other
    }

    public enum PaymentMethod
    {
        Cash,
        Bank,
        Card,
        UPI,
        Other
    }

    public class Expense
    {
        public Guid Id { get; set; }
        public Guid CompanyId { get; set; }
        public Guid LocationId { get; set; }
        public DateTime Date { get; set; }
        public ExpenseCategory ExpenseCategory { get; set; }
        public Guid AccountId { get; set; }
        public decimal Amount { get; set; }
        public PaymentMethod PaymentMethod { get; set; }
        public string Vendor { get; set; }
        public string Notes { get; set; }
        public string AttachmentUrl { get; set; }
        public Guid CreatedBy { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
