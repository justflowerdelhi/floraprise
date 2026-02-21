# Sumpooj Florist ERP

A comprehensive, multi-tenant Enterprise Resource Planning (ERP) system designed specifically for florist businesses. Built with .NET 10, React 19, Clean Architecture, and PostgreSQL.

## Overview

Sumpooj Florist ERP is a full-featured business management system tailored for florist shops, wedding planners, and event decorators. It handles everything from inventory management with perishable tracking to order processing, staff management, and financial operations.

### Key Highlights

- **Multi-Tenant Architecture**: Support multiple companies/stores with complete data isolation
- **Florist-Specific Features**: Flower grades, perishability tracking, batch expiry management
- **Complete Order Lifecycle**: From walk-in to delivery with real-time status tracking
- **Event Management**: Wedding and corporate event planning with budgets and timelines
- **Comprehensive Audit Trail**: Track every user action for compliance and debugging
- **Modern React Frontend**: Beautiful, responsive UI with Material UI and Tailwind CSS

---

## Features

### Core Business
- **Multi-Company**: Support multiple stores/franchises with isolated data
- **Locations**: Manage stores, warehouses, cold rooms, display areas
- **Staff Management**: Roles, commissions, task assignments
- **Customer CRM**: Customer profiles, order history, preferences

### Inventory Management
- **Product Catalog**: Flowers, arrangements, supplies, services
- **Batch Tracking**: FIFO-based inventory with expiry dates
- **Perishable Alerts**: Automated expiry notifications
- **Stock Adjustments**: Damage, waste, theft, corrections
- **Low Stock Alerts**: Reorder level notifications

### Order Processing
- **Multi-Source Orders**: Walk-in, phone, website, BloomNation, FTD
- **Delivery Management**: Time slots, driver assignments, proof of delivery
- **Fulfillment Tracking**: Draft to Design to Ready to Delivered
- **Card Messages**: Custom messages for recipients

### Financial Operations
- **Multiple Payment Methods**: Cash, card, UPI, gift cards, bank transfer
- **Terminal Integration**: External payment terminal support
- **Refund Processing**: Full/partial refunds with restock option
- **Day Close**: End-of-day cash reconciliation
- **Gift Cards**: Issue, redeem, track balances

### Event Management
- **Event Types**: Weddings, corporate, funerals, parties
- **Budget Tracking**: Proposals, costs, payments
- **Designer Assignment**: Assign staff to events
- **Mood Boards**: Color themes, style notes

### Analytics and Reporting
- **Dashboard**: Role-based metrics and KPIs
- **Audit Logs**: Complete user activity tracking
- **Profit Intelligence**: Revenue and cost analysis
- **Stock Valuation**: Inventory value tracking

---

## Technology Stack

### Backend
| Category | Technology |
|----------|------------|
| Framework | .NET 10 |
| Database | PostgreSQL 15+ |
| ORM | Entity Framework Core 10 |
| Authentication | ASP.NET Identity + JWT |
| API Documentation | OpenAPI (Scalar) |
| Architecture | Clean Architecture / DDD |

### Frontend
| Category | Technology |
|----------|------------|
| Framework | React 19 |
| Language | TypeScript 5.9 |
| Build Tool | Vite 7 |
| UI Library | Material UI 7 |
| Styling | Tailwind CSS 4 |
| Forms | React Hook Form + Zod |
| Charts | Recharts |
| Routing | React Router 7 |
| HTTP Client | Axios |

---

## Architecture

### System Architecture Diagram

```mermaid
graph TB
    subgraph "Frontend - sumpooj-web"
        REACT[React 19 App<br/>TypeScript + Vite]
        MUI[Material UI 7]
        TAIL[Tailwind CSS]
        PAGES[27 Page Modules]
    end

    subgraph "API Layer - Sumpooj.API"
        AUTH[Auth Controller]
        ORDERS[Orders Controller]
        INV[Inventory Controller]
        PAY[Payments Controller]
        OTHER[19 Controllers Total]
    end

    subgraph "Application Layer - Sumpooj.Application"
        SVC[16 Services]
        DTO[DTOs]
        INT[Interfaces]
    end

    subgraph "Infrastructure Layer - Sumpooj.Infrastructure"
        REPO[15 Repositories]
        IDENT[Identity]
        DBCTX[DbContext]
    end

    subgraph "Domain Layer - Sumpooj.Domain"
        ENT[17 Entities]
        ENUM[Enums]
    end

    subgraph "Database"
        PG[(PostgreSQL<br/>25 Tables)]
    end

    REACT --> AUTH
    MUI --> REACT
    TAIL --> REACT
    PAGES --> REACT

    AUTH --> SVC
    ORDERS --> SVC
    INV --> SVC
    PAY --> SVC
    OTHER --> SVC

    SVC --> INT
    INT -.-> REPO
    REPO --> DBCTX
    REPO --> ENT
    DBCTX --> PG

    style REACT fill:#61dafb
    style PG fill:#336791
    style MUI fill:#007fff
```

