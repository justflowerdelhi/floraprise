export interface DiagnosticCheckItem {
  id: string;
  category: 'Infrastructure' | 'Database' | 'Entitlements' | 'Integrations' | 'Operational API';
  serviceName: string;
  endpointOrResource: string;
  status: 'Healthy' | 'Needs Attention' | 'Critical';
  latencyMs: number;
  lastCheckedAt: string;
  detail: string;
  suggestedRemediation?: string;
}

export interface MigrationJob {
  id: string;
  companyId: string;
  companyName: string;
  ownerPhone: string;
  sourceMode: 'Flutter Solo (SQLite)';
  targetMode: 'Flutter Cloud Android / Web';
  status: 'Not Started' | 'Preparing' | 'In Progress' | 'Completed' | 'Failed';
  currentStep: string;
  totalRecordsCount: number;
  processedRecordsCount: number;
  startedAt?: string;
  completedAt?: string;
  errorMessage?: string;
  initiatedBy: string;
}

export interface SupportIssue {
  id: string;
  ticketNumber: string;
  companyId: string;
  companyName: string;
  severity: 'Critical' | 'High' | 'Medium' | 'Low';
  category: 'Location / Provisioning' | 'Authentication' | 'Printing' | 'Delivery Sync' | 'Payment Gateway';
  title: string;
  description: string;
  status: 'Open' | 'Investigating' | 'Resolved' | 'Closed';
  assignedTo: string;
  createdAt: string;
  updatedAt: string;
}
