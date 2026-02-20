/**
 * TaskTypes.ts — Lightweight Staff Task & Work Allocation Types
 *
 * Supports:
 * - Task creation from Orders, Events, Deliveries
 * - Status tracking (PENDING → IN_PROGRESS → COMPLETED)
 * - Priority levels
 * - Role-based visibility
 */

// ─── Task Status ────────────────────────────────────────────

export type TaskStatus = 'PENDING' | 'IN_PROGRESS' | 'COMPLETED';

export const TASK_STATUSES: TaskStatus[] = ['PENDING', 'IN_PROGRESS', 'COMPLETED'];

export const TASK_STATUS_CONFIG: Record<TaskStatus, { label: string; color: string; icon: string }> = {
  PENDING: { label: 'Pending', color: '#ff9800', icon: '⏳' },
  IN_PROGRESS: { label: 'In Progress', color: '#2196f3', icon: '🔄' },
  COMPLETED: { label: 'Completed', color: '#4caf50', icon: '✅' },
};

// ─── Task Priority ──────────────────────────────────────────

export type TaskPriority = 'LOW' | 'MEDIUM' | 'HIGH';

export const TASK_PRIORITIES: TaskPriority[] = ['LOW', 'MEDIUM', 'HIGH'];

export const TASK_PRIORITY_CONFIG: Record<TaskPriority, { label: string; color: string }> = {
  LOW: { label: 'Low', color: '#9e9e9e' },
  MEDIUM: { label: 'Medium', color: '#ff9800' },
  HIGH: { label: 'High', color: '#f44336' },
};

// ─── Related Entity ─────────────────────────────────────────

export type RelatedEntityType = 'ORDER' | 'EVENT' | 'DELIVERY';

export const ENTITY_TYPE_CONFIG: Record<RelatedEntityType, { label: string; color: string; icon: string; path: string }> = {
  ORDER: { label: 'Order', color: '#2196f3', icon: '🧾', path: '/order-list' },
  EVENT: { label: 'Event', color: '#e91e63', icon: '🎉', path: '/events' },
  DELIVERY: { label: 'Delivery', color: '#00bcd4', icon: '🚚', path: '/delivery-scheduler' },
};

// ─── Task Model ─────────────────────────────────────────────

export interface Task {
  id: string;
  tenantId: string;
  locationId: string;
  title: string;
  description?: string;
  relatedEntityType?: RelatedEntityType;
  relatedEntityId?: string;
  assignedTo: string; // staff ID
  dueDate?: string;
  status: TaskStatus;
  priority?: TaskPriority;
  createdAt: string;
}

// ─── Task Form Data ─────────────────────────────────────────

export interface TaskFormData {
  title: string;
  description: string;
  relatedEntityType: RelatedEntityType | '';
  relatedEntityId: string;
  assignedTo: string;
  dueDate: string;
  priority: TaskPriority;
  locationId: string;
}

export const getInitialTaskFormData = (defaults?: Partial<TaskFormData>): TaskFormData => ({
  title: defaults?.title || '',
  description: defaults?.description || '',
  relatedEntityType: defaults?.relatedEntityType || '',
  relatedEntityId: defaults?.relatedEntityId || '',
  assignedTo: defaults?.assignedTo || '',
  dueDate: defaults?.dueDate || '',
  priority: defaults?.priority || 'MEDIUM',
  locationId: defaults?.locationId || '',
});

// ─── Filter Status (includes "ALL") ────────────────────────

export type TaskFilterStatus = TaskStatus | 'ALL';
