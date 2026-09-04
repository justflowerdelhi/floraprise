namespace Sumpooj.Domain.Entities;

public class MorningPurchaseListItem : BaseEntity
{
    private MorningPurchaseListItem() { }

    public MorningPurchaseListItem(Guid companyId, DateTime listDate, Guid productId, string productName,
        string category, int quantity, string unit, string? supplier, string priority, string? remarks)
    {
        CompanyId = companyId;
        ProductId = productId;
        ListDate = EnsureUtc(listDate).Date;
        Update(productName, category, quantity, unit, supplier, priority, remarks);
    }

    public Guid CompanyId { get; private set; }
    public DateTime ListDate { get; private set; }
    public Guid ProductId { get; private set; }
    public string ProductName { get; private set; } = default!;
    public string Category { get; private set; } = default!;
    public int Quantity { get; private set; }
    public string Unit { get; private set; } = default!;
    public string Supplier { get; private set; } = string.Empty;
    public string Priority { get; private set; } = "Normal";
    public string Remarks { get; private set; } = string.Empty;
    public bool Purchased { get; private set; }
    public bool InventoryUpdated { get; private set; }
    public DateTime? DeletedAtUtc { get; private set; }

    public void Update(string productName, string category, int quantity, string unit,
        string? supplier, string priority, string? remarks)
    {
        if (quantity <= 0) throw new InvalidOperationException("Quantity must be greater than zero.");
        if (string.IsNullOrWhiteSpace(productName)) throw new InvalidOperationException("Product name is required.");
        ProductName = productName.Trim();
        Category = string.IsNullOrWhiteSpace(category) ? "Others" : category.Trim();
        Quantity = quantity;
        Unit = string.IsNullOrWhiteSpace(unit) ? "Piece" : unit.Trim();
        Supplier = supplier?.Trim() ?? string.Empty;
        Priority = string.IsNullOrWhiteSpace(priority) ? "Normal" : priority.Trim();
        Remarks = remarks?.Trim() ?? string.Empty;
        MarkUpdated();
    }

    public void SetPurchased(bool purchased) { Purchased = purchased; MarkUpdated(); }
    public void MarkInventoryUpdated() { InventoryUpdated = true; MarkUpdated(); }
    public void Delete() { DeletedAtUtc = DateTime.UtcNow; MarkUpdated(); }
}

public class Associate : BaseEntity
{
    private Associate() { }

    public Associate(Guid companyId, string associateCode, string businessName, string phone)
    {
        CompanyId = companyId;
        AssociateCode = associateCode.Trim();
        BusinessName = businessName.Trim();
        Phone = phone.Trim();
    }

    public Guid CompanyId { get; private set; }
    public string AssociateCode { get; private set; } = default!;
    public string BusinessName { get; private set; } = default!;
    public string? ContactPerson { get; private set; }
    public string Phone { get; private set; } = default!;
    public string? Whatsapp { get; private set; }
    public string? Email { get; private set; }
    public string City { get; private set; } = string.Empty;
    public string? State { get; private set; }
    public string Pincode { get; private set; } = string.Empty;
    public string? Address { get; private set; }
    public string? GstNumber { get; private set; }
    public string? Website { get; private set; }
    public string? Notes { get; private set; }
    public string Types { get; private set; } = "Other";
    public bool IsActive { get; private set; } = true;
    public DateTime? DeletedAtUtc { get; private set; }

    public void Update(string businessName, string? contactPerson, string phone, string? whatsapp,
        string? email, string city, string? state, string pincode, string? address,
        string? gstNumber, string? website, string? notes, IEnumerable<string> types, bool isActive)
    {
        if (string.IsNullOrWhiteSpace(businessName)) throw new InvalidOperationException("Business name is required.");
        if (string.IsNullOrWhiteSpace(phone)) throw new InvalidOperationException("Phone is required.");
        var values = types.Select(t => t.Trim()).Where(t => t.Length > 0).Distinct(StringComparer.OrdinalIgnoreCase).ToList();
        BusinessName = businessName.Trim();
        ContactPerson = Clean(contactPerson);
        Phone = phone.Trim();
        Whatsapp = Clean(whatsapp);
        Email = Clean(email);
        City = city?.Trim() ?? string.Empty;
        State = Clean(state);
        Pincode = pincode?.Trim() ?? string.Empty;
        Address = Clean(address);
        GstNumber = Clean(gstNumber);
        Website = Clean(website);
        Notes = Clean(notes);
        Types = values.Count == 0 ? "Other" : string.Join(',', values);
        IsActive = isActive;
        if (isActive) DeletedAtUtc = null;
        MarkUpdated();
    }

    public void Deactivate() { IsActive = false; MarkUpdated(); }
    public void Reactivate() { IsActive = true; DeletedAtUtc = null; MarkUpdated(); }
    public void Delete() { IsActive = false; DeletedAtUtc = DateTime.UtcNow; MarkUpdated(); }
    private static string? Clean(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}