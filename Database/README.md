# Sumpooj ERP - Database First Setup Guide

## Overview

This guide explains how to use the Database-First approach with the Sumpooj ERP system.

## Step 1: Create the Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create the database
CREATE DATABASE sumpooj;

# Connect to the new database
\c sumpooj

# Run the schema script
\i 'path/to/Database/sumpooj_complete_schema.sql'
```

Or using pgAdmin:
1. Create a new database named `sumpooj`
2. Open Query Tool
3. Copy and paste the contents of `sumpooj_complete_schema.sql`
4. Execute (F5)

## Step 2: Update Connection String

Update `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "Default": "Host=localhost;Database=sumpooj;Username=postgres;Password=yourpassword"
  }
}
```

## Step 3: Scaffold Entities (Optional)

If you want to regenerate entities from the database:

```bash
# Install EF Core tools if not already installed
dotnet tool install --global dotnet-ef

# Scaffold from database
cd Sumpooj.Infrastructure

dotnet ef dbcontext scaffold "Host=localhost;Database=sumpooj;Username=postgres;Password=yourpassword" Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir "../Sumpooj.Domain/Entities" \
  --context "SumpoojDbContext" \
  --context-dir "Persistence" \
  --force \
  --no-onconfiguring
```

**Note:** The entities in this project are already configured to match the database schema exactly, so scaffolding is optional.

## Database Schema Overview

### Core Tables

| Table | Description |
|-------|-------------|
| `Companies` | Multi-tenant company/store data |
| `Locations` | Store locations (warehouse, cold room, etc.) |
| `Customers` | Customer CRM |
| `Staff` | Staff members with roles and commission |
| `Products` | Product catalog with flower-specific fields |
| `ProductBatches` | Inventory batch tracking with expiry |
| `Suppliers` | Supplier management |

### Order Management

| Table | Description |
|-------|-------------|
| `Orders` | Sales orders with delivery info |
| `OrderItems` | Order line items |
| `Payments` | Payment transactions |
| `Refunds` | Refund records |
| `RefundItems` | Refund line items |
| `Deliveries` | Delivery tracking |

### Operations

| Table | Description |
|-------|-------------|
| `PurchaseOrders` | Purchase orders to suppliers |
| `PurchaseOrderItems` | PO line items |
| `InventoryAdjustments` | Stock adjustments |
| `StockMovements` | Audit trail for stock changes |
| `Tasks` | Staff task management |
| `Events` | Wedding/corporate event management |
| `GiftCards` | Gift card issuance and redemption |
| `DayCloses` | End-of-day cash reconciliation |
| `AuditLogs` | **User activity tracking** - who did what, when |

## Audit Logging

The system includes comprehensive audit logging to track all user actions:

### What's Tracked

- **User Info**: Who performed the action (userId, userName, role)
- **Action**: What was done (CREATE, UPDATE, DELETE, LOGIN, etc.)
- **Entity**: Which record was affected (entityType, entityId, entityName)
- **Changes**: Before/after values for updates (oldValues, newValues)
- **Context**: Request details (IP address, path, HTTP method)
- **Timing**: When it happened (timestamp, duration)
- **Status**: Success/failure with error messages

### Audit API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/audit-logs/search` | Search logs with filters |
| `GET /api/audit-logs/recent` | Get recent activity |
| `GET /api/audit-logs/entity/{type}/{id}` | History for specific entity |
| `GET /api/audit-logs/user/{userId}` | Activity by user |
| `GET /api/audit-logs/summary` | Daily summary with stats |
| `GET /api/audit-logs/user-activity` | User activity report |

### Standard Action Types

```
CREATE, READ, UPDATE, DELETE
LOGIN, LOGOUT, LOGIN_FAILED, PASSWORD_CHANGED
ORDER_CREATED, ORDER_CANCELLED, ORDER_STATUS_CHANGED
PAYMENT_RECEIVED, PAYMENT_VOIDED, REFUND_PROCESSED
STOCK_ADJUSTED, BATCH_RECEIVED, BATCH_EXPIRED
DAY_CLOSED, SETTINGS_CHANGED, DATA_EXPORTED
```

## Enum Reference

All enums are stored as integers. Here's a quick reference:

### StaffRole
```
0 = Admin, 1 = Manager, 2 = Designer, 3 = Cashier, 4 = Driver, 5 = Staff
```

### OrderStatus
```
0 = Pending, 1 = Confirmed, 2 = Processing, 3 = ReadyForDelivery,
4 = OutForDelivery, 5 = Delivered, 6 = Cancelled, 7 = Failed
```

### PaymentStatus
```
0 = Unpaid, 1 = PartiallyPaid, 2 = Paid, 3 = Refunded
```

### FulfillmentStatus
```
0 = Draft, 1 = Confirmed, 2 = InDesign, 3 = Ready,
4 = OutForDelivery, 5 = Completed, 6 = Cancelled
```

### OrderSource
```
0 = WalkIn, 1 = Phone, 2 = Website, 3 = BloomNation, 4 = Ftd, 5 = Other
```

### PaymentMethod
```
0 = Cash, 1 = Card, 2 = GiftCard, 3 = ExternalTerminal, 4 = Upi, 5 = BankTransfer
```

### EventType
```
0 = Wedding, 1 = Corporate, 2 = Funeral, 3 = Party, 4 = Other
```

### EventStatus
```
0 = Inquiry, 1 = ProposalSent, 2 = Confirmed, 3 = InProduction, 4 = Completed, 5 = Cancelled
```

### TaskStatus
```
0 = Pending, 1 = InProgress, 2 = Completed
```

### TaskPriority
```
0 = Low, 1 = Medium, 2 = High
```

### GiftCardStatus
```
0 = Active, 1 = Inactive, 2 = FullyRedeemed, 3 = Expired
```

## API Endpoints

After setup, the following API endpoints are available:

### Orders
- `GET /api/orders/search` - Search orders
- `GET /api/orders/today` - Get today's orders
- `POST /api/orders` - Create order
- `PATCH /api/orders/{id}/status` - Update status

### Payments
- `GET /api/payments/by-order/{orderId}` - Get payments for order
- `POST /api/payments` - Create payment

### Staff
- `GET /api/staff` - List all staff
- `POST /api/staff` - Create staff member

### Events
- `GET /api/events/search` - Search events
- `GET /api/events/upcoming` - Get upcoming events
- `POST /api/events` - Create event

### Gift Cards
- `GET /api/gift-cards/check-balance/{code}` - Check balance
- `POST /api/gift-cards` - Issue gift card
- `POST /api/gift-cards/redeem` - Redeem gift card

### Tasks
- `GET /api/tasks/search` - Search tasks
- `GET /api/tasks/pending` - Get pending tasks
- `POST /api/tasks` - Create task

### Day Close
- `GET /api/day-close/summary` - Get day summary
- `POST /api/day-close` - Close the day

### Dashboard
- `GET /api/dashboard?role=ADMIN` - Get role-based dashboard

## Running the Application

```bash
# Ensure database is created and connection string is correct
cd Sumpooj.API
dotnet run
```

The API will be available at `https://localhost:5001` (or the configured port).