### Backend Architecture (Clean Architecture)

| Layer | Project | Responsibility |
|-------|---------|----------------|
| Domain | Sumpooj.Domain | Core business entities, enums, domain logic |
| Application | Sumpooj.Application | Use cases, DTOs, service interfaces |
| Infrastructure | Sumpooj.Infrastructure | Data access, EF Core, Identity |
| API | Sumpooj.API | HTTP endpoints, authentication |

### Frontend Architecture

```
sumpooj-web/
├── src/
│   ├── api/            # API client and endpoints
│   ├── auth/           # Authentication context and guards
│   ├── components/     # Shared UI components
│   ├── core/           # Core utilities and types
│   ├── pages/          # Feature pages (27 modules)
│   └── routes/         # Route definitions
```

---

## Frontend Pages

The React application includes 27 feature modules:

| Category | Pages |
|----------|-------|
| **Dashboard** | Main Dashboard, Health Dashboard, Profit Intelligence |
| **Sales** | Orders, Cart, Payments, Refunds |
| **Inventory** | Products, Inventory, Adjustments, Expiry Alerts, Reorder, Stock Ledger, Valuation |
| **Purchasing** | Purchases |
| **CRM** | Customers, CRM |
| **Operations** | Staff, Tasks, Events, Day Close |
| **Finance** | Gift Cards |
| **Settings** | Settings, Onboarding, Subscription |
| **Production** | Production Management |
| **Auth** | Login, Register |

---

## Business Process Flowcharts

### Order Processing Workflow

```mermaid
flowchart TD
    START([New Order]) --> SOURCE{Order Source?}

    SOURCE -->|Walk-in| WALKIN[Create Walk-in Order]
    SOURCE -->|Phone| PHONE[Create Phone Order]
    SOURCE -->|Website| WEB[Create Online Order]
    SOURCE -->|Wire Service| WIRE[Create Wire Order]

    WALKIN --> CREATE
    PHONE --> CREATE
    WEB --> CREATE
    WIRE --> CREATE

    CREATE[Create Order<br/>Status: PENDING] --> PAYMENT{Payment?}

    PAYMENT -->|Full Payment| PAID[Mark as PAID]
    PAYMENT -->|Partial| PARTIAL[Mark as PARTIALLY_PAID]
    PAYMENT -->|Later| UNPAID[Keep as UNPAID]

    PAID --> CONFIRM
    PARTIAL --> CONFIRM
    UNPAID --> CONFIRM

    CONFIRM[Confirm Order<br/>Status: CONFIRMED] --> ASSIGN[Assign Designer]

    ASSIGN --> DESIGN[Start Design<br/>Status: PROCESSING<br/>Fulfillment: IN_DESIGN]

    DESIGN --> READY[Mark Ready<br/>Status: READY_FOR_DELIVERY<br/>Fulfillment: READY]

    READY --> DELIVERY{Delivery Type?}

    DELIVERY -->|Pickup| PICKUP[Customer Pickup]
    DELIVERY -->|Delivery| DRIVER[Assign Driver]

    DRIVER --> OUT[Out for Delivery<br/>Status: OUT_FOR_DELIVERY]

    OUT --> DELIVERED[Delivered<br/>Status: DELIVERED<br/>Fulfillment: COMPLETED]
    PICKUP --> DELIVERED

    DELIVERED --> DONE([Order Complete])

    style START fill:#c8e6c9
    style DONE fill:#c8e6c9
    style DESIGN fill:#fff9c4
    style READY fill:#bbdefb
    style DELIVERED fill:#c8e6c9
```

### Inventory Management Flow

