using System;

namespace FloristERP.Domain
{
    public enum AccountType
    {
        Asset,
        Liability,
        Income,
        Expense,
        Equity
    }

    public class Account
    {
        public Guid Id { get; set; }
        public Guid CompanyId { get; set; }
        public string Code { get; set; }
        public string Name { get; set; }
        public AccountType AccountType { get; set; }
        public Guid? ParentAccountId { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
