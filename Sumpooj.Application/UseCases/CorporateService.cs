using Sumpooj.Application.Common;
using Sumpooj.Application.Corporate;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class CorporateService
{
    private readonly ICorporateRepository _corporateRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IOrderRepository _orderRepository;
    private readonly IProductRepository _productRepository;
    private readonly ILocationRepository _locationRepository;
    private readonly IShiftRepository _shiftRepository;
    private readonly IJournalEntryRepository _journalEntryRepository;
    private readonly IDeliveryRepository _deliveryRepository;

    public CorporateService(
        ICorporateRepository corporateRepository,
        ICustomerRepository customerRepository,
        IOrderRepository orderRepository,
        IProductRepository productRepository,
        ILocationRepository locationRepository,
        IShiftRepository shiftRepository,
        IJournalEntryRepository journalEntryRepository,
        IDeliveryRepository deliveryRepository)
    {
        _corporateRepository = corporateRepository;
        _customerRepository = customerRepository;
        _orderRepository = orderRepository;
        _productRepository = productRepository;
        _locationRepository = locationRepository;
        _shiftRepository = shiftRepository;
        _journalEntryRepository = journalEntryRepository;
        _deliveryRepository = deliveryRepository;
    }

    public Task<PagedResult<CorporateClientDto>> SearchClientsAsync(Guid companyId, string? query, bool? isActive, int page, int pageSize)
    {
        return _corporateRepository.SearchClientsAsync(companyId, query, isActive, page, pageSize);
    }

    public async Task<CorporateClientDto> CreateClientAsync(Guid companyId, CreateCorporateClientRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            throw new InvalidOperationException("Client name is required.");
        if (string.IsNullOrWhiteSpace(request.BillingEmail))
            throw new InvalidOperationException("Billing email is required.");

        var customer = new Customer(
            companyId,
            request.Name.Trim(),
            request.BillingEmail.Trim(),
            request.Phone?.Trim());

        await _customerRepository.AddAsync(customer);

        var client = new CorporateClient(
            companyId,
            customer.Id,
            request.Name.Trim(),
            request.BillingEmail.Trim(),
            request.Phone?.Trim(),
            request.CreditLimit,
            request.PaymentTerms?.Trim(),
            string.IsNullOrWhiteSpace(request.BillingCycle) ? "MONTHLY" : request.BillingCycle.Trim().ToUpperInvariant(),
            request.DefaultProductId,
            request.DefaultMessage?.Trim());

        await _corporateRepository.AddClientAsync(client);

        return new CorporateClientDto
        {
            Id = client.Id,
            CustomerId = client.CustomerId,
            Name = client.Name,
            BillingEmail = client.BillingEmail,
            Phone = client.Phone,
            CreditLimit = client.CreditLimit,
            PaymentTerms = client.PaymentTerms,
            BillingCycle = client.BillingCycle,
            DefaultProductId = client.DefaultProductId,
            DefaultMessage = client.DefaultMessage,
            IsActive = client.IsActive,
            OutstandingAmount = 0,
            ActiveEmployees = 0,
            CreatedAtUtc = client.CreatedAtUtc
        };
    }

    public async Task<CorporateEmployeeDto> AddEmployeeAsync(Guid companyId, Guid clientId, CreateCorporateEmployeeRequest request)
    {
        var client = await _corporateRepository.GetClientByIdAsync(companyId, clientId)
            ?? throw new KeyNotFoundException("Corporate client not found.");

        if (!client.IsActive)
            throw new InvalidOperationException("Cannot add employees to an inactive corporate client.");

        var employee = new CorporateEmployee(
            companyId,
            clientId,
            request.Name.Trim(),
            request.DateOfBirth,
            request.Address?.Trim());

        await _corporateRepository.AddEmployeeAsync(employee);

        return new CorporateEmployeeDto
        {
            Id = employee.Id,
            ClientId = employee.ClientId,
            Name = employee.Name,
            DateOfBirth = employee.DateOfBirth,
            Address = employee.Address,
            IsActive = employee.IsActive
        };
    }

    public Task<List<CorporateEmployeeDto>> GetEmployeesAsync(Guid companyId, Guid clientId, bool activeOnly)
    {
        return _corporateRepository.GetEmployeesAsync(companyId, clientId, activeOnly);
    }

    public Task<List<PendingCorporateApprovalOrderDto>> GetPendingApprovalOrdersAsync(Guid companyId)
    {
        return _corporateRepository.GetPendingAutoCreatedOrdersAsync(companyId);
    }

    public async Task<CreateCorporateOrderResponse> CreateCorporateOrderAsync(Guid companyId, CreateCorporateOrderRequest request)
    {
        var client = await _corporateRepository.GetClientByIdAsync(companyId, request.ClientId)
            ?? throw new KeyNotFoundException("Corporate client not found.");

        if (!client.IsActive)
            throw new InvalidOperationException("Corporate client is inactive.");

        if (request.Items.Count == 0)
            throw new InvalidOperationException("At least one order item is required.");

        var locationId = request.LocationId;
        if (!locationId.HasValue || locationId.Value == Guid.Empty)
        {
            var defaultLocation = await _locationRepository.GetDefaultAsync(companyId)
                ?? throw new InvalidOperationException("LocationId is required when creating a corporate order.");
            locationId = defaultLocation.Id;
        }

        var location = await _locationRepository.GetByIdAsync(locationId.Value)
            ?? throw new InvalidOperationException("Location not found.");

        if (location.CompanyId != companyId || !location.IsActive)
            throw new InvalidOperationException("Invalid active location for this company.");

        var activeShift = await _shiftRepository.GetActiveShiftAsync(companyId, locationId.Value);
        if (activeShift == null)
            throw new InvalidOperationException("No active shift for this location. Please open shift before creating corporate order.");

        var order = new Order(
            companyId,
            client.CustomerId,
            request.DeliveryDate,
            request.DeliveryAddress,
            request.DeliveryPincode,
            request.RecipientName,
            request.RecipientPhone);

        order.LocationId = locationId;
        order.SetCustomerType(CustomerType.Corporate);
        order.SetOrderSource(OrderSource.Phone);
        order.SetFulfillmentStatus(FulfillmentStatus.Confirmed);

        if (!string.IsNullOrWhiteSpace(request.Message))
            order.SetCardMessage(request.Message.Trim());
        else if (!string.IsNullOrWhiteSpace(client.DefaultMessage))
            order.SetCardMessage(client.DefaultMessage);

        if (!string.IsNullOrWhiteSpace(request.TimeSlot))
            order.SetTimeSlot(request.TimeSlot);

        foreach (var item in request.Items)
        {
            order.AddItem(item.ProductId, item.ProductName, item.Quantity, item.UnitPrice);
        }

        order.Confirm();

        // Corporate orders are credit sales.
        order.MarkCredit();

        await _orderRepository.AddAsync(order);

        var isDelivery = string.Equals(request.OrderType, "DELIVERY", StringComparison.OrdinalIgnoreCase);
        if (isDelivery)
        {
            if (string.IsNullOrWhiteSpace(request.DeliveryAddress) || string.IsNullOrWhiteSpace(request.TimeSlot))
                throw new InvalidOperationException("Delivery address and time slot are required for delivery orders.");

            var existingDelivery = await _deliveryRepository.GetBySalesOrderIdAsync(order.Id);
            if (existingDelivery == null)
            {
                var delivery = new Delivery(companyId, order.Id, request.DeliveryDate, request.TimeSlot!, request.DeliveryAddress!);
                if (!string.IsNullOrWhiteSpace(request.DeliveryPincode))
                    delivery.SetPostalCode(request.DeliveryPincode);
                await _deliveryRepository.AddAsync(delivery);
            }
        }

        var orderMeta = new CorporateOrderMeta(
            companyId,
            order.Id,
            client.Id,
            CorporateBillingStatus.Pending,
            null,
            isAutoCreated: false,
            needsApproval: false,
            automationDateUtc: null);

        await _corporateRepository.AddOrderMetaAsync(orderMeta);

        await CreateCorporateRevenueJournalAsync(companyId, order, client.Name);
        orderMeta.MarkAccountingPosted();
        await _corporateRepository.UpdateOrderMetaAsync(orderMeta);

        var outstandingAfter = await _corporateRepository.GetClientOutstandingAsync(companyId, client.Id);
        var creditLimitExceeded = client.CreditLimit.HasValue && outstandingAfter > client.CreditLimit.Value;

        return new CreateCorporateOrderResponse
        {
            OrderId = order.Id,
            OrderNumber = order.OrderNumber,
            CorporateClientId = client.Id,
            CreditLimitExceeded = creditLimitExceeded
        };
    }

    public async Task ApproveAutoCreatedOrderAsync(Guid companyId, Guid orderId)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, orderId)
            ?? throw new KeyNotFoundException("Order not found.");

        var meta = await _corporateRepository.GetOrderMetaByOrderIdAsync(companyId, orderId)
            ?? throw new KeyNotFoundException("Corporate order metadata not found.");

        if (!meta.NeedsApproval)
            return;

        order.Confirm();
        await _orderRepository.UpdateAsync(order);

        meta.MarkApproved();
        await _corporateRepository.UpdateOrderMetaAsync(meta);

        if (!meta.IsAccountingPosted)
        {
            var client = await _corporateRepository.GetClientByIdAsync(companyId, meta.ClientId)
                ?? throw new KeyNotFoundException("Corporate client not found.");

            await CreateCorporateRevenueJournalAsync(companyId, order, client.Name);
            meta.MarkAccountingPosted();
            await _corporateRepository.UpdateOrderMetaAsync(meta);
        }
    }

    public async Task CancelAutoCreatedOrderAsync(Guid companyId, Guid orderId, string? reason)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, orderId)
            ?? throw new KeyNotFoundException("Order not found.");

        var meta = await _corporateRepository.GetOrderMetaByOrderIdAsync(companyId, orderId)
            ?? throw new KeyNotFoundException("Corporate order metadata not found.");

        if (!meta.IsAutoCreated)
            throw new InvalidOperationException("Only auto-created corporate orders can be cancelled from approval flow.");

        order.Cancel(reason ?? "Cancelled from corporate approval queue");
        await _orderRepository.UpdateAsync(order);
    }

    public async Task<CorporateInvoiceDto> GenerateMonthlyInvoiceAsync(Guid companyId, GenerateCorporateInvoiceRequest request)
    {
        var client = await _corporateRepository.GetClientByIdAsync(companyId, request.ClientId)
            ?? throw new KeyNotFoundException("Corporate client not found.");

        var metas = await _corporateRepository.GetPendingOrderMetaForInvoiceAsync(
            companyId,
            request.ClientId,
            request.StartDate,
            request.EndDate);

        if (metas.Count == 0)
            throw new InvalidOperationException("No pending corporate orders found for invoicing period.");

        var total = metas.Sum(x => x.Order?.TotalAmount ?? 0m);

        var invoice = new CorporateInvoice(companyId, request.ClientId, request.StartDate, request.EndDate, total);

        foreach (var meta in metas)
        {
            if (meta.Order == null)
                continue;

            invoice.AddLine(meta.OrderId, meta.Order.OrderNumber, meta.Order.OrderDate, meta.Order.TotalAmount);
            meta.MarkBillingStatus(CorporateBillingStatus.Invoiced);
        }

        await _corporateRepository.AddInvoiceAsync(invoice);

        foreach (var meta in metas)
            await _corporateRepository.UpdateOrderMetaAsync(meta);

        return new CorporateInvoiceDto
        {
            Id = invoice.Id,
            ClientId = invoice.ClientId,
            StartDateUtc = invoice.StartDateUtc,
            EndDateUtc = invoice.EndDateUtc,
            TotalAmount = invoice.TotalAmount,
            Status = invoice.Status,
            PaidAtUtc = invoice.PaidAtUtc,
            CreatedAtUtc = invoice.CreatedAtUtc,
            Lines = invoice.Lines.Select(x => new CorporateInvoiceLineDto
            {
                OrderId = x.OrderId,
                OrderNumber = x.OrderNumber,
                OrderDateUtc = x.OrderDateUtc,
                Amount = x.Amount
            }).ToList()
        };
    }

    public async Task RecordInvoicePaymentAsync(Guid companyId, Guid invoiceId, RecordCorporateInvoicePaymentRequest request)
    {
        var invoice = await _corporateRepository.GetInvoiceByIdAsync(companyId, invoiceId)
            ?? throw new KeyNotFoundException("Invoice not found.");

        if (invoice.Status == CorporateInvoiceStatus.Paid)
            return;

        invoice.MarkPaid(request.PaidAtUtc);
        await _corporateRepository.UpdateInvoiceAsync(invoice);

        var arAccountId = await _journalEntryRepository.GetOrCreateAccountIdAsync(
            companyId, "1105", "Accounts Receivable - Corporate", "Asset");

        var bankAccountId = await _journalEntryRepository.GetOrCreateAccountIdAsync(
            companyId, "1100", "Bank Account", "Asset");

        var entries = new List<JournalEntry>
        {
            new(companyId, request.PaidAtUtc, invoice.Id.ToString(), "CORPORATE_INVOICE_PAYMENT",
                $"Corporate invoice payment {invoice.Id}", invoice.TotalAmount, 0, bankAccountId),
            new(companyId, request.PaidAtUtc, invoice.Id.ToString(), "CORPORATE_INVOICE_PAYMENT",
                $"Corporate invoice payment {invoice.Id}", 0, invoice.TotalAmount, arAccountId)
        };

        await _journalEntryRepository.AddRangeAsync(entries);

        foreach (var line in invoice.Lines)
        {
            var meta = await _corporateRepository.GetOrderMetaByOrderIdAsync(companyId, line.OrderId);
            if (meta == null)
                continue;

            meta.MarkBillingStatus(CorporateBillingStatus.Paid);
            await _corporateRepository.UpdateOrderMetaAsync(meta);
        }
    }

    public Task<List<CorporateInvoiceDto>> GetClientInvoicesAsync(Guid companyId, Guid clientId)
    {
        return _corporateRepository.GetClientInvoicesAsync(companyId, clientId);
    }

    public async Task<CorporateBirthdayAutomationResult> RunBirthdayAutomationAsync(Guid companyId, DateTime runDateUtc)
    {
        var birthdays = await _corporateRepository.GetTodaysBirthdayEmployeesAsync(companyId, runDateUtc);
        var result = new CorporateBirthdayAutomationResult { RunDateUtc = runDateUtc };

        foreach (var employee in birthdays)
        {
            if (employee.Client == null)
                continue;

            if (!employee.Client.DefaultProductId.HasValue)
            {
                result.SkippedMissingDefaultProduct++;
                continue;
            }

            if (string.IsNullOrWhiteSpace(employee.Address))
            {
                result.SkippedNoAddress++;
                continue;
            }

            var duplicate = await _corporateRepository.HasBirthdayOrderForDateAsync(companyId, employee.Id, runDateUtc);
            if (duplicate)
            {
                result.SkippedDuplicate++;
                continue;
            }

            var product = await _productRepository.GetByIdAsync(companyId, employee.Client.DefaultProductId.Value);
            if (product == null || !product.IsActive)
            {
                result.SkippedMissingDefaultProduct++;
                continue;
            }

            var location = await _locationRepository.GetDefaultAsync(companyId)
                ?? throw new InvalidOperationException("Default location is required for birthday automation.");

            var order = new Order(
                companyId,
                employee.Client.CustomerId,
                runDateUtc,
                employee.Address,
                null,
                employee.Name,
                null);

            order.LocationId = location.Id;
            order.SetCustomerType(CustomerType.Corporate);
            order.SetOrderSource(OrderSource.Other);
            order.SetCardMessage(employee.Client.DefaultMessage ?? $"Happy Birthday {employee.Name}!");
            order.SetTimeSlot("10:00-13:00");
            order.AddItem(product.Id, product.Name, 1, product.RetailPrice);
            order.MarkAutoCreated();

            order.MarkCredit();

            await _orderRepository.AddAsync(order);

            var delivery = new Delivery(companyId, order.Id, runDateUtc, "10:00-13:00", employee.Address!);
            await _deliveryRepository.AddAsync(delivery);

            var meta = new CorporateOrderMeta(
                companyId,
                order.Id,
                employee.ClientId,
                CorporateBillingStatus.Pending,
                employee.Id,
                isAutoCreated: true,
                needsApproval: true,
                automationDateUtc: runDateUtc);

            await _corporateRepository.AddOrderMetaAsync(meta);
            result.CreatedOrders++;
        }

        return result;
    }

    private async Task CreateCorporateRevenueJournalAsync(Guid companyId, Order order, string clientName)
    {
        var arAccountId = await _journalEntryRepository.GetOrCreateAccountIdAsync(
            companyId, "1105", "Accounts Receivable - Corporate", "Asset");

        var revenueAccountId = await _journalEntryRepository.GetOrCreateAccountIdAsync(
            companyId, "4000", "Sales Revenue", "Income");

        var now = DateTime.UtcNow;

        var entries = new List<JournalEntry>
        {
            new(companyId, now, order.OrderNumber, "CORPORATE_SALE",
                $"Corporate sale {order.OrderNumber} - {clientName} (AR)", order.TotalAmount, 0, arAccountId),
            new(companyId, now, order.OrderNumber, "CORPORATE_SALE",
                $"Corporate sale {order.OrderNumber} - Revenue", 0, order.TotalAmount, revenueAccountId)
        };

        if (order.LocationId.HasValue)
        {
            entries[0].SetLocation(order.LocationId.Value);
            entries[1].SetLocation(order.LocationId.Value);
        }

        await _journalEntryRepository.AddRangeAsync(entries);
    }
}