```mermaid
flowchart TD
    subgraph "Stock In"
        PO[Purchase Order] --> RECEIVE[Receive Stock]
        RECEIVE --> BATCH[Create Batch<br/>with Expiry Date]
        BATCH --> UPDATE_IN[Update Product<br/>Stock Quantity +]
    end

    subgraph "Stock Out"
        ORDER[Sales Order] --> ALLOCATE[Allocate Stock<br/>FIFO Method]
        ALLOCATE --> DEDUCT[Deduct from<br/>Oldest Batch]
        DEDUCT --> UPDATE_OUT[Update Product<br/>Stock Quantity -]
    end

    subgraph "Adjustments"
        ADJ_START([Adjustment Needed]) --> TYPE{Type?}
        TYPE -->|Damage| DAMAGE[Record Damage]
        TYPE -->|Waste/Expired| WASTE[Record Waste]
        TYPE -->|Theft| THEFT[Record Theft]
        TYPE -->|Count Correction| COUNT[Stock Count]

        DAMAGE --> ADJUST[Create Adjustment<br/>Record]
        WASTE --> ADJUST
        THEFT --> ADJUST
        COUNT --> ADJUST

        ADJUST --> UPDATE_ADJ[Update Stock]
    end

    subgraph "Alerts"
        CHECK{Daily Check} --> LOW{Stock <= Min?}
        LOW -->|Yes| LOW_ALERT[Low Stock Alert]

        CHECK --> EXPIRY{Expiring Soon?}
        EXPIRY -->|Yes| EXP_ALERT[Expiry Alert]

        CHECK --> REORDER{Stock <= Reorder?}
        REORDER -->|Yes| REORDER_ALERT[Reorder Alert]
    end

    style PO fill:#e3f2fd
    style ORDER fill:#fff3e0
    style ADJ_START fill:#fce4ec
    style LOW_ALERT fill:#ffcdd2
    style EXP_ALERT fill:#ffcdd2
    style REORDER_ALERT fill:#fff9c4
```

### Payment Processing Flow

```mermaid
flowchart TD
    START([Payment Request]) --> METHOD{Payment Method?}

    METHOD -->|Cash| CASH[Cash Payment]
    METHOD -->|Card| CARD[Card Payment]
    METHOD -->|UPI| UPI[UPI Payment]
    METHOD -->|Gift Card| GC[Gift Card]
    METHOD -->|Bank Transfer| BANK[Bank Transfer]

    CASH --> RECEIVE_CASH[Receive Cash<br/>Give Change]
    RECEIVE_CASH --> APPROVE

    CARD --> TERMINAL{Terminal Type?}
    TERMINAL -->|External| EXT[Send to Terminal]
    TERMINAL -->|Integrated| INT[Process Card]

    EXT --> WAIT[Wait for Response]
    INT --> WAIT

    WAIT --> RESULT{Result?}
    RESULT -->|Approved| APPROVE[Payment Approved]
    RESULT -->|Declined| DECLINE[Payment Declined]

    UPI --> UPI_WAIT[Wait for Confirmation]
    UPI_WAIT --> RESULT

    GC --> CHECK_BAL{Balance OK?}
    CHECK_BAL -->|Yes| DEDUCT_GC[Deduct Balance]
    CHECK_BAL -->|No| INSUFFICIENT[Insufficient Balance]
    DEDUCT_GC --> APPROVE

    BANK --> MANUAL[Manual Verification]
    MANUAL --> APPROVE

    APPROVE --> UPDATE[Update Order<br/>Payment Status]
    UPDATE --> RECEIPT[Generate Receipt]
    RECEIPT --> DONE([Payment Complete])

    DECLINE --> RETRY{Retry?}
    RETRY -->|Yes| METHOD
    RETRY -->|No| CANCEL([Payment Cancelled])

    style START fill:#e8f5e9
    style DONE fill:#c8e6c9
    style DECLINE fill:#ffcdd2
    style CANCEL fill:#ffcdd2
```

### Event Management Flow

```mermaid
flowchart TD
    START([Client Inquiry]) --> INQUIRY[Create Event<br/>Status: INQUIRY]

    INQUIRY --> CONSULT[Consultation<br/>Discuss Requirements]

    CONSULT --> PROPOSAL[Create Proposal<br/>Budget & Items]

    PROPOSAL --> SEND[Send Proposal<br/>Status: PROPOSAL_SENT]

    SEND --> RESPONSE{Client Response?}

    RESPONSE -->|Approved| CONFIRM[Confirm Event<br/>Status: CONFIRMED]
    RESPONSE -->|Changes| REVISE[Revise Proposal]
    RESPONSE -->|Declined| CANCEL([Event Cancelled])

    REVISE --> SEND

    CONFIRM --> DEPOSIT[Collect Deposit]

    DEPOSIT --> ASSIGN[Assign Designer]

    ASSIGN --> PLAN[Plan & Source<br/>Materials]

    PLAN --> PRODUCE[Production<br/>Status: IN_PRODUCTION]

    PRODUCE --> SETUP[Event Day Setup]

    SETUP --> EXECUTE[Execute Event]

    EXECUTE --> FINAL[Final Payment]

    FINAL --> COMPLETE[Complete Event<br/>Status: COMPLETED]

    COMPLETE --> REVIEW([Client Review])

    style START fill:#e8f5e9
    style REVIEW fill:#c8e6c9
    style CANCEL fill:#ffcdd2
    style PRODUCE fill:#fff9c4
```

