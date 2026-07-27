# Floraprise Home Dashboard Mockup Options

Status: design review only. Do not implement the production dashboard until one option is selected.

Goal: make Home answer "What should a florist do today?" instead of "Which module do you want to open?"

Home dashboard philosophy: Home is the florist's business control center, not a menu or feature directory. Every card must satisfy all of these rules:
- It answers exactly one of the three Home questions.
- It has a clear daily business purpose.
- It belongs in daily operations, not weekly/monthly administration.

The three Home questions are:
- How is my business today? Business Snapshot.
- What should I do next? Today's Work.
- Where do I manage this part of my business? Grouped Workspaces.

If a card does not answer one of these questions, it does not belong on Home.
Do not mix questions inside one card. For example, a revenue card should not also contain quick-action buttons.
Rarely used features belong inside Settings or More, not on Home. Examples: Subscription, Support, User Management, Printer Settings, Backup, Import/Export, and App Information.

Existing data to reuse:
- `DashboardSummary.todaySalesAmount`
- `DashboardSummary.todayOrderCount`
- `DashboardSummary.todayDeliveryCount`
- `DashboardSummary.todayPendingPayments`
- `DashboardSummary.preparingOrders`
- `DashboardSummary.readyOrders`
- `DashboardSummary.outForDeliveryOrders`
- `DashboardSummary.todayPickupCount`
- `DashboardSummary.todayFollowUps`
- `DashboardSummary.todayTaskCount`
- `DashboardSummary.lowStockItems`
- `DashboardSummary.outOfStockItems`
- `DashboardSummary.lowStockList`
- `DashboardSummary.todaySchedule`
- `DashboardSummary.activeStaff`
- `DashboardSummary.activeAssociates`

Current Home route targets to preserve:
- `/walkin-sales`
- `/orders`
- `/customers`
- `/associates`
- `/products`
- `/inventory`
- `/purchase-list`
- `/staff`
- `/reminders`
- `/scheduler`
- `/barcode`

Shared visual direction:
- Material 3, warm white surface, botanical green primary, restrained accent colors.
- 16-20 px card radius, soft elevation, 16 px page padding, 12-16 px internal rhythm.
- Large touch targets, minimum 48 px rows and controls.
- No dense icon grid. Workspace groups use compact rows or grouped cards.
- Hide zero-count action items.
- Do not add separate insight, promotion, announcement, or shortcut cards unless they are expressed as Business Snapshot, Today's Work, or Grouped Workspaces.
- Do not place rarely used admin, setup, support, account, or app-information features on Home.
- Keep database schema, repositories, business logic, and route names unchanged.

## Option 1: Command Center

Best for launch. This feels most like a premium ERP home screen: KPIs first, then a decisive work queue, then grouped operating areas.

Mobile wireframe:

```text
+------------------------------------------------+
| Floraprise                         Profile     |
| Morning, Rose Petal Florist                    |
| Today is ready for review                      |
+------------------------------------------------+

+------------------+  +-------------------------+
| Today Sales      |  | Today's Orders          |
| Rs 12,450        |  | 18                      |
+------------------+  +-------------------------+
| Deliveries       |  | Pending Payments        |
| 6                |  | 3                       |
+------------------+  +-------------------------+

Today's Work
+------------------------------------------------+
| Prepare Bouquets              4       Orders > |
| Deliver Orders                6       Orders > |
| Customer Pickups              2       Orders > |
| Payment Follow-up             3    Reminders > |
| Today's Reminders             5    Reminders > |
+------------------------------------------------+

Grouped Workspaces
+------------------------------------------------+
| Sales & Orders                                >|
| Walk-in Sale   Orders   Customers  Associates |
+------------------------------------------------+
| Catalogue & Inventory                         >|
| Categories      Products  Inventory  Purchase |
+------------------------------------------------+
| Team                                            |
| Staff          Attendance  Delivery            |
+------------------------------------------------+
| Finance                                         |
| Cash Book      Expenses    Payments   Reports  |
+------------------------------------------------+
```

Desktop/tablet adaptation:

```text
+------------------------------------------------------------+
| Header                                                     |
+------------------------------------------------------------+

+----------+ +----------+ +----------+ +----------+
| Sales    | | Orders   | | Delivery | | Payments |
+----------+ +----------+ +----------+ +----------+

+------------------------------------------------------------+
| Today's Work: prepare / deliver / payments / low stock      |
+------------------------------------------------------------+

+------------------------------------------------------------+
| Workspaces grouped in two-column cards                      |
+------------------------------------------------------------+
```

Why choose this:
- Most balanced option for first-time impression and daily use.
- Keeps KPIs prominent without letting metrics dominate the task flow.
- Workspaces still fit future modules naturally without another redesign.
- Low risk because it maps cleanly to the existing `DashboardSummary`.

Tradeoff:
- It is polished and familiar rather than highly distinctive.

Implementation notes after approval:
- Replace `_buildAttentionSection` with `_buildTodaysWork`.
- Move `_buildTodaySchedule` into Today's Work; do not keep it as a fourth section.
- Convert low-stock and pending-payment signals into Today's Work rows when they require action.
- Create reusable private widgets: `_KpiCard`, `_WorkQueueCard`, `_WorkspaceGroupCard`.
- Use `Selector<DashboardProvider, DashboardSummary>` for each section to reduce unnecessary rebuilds.

## Option 2: Agenda First

Best for shops where execution discipline matters most. This makes the day queue the hero and treats KPIs as supporting context.

Mobile wireframe:

