import { ExistingAdminTool, ExistingToolCategory } from '../../types/existingTools';

const VERIFIED_EXISTING_TOOLS: ExistingAdminTool[] = [
  // 1. PLATFORM
  {
    id: 'tool-erp-dashboard',
    name: 'ERP Platform SuperAdmin Dashboard',
    category: 'PLATFORM',
    description: 'Enterprise ERP backoffice platform control dashboard for tenant organizations, platform telemetry, and global system health.',
    url: 'https://erp.floraprise.com/admin/dashboard',
    iconName: 'LayoutDashboard',
    target: '_blank',
    badge: 'SuperAdmin Backoffice',
    status: 'Requires Separate Login',
    authRequirement: 'PlatformSuperAdmin (Policy: PlatformOnly)',
    isPrimary: false
  },
  {
    id: 'tool-audit-logs',
    name: 'Platform Audit Logs Trail',
    category: 'PLATFORM',
    description: 'Tamper-proof chronological log of administrative actions, billing adjustments, and tenant security events across the entire platform.',
    url: 'https://erp.floraprise.com/admin/audit-logs',
    iconName: 'ShieldAlert',
    target: '_blank',
    badge: 'Platform Support Audit',
    status: 'Available',
    authRequirement: 'PlatformSupport, PlatformSuperAdmin',
    isPrimary: false
  },
  {
    id: 'tool-platform-settings',
    name: 'Platform System Settings',
    category: 'PLATFORM',
    description: 'Global system configuration, payment gateway credentials, SMS/WhatsApp integrations, and maintenance mode toggles.',
    url: 'https://erp.floraprise.com/admin/settings',
    iconName: 'Sliders',
    target: '_blank',
    badge: 'System Settings',
    status: 'Requires Separate Login',
    authRequirement: 'PlatformSuperAdmin',
    isPrimary: false
  },
  {
    id: 'tool-platform-analytics',
    name: 'Platform-Wide Analytics',
    category: 'PLATFORM',
    description: 'Aggregated multi-tenant performance analytics, subscription metrics, order volume across branches, and platform load.',
    url: 'https://erp.floraprise.com/admin/analytics',
    iconName: 'BarChart3',
    target: '_blank',
    badge: 'Platform Metrics',
    status: 'Requires Separate Login',
    authRequirement: 'PlatformSuperAdmin',
    isPrimary: false
  },
  {
    id: 'tool-data-cleanup',
    name: 'Tenant Data Cleanup & Reset',
    category: 'PLATFORM',
    description: 'Administrative data maintenance, test transaction clearing, and transactional database reset utilities for go-live subscribers.',
    url: 'https://erp.floraprise.com/settings/data-cleanup',
    iconName: 'Trash2',
    target: '_blank',
    badge: 'Tenant Reset Ops',
    status: 'Requires Separate Login',
    authRequirement: 'CompanyAdmin (Policy: CompanyAdmin)',
    isPrimary: false
  },

  // 2. CUSTOMER / SALES
  {
    id: 'tool-demo-requests',
    name: 'Demo Requests & Inbound Leads',
    category: 'CUSTOMER / SALES',
    description: 'Review inbound trial and demo submissions from floraprise.com, qualify leads, approve requests, and provision evaluation tenants.',
    url: 'https://erp.floraprise.com/admin/demo-requests',
    iconName: 'UserCheck',
    target: '_blank',
    badge: 'Sales & Onboarding',
    status: 'Requires Separate Login',
    authRequirement: 'PlatformSuperAdmin (Policy: PlatformOnly)',
    isPrimary: true
  },
  {
    id: 'tool-erp-companies',
    name: 'ERP Company Master Directory',
    category: 'CUSTOMER / SALES',
    description: 'Manage core tenant company entities, corporate tax IDs, legal business profiles, and tenant deactivation.',
    url: 'https://erp.floraprise.com/admin/companies',
    iconName: 'Building2',
    target: '_blank',
    badge: 'Company Registry',
    status: 'Requires Separate Login',
    authRequirement: 'PlatformSuperAdmin',
    isPrimary: false
  },
  {
    id: 'tool-mobile-customers',
    name: 'Mobile Customer & Subscriber Directory',
    category: 'CUSTOMER / SALES',
    description: 'Complete directory of mobile app subscriber accounts, registered store owners, phone number bindings, and sync sessions.',
    url: 'https://erp.floraprise.com/admin/mobile/customers',
    iconName: 'Users',
    target: '_blank',
    badge: 'Platform Support Directory',
    status: 'Available',
    authRequirement: 'PlatformSupport, PlatformSuperAdmin',
    isPrimary: true
  },
  {
    id: 'tool-support-activity',
    name: 'Support & Customer Activity Trail',
    category: 'CUSTOMER / SALES',
    description: 'Audit trail of support actions taken on customer accounts, password resets, onboarding approvals, and tenant modifications.',
    url: 'https://erp.floraprise.com/admin/mobile/support-activity',
    iconName: 'Activity',
    target: '_blank',
    badge: 'Support Audit',
    status: 'Available',
    authRequirement: 'PlatformSupport, PlatformSuperAdmin',
    isPrimary: false
  },

  // 3. SUBSCRIPTIONS
  {
    id: 'tool-central-plan-catalog',
    name: 'Central Admin Plan Catalog',
    category: 'SUBSCRIPTIONS',
    description: 'Official source-of-truth commercial subscription tiers, device allowances, staff limits, offline grace periods, and live pricing.',
    url: '/subscriptions/plans',
    iconName: 'CreditCard',
    target: '_self',
    badge: 'Active Source of Truth',
    status: 'Available',
    authRequirement: 'PlatformSupport, PlatformSuperAdmin',
    isPrimary: true
  },
  {
    id: 'tool-mobile-licenses',
    name: 'Mobile Device Licenses Registry',
    category: 'SUBSCRIPTIONS',
    description: 'Cryptographic license key management, device binding enforcement, validity extensions, and suspension controls.',
    url: 'https://erp.floraprise.com/admin/mobile/licenses',
    iconName: 'KeyRound',
    target: '_blank',
    badge: 'License Registry',
    status: 'Available',
    authRequirement: 'PlatformSupport, PlatformSuperAdmin',
    isPrimary: false
  },
  {
    id: 'tool-mobile-devices',
    name: 'Registered Mobile Devices & Terminals',
    category: 'SUBSCRIPTIONS',
    description: 'Registry of all connected POS hardware, Android devices, and Flutter Web sessions across subscriber stores.',
    url: 'https://erp.floraprise.com/admin/mobile/devices',
    iconName: 'Smartphone',
    target: '_blank',
    badge: 'Device Registry',
    status: 'Available',
    authRequirement: 'PlatformSupport, PlatformSuperAdmin',
    isPrimary: false
  },

  // 4. OPERATIONS
  {
    id: 'tool-delivery-routes',
    name: 'Delivery Control Center & Route Manager',
    category: 'OPERATIONS',
    description: 'Multi-driver dispatch console, order grouping, GPS route tracking, geofence radius validation, and live proof-of-delivery.',
    url: 'https://erp.floraprise.com/delivery-routes',
    iconName: 'MapPin',
    target: '_blank',
    badge: 'Live Dispatch Console',
    status: 'Tenant-Scoped',
    authRequirement: 'CompanyAdmin / Dispatcher (Policy: CompanyOnly)',
    isPrimary: true
  },
  {
    id: 'tool-mobile-app',
    name: 'Mobile Web Client Operations',
    category: 'OPERATIONS',
    description: 'Web client interface for retail store operations, cashier barcode scanning, daily order intake, and customer lookups.',
    url: 'https://mobile.floraprise.com/',
    iconName: 'Smartphone',
    target: '_blank',
    badge: 'Store Operator Client',
    status: 'Requires Separate Login',
    authRequirement: 'CompanyAdmin / Staff',
    isPrimary: false
  }
];

class RealExistingToolsService {
  async getTools(): Promise<ExistingAdminTool[]> {
    return [...VERIFIED_EXISTING_TOOLS];
  }

  async getToolsByCategory(category: ExistingToolCategory): Promise<ExistingAdminTool[]> {
    return VERIFIED_EXISTING_TOOLS.filter(t => t.category === category);
  }
}

export const realExistingToolsService = new RealExistingToolsService();