### Day Close Process

```mermaid
flowchart TD
    START([End of Day]) --> CHECK{All Orders<br/>Processed?}

    CHECK -->|No| PENDING[Complete Pending<br/>Orders]
    PENDING --> CHECK

    CHECK -->|Yes| PAYMENTS[Review Day's<br/>Payments]

    PAYMENTS --> CASH_COUNT[Count Physical<br/>Cash]

    CASH_COUNT --> COMPARE{Cash Matches<br/>System?}

    COMPARE -->|Yes| MATCH[No Variance]
    COMPARE -->|No| VARIANCE[Record Variance<br/>& Reason]

    MATCH --> SUMMARY
    VARIANCE --> SUMMARY

    SUMMARY[Generate Summary<br/>- Total Orders<br/>- Total Sales<br/>- Payment Breakdown<br/>- Refunds]

    SUMMARY --> REVIEW[Manager Review]

    REVIEW --> APPROVE{Approved?}

    APPROVE -->|Yes| CLOSE[Close Day<br/>Status: CLOSED]
    APPROVE -->|No| INVESTIGATE[Investigate<br/>Discrepancies]

    INVESTIGATE --> CASH_COUNT

    CLOSE --> REPORT[Generate Report]

    REPORT --> DONE([Day Closed])

    style START fill:#e3f2fd
    style DONE fill:#c8e6c9
    style VARIANCE fill:#fff9c4
```

### Audit Trail Flow

```mermaid
flowchart LR
    subgraph "User Actions"
        A1[Create]
        A2[Update]
        A3[Delete]
        A4[Login]
        A5[Payment]
    end

    subgraph "Audit Service"
        LOG[AuditLogService.LogAsync]
    end

    subgraph "Audit Record"
        REC[AuditLog Entity<br/>- Who: UserId, UserName<br/>- What: Action, EntityType<br/>- When: Timestamp<br/>- Where: IP, Path<br/>- Details: Old/New Values]
    end

    subgraph "Storage"
        DB[(AuditLogs Table)]
    end

    subgraph "Reports"
        R1[User Activity]
        R2[Entity History]
        R3[Daily Summary]
    end

    A1 --> LOG
    A2 --> LOG
    A3 --> LOG
    A4 --> LOG
    A5 --> LOG

    LOG --> REC
    REC --> DB

    DB --> R1
    DB --> R2
    DB --> R3

    style LOG fill:#e8f5e9
    style DB fill:#fff3e0
```

---

## Entity Relationship Diagram

```mermaid
erDiagram
    Company ||--o{ Location : has
    Company ||--o{ Customer : has
    Company ||--o{ Staff : has
    Company ||--o{ Supplier : has
    Company ||--o{ Product : has
    Company ||--o{ Order : has
    Company ||--o{ Event : has
    Company ||--o{ AuditLog : has

    Product ||--o{ ProductBatch : has
    Product ||--o{ OrderItem : "sold in"
    Product ||--o{ PurchaseOrderItem : "ordered in"

    ProductBatch ||--o{ InventoryAdjustment : has

    Supplier ||--o{ PurchaseOrder : receives
    PurchaseOrder ||--o{ PurchaseOrderItem : contains

    Customer ||--o{ Order : places
    Order ||--o{ OrderItem : contains
    Order ||--o{ Payment : has
    Order ||--o{ Refund : may_have
    Order ||--o{ Delivery : has

    Refund ||--o{ RefundItem : contains

    Staff ||--o{ StaffTask : assigned
    Staff ||--o{ Event : designs

    Location ||--o{ DayClose : has
    Location ||--o{ StaffTask : has

    Company {
        uuid Id PK
        string Name
        string Region
        string CurrencyCode
    }

    Product {
        uuid Id PK
        string Name
        string Sku
        decimal RetailPrice
        int StockQuantity
    }

    Order {
        uuid Id PK
        string OrderNumber
        int Status
        decimal TotalAmount
    }

    Customer {
        uuid Id PK
        string Name
        string Email
        int TotalOrders
    }
```