```text
+------------------------------------------------+
| Floraprise                         Profile     |
| What needs attention today?                    |
+------------------------------------------------+

Today's Work Priority
+------------------------------------------------+
| 15 open tasks                                  |
| Prepare 4 bouquets before noon                 |
+------------------------------------------------+

Today's Work
+------------------------------------------------+
| 09:30  Prepare     Mehta wedding bouquet    >  |
| 11:00  Delivery    Patel residence          >  |
| 02:00  Pickup      Corporate order          >  |
| 05:00  Payment     Sharma follow-up         >  |
+------------------------------------------------+

Business Snapshot
+----------+ +----------+ +----------+ +----------+
| Sales    | | Orders   | | Delivery | | Payments |
+----------+ +----------+ +----------+ +----------+

Grouped Workspaces
+------------------------------------------------+
| Sales & Orders                                >|
| Catalogue & Inventory                         >|
| Team                                          >|
| Finance                                       >|
+------------------------------------------------+
```

Why choose this:
- Strongest answer to "What should I do today?"
- Feels like an operating cockpit, not a launcher.
- Makes schedule and reminders feel central to Floraprise.

Tradeoff:
- First-time users may see fewer modules above the fold, so the app may feel less broad until they scroll.
- Requires careful empty states so a quiet day still feels premium instead of blank.

Implementation notes after approval:
- Use `todaySchedule` as the backbone, then add summary-derived rows for preparation, delivery, pickup, payments, and reminders.
- Hide zero-count rows.
- If current screens do not support deep filters, tap rows to the current route first and add presentation-only filter arguments in a later step.

## Option 3: Owner Overview

Best for owner/managers who want command, revenue, and operations at a glance. This option feels more like Shopify or Stripe: a premium business overview with actions embedded.

Mobile wireframe:

```text
+------------------------------------------------+
| Floraprise                         Profile     |
| Rose Petal Florist                             |
+------------------------------------------------+

+------------------------------------------------+
| Today                                          |
| Rs 12,450 sales                               |
| 18 orders  /  6 deliveries  /  3 payments     |
+------------------------------------------------+

Today's Work
+----------------------+ +-----------------------+
| Prepare              | | Deliver               |
| 4                    | | 6                     |
+----------------------+ +-----------------------+
| Payments             | | Reminders             |
| 3                    | | 5                     |
+----------------------+ +-----------------------+

Grouped Workspaces
+------------------------------------------------+
| Sales & Orders       Walk-in, Orders, Customers|
| Inventory            Products, Stock, Purchase |
| Team                 Staff, Attendance, Delivery|
| Finance              Cash, Expenses, Reports   |
+------------------------------------------------+

Today's Work after closing time
+------------------------------------------------+
| Close Today's Sales                            |
| Verify Cash                                    |
| Complete Deliveries                            |
| Mark Attendance                                |
| Close Day                                      |
+------------------------------------------------+
```

Why choose this:
- Strongest premium first impression.
- Gives the business owner an immediate "how are we doing?" read.
- Keeps owner-level performance separate from the work queue and workspace navigation.

Tradeoff:
- The hero card can become too large on small phones if copy is not kept very tight.
- Less operationally direct than Option 2 because the queue is not the first visual object.

Implementation notes after approval:
- Convert the four KPI cards into one large `Today` hero card on phones, then split into four KPI cards on wider layouts.
- Use a `SliverList` or plain `ListView` depending on whether pull-to-refresh and sticky headers are desired.
- After the configured closing hour, Today's Work can switch from daytime operations to closing tasks.

## Day Closing Behavior

Day Closing is not a separate Home section. It is the evening state of Today's Work because it answers "What should I do next?"

Recommended display:

```text
Today's Work
+------------------------------------------------+
| Close Today's Sales                    Pending |
| Verify Cash                            Pending |
| Complete Deliveries                    Pending |
| Mark Attendance                        Pending |
| Close Day                              Ready   |
+------------------------------------------------+
```

Initial implementation can use a local dashboard constant for review builds, then connect to business settings only if the setting already exists. Do not add schema or database version changes for this redesign.

## Workspace Group Map

Sales & Orders:
- Walk-in Sale: `/walkin-sales`
- Orders: `/orders`
- Customers: `/customers`
- Associates: `/associates`

Catalogue & Inventory:
- Categories: existing category surface if available, otherwise future placeholder
- Products: `/products`
- Inventory: `/inventory`
- Purchase: `/purchase-list`
- Recipes: future placeholder
- Stock Adjustment: future placeholder
- Barcode Labels: `/barcode`

Team:
- Staff: `/staff`
- Attendance: future placeholder
- Delivery: `/scheduler` or `/orders` depending on selected implementation
- Leave: future placeholder

Finance:
- Cash Book: future placeholder
- Expenses: future placeholder
- Payments: `/reminders` or `/orders` depending on selected implementation
- Reports: future placeholder
- Day Closing: future placeholder outside Home; on Home, closing tasks belong under Today's Work

Not on Home:
- Settings: `/settings`
- Subscription: Settings or More
- Support: Settings or More
- User Management: Settings or More
- Printer Settings: Settings or More
- Backup: Settings or More
- Import/Export: Settings or More
- App Information: Settings or More

## Recommendation

Choose Option 1 for public launch unless the product strategy is to make Floraprise feel primarily like a task execution system. Option 1 gives the best balance of premium impression, practical daily guidance, and future-ready module grouping.

Use Option 2 if the main buyer pain is missed preparation, delivery, pickup, and payment work.

Use Option 3 if the main buyer is the shop owner and the first impression must feel more like a business health cockpit.

## Approval Checklist Before Build

- Select one option as the base layout.
- Decide how `todaySchedule` merges into Today's Work.
- Keep future or rarely used modules hidden from Home until they become daily business workspaces.
- Confirm whether bottom navigation remains unchanged for launch.
- Confirm the configured evening time for Day Closing.