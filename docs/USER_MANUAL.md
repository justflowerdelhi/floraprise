# Sumpooj Florist ERP — Company Admin User Manual

> **Audience**: Company Administrators (CompanyAdmin role)  
> **Version**: 1.0  
> **Last Updated**: June 2025

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [Initial Setup (First-Time Onboarding)](#2-initial-setup-first-time-onboarding)
3. [Settings Configuration](#3-settings-configuration)
4. [Catalog Setup](#4-catalog-setup)
5. [Inventory Setup](#5-inventory-setup)
6. [Staff Management](#6-staff-management)
7. [Customer Management (CRM)](#7-customer-management-crm)
8. [Daily Sales Operations](#8-daily-sales-operations)
9. [Order Management](#9-order-management)
10. [Delivery Management](#10-delivery-management)
11. [Payment Processing](#11-payment-processing)
12. [Refunds](#12-refunds)
13. [Events & Weddings](#13-events--weddings)
14. [Floral Production Engine](#14-floral-production-engine)
15. [Gift Cards](#15-gift-cards)
16. [Day Close (End-of-Day)](#16-day-close-end-of-day)
17. [Reports & Analytics](#17-reports--analytics)
18. [Audit Logs](#18-audit-logs)
19. [Subscription & Billing](#19-subscription--billing)
20. [Recommended Workflow Order](#20-recommended-workflow-order)

---

## 1. Getting Started

### Logging In

1. Open **http://localhost:5173** (or your deployed URL) in a browser.
2. Enter your **email** and **password**.
3. Click **Login**.

On successful login, the system loads your role (CompanyAdmin), your company tenant, and redirects you to the **Home Dashboard**.

> **Demo Credentials** (seeded automatically):
> | Role | Email | Password |
> |------|-------|----------|
> | CompanyAdmin | admin@sumpooj.com | Admin@123 |
> | Manager | manager@sumpooj.com | Manager@123 |
> | Cashier | cashier@sumpooj.com | Cashier@123 |
> | Designer | designer@sumpooj.com | Designer@123 |
> | Driver | driver@sumpooj.com | Driver@123 |

### Home Dashboard

After login, you land on the **Home** page (`/home`) which shows:

- Today's order count and revenue
- Pending deliveries
- Low stock alerts
- Quick-action buttons for Walk-In Sale, Phone Order, and New Order

---

## 2. Initial Setup (First-Time Onboarding)

If this is a **new company** (no country/currency set), the system automatically redirects you to the **Onboarding Wizard** (`/onboarding`).

### Steps:

| Step | What You Do |
|------|-------------|
| **1. Business Info** | Enter your business name (e.g., "Rose Garden NYC") |
| **2. Country & Region** | Select your country (US, IN, AE, GB, CA, AU). Currency, locale, tax system, and date/time formats are auto-filled |
| **3. Review & Confirm** | Review all settings and click **Complete Setup** |

After onboarding, you're taken to the main dashboard. You can always change these settings later from **Settings → Tenant Settings**.

---

## 3. Settings Configuration

**Navigate to**: Sidebar → **Settings** section

Complete these settings **before** you start daily operations.

### 3.1 Tenant Settings (`/settings/tenant`)

Configure your company-wide defaults:

- Business name and branding
- Country, currency, locale
- Tax system (GST, VAT, Sales Tax, etc.)
- Date and time format preferences

### 3.2 Locations (`/settings/locations`)

Set up your physical locations:

- **Store**: Your retail shop front
- **Warehouse**: Bulk storage
- **Cold Room**: Temperature-controlled flower storage
- **Display Cooler**: Retail display refrigeration
- **Workshop**: Design/assembly area

**Actions**: Create, edit, activate/deactivate, set a **default location**.

> ⚡ **Tip**: Create at least one location before adding products or processing orders. The POS system requires an active location.

### 3.3 Tax Rules (`/settings/tax-rules`)

Configure tax rules for your country:

- **Rule name** (e.g., "GST 18%", "Sales Tax 8.875%")
- **Country code** (US, IN, AE, etc.)
- **Tax rate** (percentage)
- **Applies to**: Products, Services, or both
- Activate/deactivate rules

Products can be linked to specific tax rules for automatic tax calculation.

### 3.4 Delivery Zones (`/settings/delivery-zones`)

Define delivery zones with pricing:

| Field | Description |
|-------|-------------|
| Zone Name | e.g., "Downtown", "Suburbs", "Hills Area" |
| Zone Code | Short code (e.g., "DTN", "SUB") |
| Zip Codes / Cities | Comma-separated list of covered areas |
| Base Delivery Fee | Standard delivery charge |
| Same-Day Fee | Extra fee for same-day delivery |
| Express Fee | Extra fee for express delivery |
| Free Delivery Threshold | Order amount above which delivery is free |
| Estimated Minutes | Delivery time estimate |

### 3.5 Payment Gateways (`/settings/payment-gateways`)

Configure online payment processing:

- **Stripe** (US, EU)
- **Razorpay** (India)
- **PayPal** (Global)
- **Square** (US)
- **Tap** (UAE/GCC)
- **PayTabs** (MENA)
- **HyperPay** (MENA)
- **Cashfree** (India)
- **PayU** (India, LATAM)
- **Checkout.com** (Global)

For each gateway: enter API keys, set as active/default, configure sandbox vs. production mode.

---

## 4. Catalog Setup

### 4.1 Product Categories (`/categories`)

Create categories to organize your products:

- Roses, Lilies, Orchids, Mixed Flowers
- Indoor Plants, Outdoor Plants
- Vases, Ribbons, Cards
- Chocolates & Gifts
- Custom categories

Each category can be marked as **perishable** (enables expiry tracking for products in that category).

### 4.2 Products (`/products`)

**Navigate to**: Sidebar → **Catalog** → **Products**

#### Adding a Product (`/products/new`)

| Section | Key Fields |
|---------|------------|
| **Basic Info** | Name, SKU, Barcode, Brand, Description |
| **Type & Category** | Product Type (SingleFlower, Bouquet, Arrangement, Plant, Gift, Accessory), Category |
| **Pricing** | Retail Price, Cost Price, Wholesale Price, Wedding/Event Price |
| **Inventory** | Track Inventory (yes/no), Track Batches, Min Stock Level, Reorder Level |
| **Perishable** | Shelf Life Days, Expiry Alert Days, Temperature Notes |
| **Flower Details** | Color, Variety, Grade (Standard/Select/Premium/Luxury), Country of Origin, Seasonal Availability |
| **Arrangement** | Estimated Minutes to Assemble |
| **Tax** | Link to a Tax Rule |
| **Flags** | Allow as Raw Material, Available Online, Commission Eligible |

> ⚡ **Tip**: Start with your top 20 best-selling products. You can always add more later.

### 4.3 Suppliers (`/suppliers`)

Add your flower and supply vendors:

- Supplier name, contact info
- Default lead time
- Rating (Not Rated → Excellent)
- Notes

---

## 5. Inventory Setup

### 5.1 Purchase Orders (`/purchases/new`)

Record incoming stock:

1. Select **Supplier**
2. Add line items (product, quantity, unit cost)
3. **Submit** the purchase order
4. When stock arrives, click **Receive** to:
   - Create product batches with expiry dates
   - Automatically increase stock quantities

### 5.2 Stock Overview (`/inventory`)

View all product batches with:

- Current stock quantities
- Batch numbers and expiry dates
- FIFO status (oldest batches highlighted)

### 5.3 Stock Adjustments (`/adjustments/new`)

Record inventory adjustments:

| Type | Use Case |
|------|----------|
| **Damaged** | Flowers damaged in transit or storage |
| **Spoiled** | Naturally wilted/expired |
| **Expired** | Past expiry date |
| **Theft** | Stock loss due to theft |
| **Lost** | Unaccounted stock |
| **Found** | Unexpected stock discovered |
| **Correction** | Physical count differs from system |
| **Transfer Out/In** | Moving stock between locations |

### 5.4 Expiry Alerts (`/expiry-alerts`)

Automated alerts for:

- Batches expiring within the alert window (configured per product)
- Products past expiry that need discarding
- Action buttons to mark as expired or adjust

### 5.5 Reorder Intelligence (`/reorder`)

Automatic suggestions for products that:

- Have hit or dropped below reorder level
- Show low stock warnings
- Need urgent restocking

---

## 6. Staff Management

**Navigate to**: Sidebar → **Staff** → **All Staff**

### Adding Staff (`/staff/new`)

| Field | Description |
|-------|-------------|
| Name | Full name |
| Role | Admin, Manager, Designer, Cashier, Driver, Staff |
| Email / Phone | Contact details |
| Commission Type | Revenue-based or Profit-based |
| Commission Rate | Percentage |
| Hourly Rate | For wage tracking |
| Primary Location | Default assigned location |
| Enable Login | Creates a system login for this staff member |

### Staff Roles Explained

| Role | What They Can Do |
|------|-----------------|
| **Admin** | Everything — settings, reports, staff management, all operations |
| **Manager** | Day-to-day management, inventory, reports, staff (no billing/settings) |
| **Cashier** | POS sales, view orders and customers |
| **Designer** | View orders, update fulfillment status, production, tasks |
| **Driver** | View assigned deliveries, update delivery status |
| **Staff** | Basic POS access, view orders |

### Tasks (`/tasks`)

Create and assign tasks to staff:

- Link tasks to Orders, Events, or Deliveries
- Set priority (Low / Medium / High)
- Track status (Pending → In Progress → Completed)

---

## 7. Customer Management (CRM)

### 7.1 Customer List (`/crm/customers`)

View all customers with:

- Name, email, phone
- Total orders and lifetime value
- Quick search and filters

### 7.2 Customer 360° View (`/crm/customers/:id`)

Full customer profile:

- Order history
- Preferences (favorite flowers, colors)
- Communication history
- Notes

### 7.3 Smart Reminders (`/crm/reminders`)

Automated reminders for:

- Customer birthdays and anniversaries
- Repeat order suggestions
- Follow-up on large orders

### 7.4 Loyalty Program (`/crm/loyalty`)

Configure and manage customer loyalty:

- Points earning rules
- Reward tiers
- Redemption options

---

## 8. Daily Sales Operations

### 8.1 Walk-In Sales (POS) — `/pos`

The Point of Sale screen for walk-in customers:

1. **Start Shift**: Select your location, enter opening cash
2. **Scan/Search** products by name, SKU, or barcode
3. **Add to Cart** with quantities
4. **Apply Discounts** (line-level or order-level)
5. **Select Customer** (optional — for CRM tracking)
6. **Process Payment**:
   - Cash (with change calculation)
   - Card (via configured payment terminal)
   - UPI
   - Gift Card
   - Split payments
7. **Print/Email Receipt**

### 8.2 Phone Orders — `/phone-orders`

For orders taken over the phone:

1. Go to **Phone Orders → New**
2. Search/create customer
3. Add products and special instructions
4. Set delivery date, time slot, and address
5. Add card message (for recipient)
6. Collect payment or mark as pay-later
7. Submit order → enters fulfillment pipeline

### 8.3 Online / External Orders — `/external-orders`

View and process orders from external channels:

- Website orders
- BloomNation
- FTD wire orders
- Other integrations

---

## 9. Order Management

### Order List (`/order-list`)

View all orders with filters:

| Filter | Options |
|--------|---------|
| Status | Pending, Confirmed, Processing, Ready, Out for Delivery, Delivered, Cancelled |
| Payment | Unpaid, Partially Paid, Paid, Refunded |
| Date Range | From/To date |
| Customer | Search by name |
| Order Number | Direct lookup |

### Order Lifecycle

```
PENDING → CONFIRMED → PROCESSING → READY_FOR_DELIVERY → OUT_FOR_DELIVERY → DELIVERED
                                                      → PICKUP (customer picks up)
```

### Order Actions

| Action | Description |
|--------|-------------|
| **Confirm** | Accept the order for processing |
| **Assign Designer** | Assign a floral designer to create the arrangement |
| **Update Fulfillment** | IN_DESIGN → READY |
| **Assign Driver** | Assign a delivery driver |
| **Mark Delivered** | Confirm delivery completion |
| **Cancel** | Cancel the order (with optional reason) |
| **Refund** | Process full or partial refund |

---

## 10. Delivery Management

### Delivery Board (`/deliveries`)

A Kanban-style board showing deliveries by status:

- **Scheduled** — Upcoming deliveries
- **Out for Delivery** — Currently being delivered
- **Delivered** — Completed
- **Failed** — Delivery attempt failed

### Delivery Routes (`/delivery-routes`)

Optimize delivery logistics:

1. **Create Route** — Select scheduled deliveries, group by zone
2. **Assign Driver** — Pick an available driver
3. **Start Route** — Driver begins deliveries
4. **Complete Route** — Mark all deliveries complete, driver becomes available

### Wire Orders

For **FTD / Teleflora** wire service orders:

- **Wire Vendors** (`/wire-vendors`) — Manage partner florists
- **Wire Settlements** (`/wire-settlements`) — Track payments between wire partners

---

## 11. Payment Processing

### Payment Methods

| Method | How It Works |
|--------|-------------|
| **Cash** | Enter amount received, system calculates change |
| **Card** | Processed via configured payment gateway or external terminal |
| **UPI** | India-specific digital payment |
| **Gift Card** | Enter gift card code, balance is deducted |
| **Bank Transfer** | Manual verification by manager |
| **Split Payment** | Combine multiple methods on one order |

### Payment Statuses

- **Unpaid** — No payment received
- **Partially Paid** — Deposit or partial payment
- **Paid** — Full payment received
- **Refunded** — Payment returned to customer

---

## 12. Refunds

**Navigate to**: Order List → Click order → **Refund**

1. Select items to refund (or full order)
2. Choose refund method:
   - **Original** — Refund to original payment method
   - **Store Credit** — Issue credit for future purchases
3. Toggle **Restock** to return items to inventory
4. Add refund reason/notes
5. Process refund

---

## 13. Events & Weddings

### Event List (`/events`)

Manage floral events — weddings, corporate, funerals, parties.

### Event Lifecycle

```
INQUIRY → PROPOSAL_SENT → CONFIRMED → IN_PRODUCTION → COMPLETED
                        → CANCELLED (if client declines)
```

### Creating an Event (`/events/new`)

| Field | Description |
|-------|-------------|
| Event Type | Wedding, Corporate, Funeral, Party, Other |
| Client | Select or create customer |
| Event Date | When the event occurs |
| Venue | Location details |
| Budget | Estimated budget |
| Style Notes | Color themes, flower preferences, mood board |

### Proposals (`/proposals`)

1. **Create Proposal** — Itemized quote with flowers, arrangements, labor
2. **Send to Client** — Status changes to PROPOSAL_SENT
3. **Client Approves** → Confirm event, collect deposit
4. **Client Requests Changes** → Revise and resend
5. **Client Declines** → Cancel

### Event Payments (`/events/:id/payments`)

Track deposits and final payments for events.

### Event Production (`/events/:id/production`)

Plan and source materials needed for the event.

---

## 14. Floral Production Engine

**Navigate to**: Sidebar → **Production**

### 14.1 Recipes (`/production/recipes`)

Create floral recipes (Bill of Materials):

| Field | Description |
|-------|-------------|
| Recipe Name | e.g., "Classic Rose Bouquet" |
| Category | Bouquet, Arrangement, Centerpiece, Wreath, Corsage, Boutonniere |
| Components | List of raw materials with quantities and costs |
| Labor Cost | Per-unit labor cost |
| Selling Price | Retail price of finished product |

### 14.2 Produce (`/production/produce`)

Pre-produce finished arrangements:

1. **Select Recipe** from the list
2. **Enter Quantity** to produce
3. **Select Location** where production happens
4. **Check Stock** — system validates all components are available
5. **Set Expected Expiry** (default: 3 days)
6. **Produce** — Creates a finished goods batch with barcode

### 14.3 Finished Goods (`/production/finished-goods`)

View inventory of pre-made arrangements:

- Batch code and barcode
- Quantity produced vs. available
- Expiry status (Active, Expired, Discarded)
- Location

### 14.4 Custom Bouquet Builder (`/production/custom-builder`)

Build one-off custom arrangements:

1. Select flowers and materials from inventory
2. Set quantities and pricing
3. Either **Sell Directly** or **Save as Recipe** for future reuse

### 14.5 Wastage Log (`/production/wastage`)

Track material wastage:

- Product, quantity, reason (Spoiled, Wilted, Damaged)
- Link to specific finished batch (optional)
- Date and staff who recorded it

---

## 15. Gift Cards

**Navigate to**: Sidebar → **Gift Cards** → **Card Designer**

### Operations

| Action | Description |
|--------|-------------|
| **Issue** | Create a new gift card with balance |
| **Redeem** | Deduct balance when used as payment |
| **Check Balance** | Look up remaining balance by card code |
| **Deactivate** | Disable a gift card |

Gift cards can be used as a payment method during POS checkout.

---

## 16. Day Close (End-of-Day)

**Navigate to**: Sidebar → **Sales** → **Day Close**

### Process

1. **Review Day's Summary**:
   - Total orders processed
   - Total sales amount
   - Payment breakdown (cash, card, UPI, etc.)
   - Refunds processed
2. **Count Physical Cash** in the register
3. **Enter Counted Amount** — system compares with expected cash
4. **Record Variance** (if any) with reason:
   - Short / Over
   - Reason (miscounted change, missing receipt, etc.)
5. **Close Day** — Locks the day's transactions

> ⚡ **Important**: Day Close should be done every day before leaving. It prevents order/payment modifications on closed days.

---

## 17. Reports & Analytics

### 17.1 Inventory Health Dashboard (`/health-dashboard`)

Overall inventory health:

- Stock coverage days
- Expiry risk percentage
- Dead stock identification
- Category-wise distribution

### 17.2 Profit Intelligence (`/profit-intelligence`)

Financial analytics:

- Revenue vs. Cost trends
- Profit margins by product/category
- Top-selling and least-selling products
- Time-based comparisons

### 17.3 Stock Valuation (`/valuation`)

Current inventory value:

- Total stock value at cost
- Total stock value at retail
- Value by category and location
- Potential write-off for expired stock

### 17.4 Stock Movement Ledger (`/stock-ledger`)

Complete history of every stock movement:

- Purchases, sales, adjustments
- Batch-level tracking
- Date range filtering
- Export capability

### 17.5 Reorder Intelligence (`/reorder`)

Smart restocking recommendations:

- Products below reorder level
- Lead time considerations
- Suggested order quantities

---

## 18. Audit Logs

**Navigate to**: Sidebar → **Settings** → **Audit Logs**

Every action in the system is automatically logged:

| What's Logged | Details |
|---------------|---------|
| **Login/Logout** | Who, when, IP address, success/failure |
| **Create** | Every new order, customer, product, payment |
| **Update** | Every status change, edit, assignment |
| **Delete** | Every deletion or deactivation |
| **Payments** | Every payment received, voided, refunded |
| **Day Close** | Every end-of-day closure |

### Searching Audit Logs

Filter by:

- User name
- Action type (CREATE, UPDATE, DELETE, LOGIN, etc.)
- Entity type (Order, Product, Customer, etc.)
- Date range
- Success/failure status

### Use Cases

- **Security**: Track who logged in and from where
- **Compliance**: Full trail of all financial transactions
- **Debugging**: Trace what happened to a specific order
- **Performance**: See which staff members are most active

---

## 19. Subscription & Billing

**Navigate to**: Sidebar → **Settings** → **Subscription**

Manage your plan and billing:

- View current plan (PRO, etc.)
- Subscription status
- Billing history

---

## 20. Recommended Workflow Order

When setting up a new store, follow this sequence:

```
Step  Action                          Where
────  ──────────────────────────────  ─────────────────────────
 1    Complete Onboarding Wizard      /onboarding
 2    Configure Locations             /settings/locations
 3    Set up Tax Rules                /settings/tax-rules
 4    Create Delivery Zones           /settings/delivery-zones
 5    Configure Payment Gateway       /settings/payment-gateways
 6    Create Product Categories       /categories
 7    Add Suppliers                   /suppliers
 8    Add Products (top 20 first)     /products/new
 9    Create Purchase Orders          /purchases/new
10    Receive Stock (creates batches) /purchases → Receive
11    Add Staff Members               /staff/new
12    Add Key Customers               /crm/customers
13    Create Floral Recipes           /production/recipes/new
14    Start Selling! (POS)            /pos
15    Process Phone Orders            /phone-orders/new
16    Day Close                       /day-close
```

### Daily Routine

| Time | Activity | Screen |
|------|----------|--------|
| **Opening** | Start shift, verify cash | POS (`/pos`) |
| **Morning** | Check expiry alerts | `/expiry-alerts` |
| **Morning** | Review reorder needs | `/reorder` |
| **All Day** | Process walk-in sales | POS (`/pos`) |
| **All Day** | Process phone orders | `/phone-orders/new` |
| **All Day** | Manage deliveries | `/deliveries` |
| **All Day** | Update order statuses | `/order-list` |
| **Evening** | Review day's performance | `/dashboard` |
| **Closing** | Day Close procedure | `/day-close` |

---

## Quick Reference — Keyboard Shortcuts & Tips

| Tip | Description |
|-----|-------------|
| Use **barcode scanner** | Scan product/batch barcodes directly in POS |
| **FIFO is automatic** | Oldest batches are always sold first |
| **Split payments** | Combine cash + card + gift card on one order |
| **Batch expiry** | System warns you before selling expired stock |
| **Multi-location** | Staff see only their assigned location's data |
| **Audit trail** | Every click that changes data is logged |

---

## Need Help?

- **API Documentation**: https://localhost:5001/scalar
- **Source Code**: https://github.com/sumitkumarsingh88/FloristERP
- **Contact**: Sumit Kumar Singh / Anand Kumar

---

*Made with 🌸 for Florists*
