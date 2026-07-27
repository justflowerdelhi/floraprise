# Floraprise

Floraprise is a Flutter florist management app for daily sales, orders, delivery, inventory, customers, staff, reminders, reports, and business settings.

## Features

### 13 Fully Navigable Screens

1. **Dashboard** - Home screen with:
   - Today's Summary (Sales Today, Pending Orders, Scheduled Tasks)
   - 8-tile Quick Actions grid
   - Today's Schedule list

2. **My Designs** - Floral design portfolio with sample designs and usage statistics

3. **Walk-in Sales** - Daily walk-in customer transactions with sales metrics

4. **Orders** - Order management with tabs for Pending, In Progress, Ready, and Completed

5. **Customers** - Customer directory with VIP status and order history

6. **Staff** - Team management with duty status and task assignments

7. **Reminders** - Task reminders with priority levels and completion tracking

8. **Products** - Product catalog with stock levels and pricing

9. **Scheduler** - Calendar view with daily events and staff assignments

10. **Reports** - Report generation options for various business metrics

11. **Settings** - App configuration and account settings

12. **Analytics** - Business analytics with charts and performance metrics

13. **Inventory** - Inventory management with low stock alerts

## Design Principles

- **Material 3 Design System** - Modern Google Material Design implementation
- **Touch-Friendly Controls** - Large tap targets (minimum 48x48 pixels)
- **Consistent Spacing** - 8px grid system for consistent padding and margins
- **Clear Typography** - Hierarchical text sizing for readability
- **Visual Hierarchy** - Color-coded status indicators and priority levels
- **Smooth Navigation** - Intuitive screen transitions and back navigation

## UX Highlights

- **Dashboard Overview** - At-a-glance view of daily metrics and activities
- **Color-Coded Status** - Visual indicators for order status, stock levels, and priorities
- **Floating Action Buttons** - Quick access to create new items on each screen
- **Card-Based Layout** - Clean, scannable content organization
- **Responsive Lists** - Scrollable lists with proper separators and spacing
- **Search & Filter Icons** - Placeholder actions for future functionality

## Sample Data

All screens include realistic sample data:
- Customer names with contact information
- Product details with pricing and stock levels
- Order information with status tracking
- Staff members with duty assignments
- Scheduled events with time ranges
- Reminder tasks with priorities

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK compatible with Flutter version

### Installation

1. Clone or navigate to the project directory
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point with theme and routes
└── screens/
    ├── dashboard_screen.dart
    ├── my_designs_screen.dart
    ├── walkin_sales_screen.dart
    ├── orders_screen.dart
    ├── customers_screen.dart
    ├── staff_screen.dart
    ├── reminders_screen.dart
    ├── products_screen.dart
    ├── scheduler_screen.dart
    ├── reports_screen.dart
    ├── settings_screen.dart
    ├── analytics_screen.dart
    ├── profile_screen.dart
    └── inventory_screen.dart
```

## Navigation

The app uses named routes for navigation:
- `/dashboard` - Home screen
- `/my-designs` - Design portfolio
- `/walkin-sales` - Walk-in sales
- `/orders` - Order management
- `/customers` - Customer directory
- `/staff` - Staff management
- `/reminders` - Task reminders
- `/products` - Product catalog
- `/scheduler` - Calendar scheduler
- `/reports` - Reports
- `/settings` - Settings
- `/analytics` - Analytics
- `/profile` - User profile
- `/inventory` - Inventory management

## Future Implementation

This prototype is designed to be the foundation for full implementation. Future phases will include:
- SQLite database integration
- REST API connectivity
- Authentication and login
- State management (Provider/Riverpod)
- Repository pattern
- Business logic layer
- Real data synchronization

## Color Scheme

The app uses a green-based color scheme (`ColorScheme.fromSeed` with seed color `#2E7D32`) appropriate for a florist business, with semantic colors for different states and priorities.

## License

This is a prototype for demonstration purposes.