---

## Multi-Tenant Data Model

```mermaid
graph TB
    subgraph "Platform Level"
        PLATFORM[Platform Admin]
    end

    subgraph "Company A - Flower Shop NYC"
        CA[Company A]
        CA_LOC1[Location: Main Store]
        CA_LOC2[Location: Warehouse]
        CA_STAFF[Staff Members]
        CA_CUST[Customers]
        CA_PROD[Products]
        CA_ORD[Orders]
    end

    subgraph "Company B - Rose Garden LA"
        CB[Company B]
        CB_LOC1[Location: Downtown]
        CB_STAFF[Staff Members]
        CB_CUST[Customers]
        CB_PROD[Products]
        CB_ORD[Orders]
    end

    PLATFORM --> CA
    PLATFORM --> CB

    CA --> CA_LOC1
    CA --> CA_LOC2
    CA --> CA_STAFF
    CA --> CA_CUST
    CA --> CA_PROD
    CA --> CA_ORD

    CB --> CB_LOC1
    CB --> CB_STAFF
    CB --> CB_CUST
    CB --> CB_PROD
    CB --> CB_ORD

    style PLATFORM fill:#e1bee7
    style CA fill:#c8e6c9
    style CB fill:#bbdefb
```

---

## Getting Started

### Prerequisites
- .NET 10 SDK
- Node.js 20+
- PostgreSQL 15+
- Visual Studio 2022 or VS Code

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/sumitkumarsingh88/FloristERP.git
cd FloristERP

# Create PostgreSQL database
psql -U postgres -c "CREATE DATABASE FloristERP;"

# Run schema (Database-First)
psql -U postgres -d FloristERP -f Database/sumpooj_complete_schema.sql

# Update connection string in Sumpooj.API/appsettings.json

# Run the API
cd Sumpooj.API
dotnet run
```

### Frontend Setup

```bash
# Navigate to frontend directory
cd sumpooj-web

# Install dependencies
npm install

# Start development server
npm run dev
```

### Access Points
- **API**: https://localhost:5001
- **API Docs**: https://localhost:5001/scalar
- **Frontend**: http://localhost:5173

---

## API Endpoints

| Category | Base Path | Key Operations |
|----------|-----------|----------------|
| Auth | /api/auth | login, register, refresh |
| Customers | /api/customer | CRUD + search |
| Products | /api/products | CRUD + search, low-stock alerts |
| Inventory | /api/inventory | batches, adjustments, expiry-alerts |
| Orders | /api/orders | CRUD + status, fulfillment, assign |
| Payments | /api/payments | CRUD + approve, void |
| Refunds | /api/refunds | CRUD |
| Gift Cards | /api/gift-cards | issue, redeem, check-balance |
| Staff | /api/staff | CRUD + search |
| Events | /api/events | CRUD + upcoming |
| Tasks | /api/tasks | CRUD + start, complete |
| Dashboard | /api/dashboard | role-based metrics |
| Audit Logs | /api/audit-logs | search, summary, user-activity |
| Day Close | /api/day-close | summary, close, history |
| Companies | /api/companies | CRUD (platform only) |
| Locations | /api/locations | CRUD |
| Suppliers | /api/suppliers | CRUD |
| Purchases | /api/purchases | CRUD + submit, receive |
| Lookup | /api/lookup | enum references |

---

## Authorization Roles

| Role | Scope | Access |
|------|-------|--------|
| PlatformSuperAdmin | Platform | Full platform access |
| PlatformSupport | Platform | Support operations |
| CompanyAdmin | Company | Full company access |
| Manager | Company | Management operations |
| Staff | Company | Day-to-day operations |
| Delivery | Company | Delivery-related only |

---

## Roadmap

- [ ] Advanced Reporting and Analytics
- [ ] Mobile App (React Native)
- [ ] Stripe/Payment Gateway Integration
- [ ] Email and SMS Notifications
- [ ] QuickBooks Integration
- [ ] Wire Service Integration (FTD, Teleflora)
- [ ] Customer Portal
- [ ] Inventory Forecasting with ML

---

## Authors

- **Sumit Kumar Singh** - [GitHub](https://github.com/sumitkumarsingh88)
- **Anand Kumar** - [GitHub](https://github.com/anandpandeji)

---

## License

This project is licensed under the MIT License.

---

Made with love for Florists
