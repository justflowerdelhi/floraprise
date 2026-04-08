using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using Sumpooj.Application.Companies;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Services;

public class PurchaseOrderPdfService
{
    private readonly ISupplierRepository _supplierRepository;
    private readonly ICompanyService _companyService;

    public PurchaseOrderPdfService(
        ISupplierRepository supplierRepository,
        ICompanyService companyService)
    {
        _supplierRepository = supplierRepository;
        _companyService = companyService;
    }

    public byte[] GeneratePdf(PurchaseOrder po)
    {
        QuestPDF.Settings.License = LicenseType.Community;

        var supplierName = ResolveSupplierName(po.SupplierId).GetAwaiter().GetResult();
        var companyName = ResolveCompanyName(po.CompanyId).GetAwaiter().GetResult();

        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(24);
                page.DefaultTextStyle(x => x.FontSize(10));

                page.Content().Column(col =>
                {
                    col.Spacing(10);

                    col.Item().Text("Purchase Order").FontSize(20).Bold();

                    col.Item().Text($"Company: {companyName}");
                    col.Item().Text($"Supplier: {supplierName}");
                    col.Item().Text($"Order Number: {po.OrderNumber}");
                    col.Item().Text($"Order Date: {po.OrderDate:dd MMM yyyy}");
                    col.Item().Text($"Expected Delivery Date: {po.ExpectedDeliveryDate:dd MMM yyyy}");

                    col.Item().PaddingTop(8).Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.RelativeColumn(4); // Product
                            columns.RelativeColumn(1); // Qty
                            columns.RelativeColumn(2); // Expected Price
                            columns.RelativeColumn(2); // Total
                        });

                        table.Header(header =>
                        {
                            header.Cell().Text("Product").Bold();
                            header.Cell().Text("Qty").Bold();
                            header.Cell().Text("Expected Price").Bold();
                            header.Cell().Text("Total").Bold();
                        });

                        foreach (var item in po.Items)
                        {
                            table.Cell().Text(item.ProductName);
                            table.Cell().Text(item.Quantity.ToString());
                            table.Cell().Text(item.ExpectedPrice.ToString("0.##"));
                            table.Cell().Text(item.TotalPrice.ToString("0.##"));
                        }
                    });

                    if (!string.IsNullOrWhiteSpace(po.Notes))
                    {
                        col.Item().PaddingTop(8).Text($"Notes: {po.Notes}");
                    }
                });
            });
        });

        return document.GeneratePdf();
    }

    private async Task<string> ResolveSupplierName(Guid supplierId)
    {
        var supplier = await _supplierRepository.GetByIdAsync(supplierId);
        return supplier?.Name ?? "Unknown Supplier";
    }

    private async Task<string> ResolveCompanyName(Guid companyId)
    {
        var company = await _companyService.GetByIdAsync(companyId);
        return company?.Name ?? companyId.ToString();
    }
}
