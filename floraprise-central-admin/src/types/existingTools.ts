export type ExistingToolCategory = 'PLATFORM' | 'CUSTOMER / SALES' | 'SUBSCRIPTIONS' | 'OPERATIONS';

export type ExistingToolStatus = 'Available' | 'Requires Separate Login' | 'Tenant-Scoped' | 'Not Connected';

export interface ExistingAdminTool {
  id: string;
  name: string;
  category: ExistingToolCategory;
  description: string;
  url: string;
  iconName: string;
  target: '_blank' | '_self';
  badge?: string;
  status: ExistingToolStatus;
  authRequirement: string;
  isPrimary?: boolean;
}
