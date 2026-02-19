/**
 * TaskMockData.ts — Mock Task Data
 *
 * Provides realistic sample tasks for the Task Module.
 * API-ready: replace with real API calls later.
 */
import type { Task, TaskStatus, TaskFilterStatus } from './TaskTypes';

// ─── Mock Tasks ─────────────────────────────────────────────

export const MOCK_TASKS: Task[] = [
  {
    id: 'task-001',
    tenantId: 'tenant-001',
    locationId: 'loc-001',
    title: 'Prepare rose bouquet for walk-in order',
    description: 'Customer wants 24 red roses with baby breath. Wrap in premium gold paper.',
    relatedEntityType: 'ORDER',
    relatedEntityId: 'ORD-001',
    assignedTo: 'staff-004', // Meera (Designer)
    dueDate: '2026-02-19',
    status: 'IN_PROGRESS',
    priority: 'HIGH',
    createdAt: '2026-02-19T08:00:00Z',
  },
  {
    id: 'task-002',
    tenantId: 'tenant-001',
    locationId: 'loc-001',
    title: 'Deliver to 23 Linking Rd, Bandra',
    description: 'Birthday delivery. Call before arriving. Gate code: 4521.',
    relatedEntityType: 'DELIVERY',
    relatedEntityId: 'ORD-002',
    assignedTo: 'staff-008', // Vikram (Driver)
    dueDate: '2026-02-19',
    status: 'PENDING',
    priority: 'HIGH',
    createdAt: '2026-02-19T07:30:00Z',
  },
  {
    id: 'task-003',
    tenantId: 'tenant-001',
    locationId: 'loc-001',
    title: 'Design centrepieces for Sharma wedding',
    description: '15 table centrepieces — white & peach roses, eucalyptus garland.',
    relatedEntityType: 'EVENT',
    relatedEntityId: 'EVT-001',
    assignedTo: 'staff-004', // Meera (Designer)
    dueDate: '2026-02-22',
    status: 'PENDING',
    priority: 'MEDIUM',
    createdAt: '2026-02-18T14:00:00Z',
  },
  {
    id: 'task-004',
    tenantId: 'tenant-001',
    locationId: 'loc-001',
    title: 'Restock cooler display',
    description: 'Move fresh inventory from storage to front cooler. Rotate older stock forward.',
    assignedTo: 'staff-003', // Amit (Cashier)
    dueDate: '2026-02-19',
    status: 'COMPLETED',
    priority: 'LOW',
    createdAt: '2026-02-18T16:00:00Z',
  },
  {
    id: 'task-005',
    tenantId: 'tenant-001',
    locationId: 'loc-002',
    title: 'Phone order arrangement — funeral sympathy',
    description: 'White lily standing spray. Ribbon text: "In Loving Memory". Due by 2pm.',
    relatedEntityType: 'ORDER',
    relatedEntityId: 'ORD-005',
    assignedTo: 'staff-005', // Ananya (Designer, loc-002)
    dueDate: '2026-02-19',
    status: 'IN_PROGRESS',
    priority: 'HIGH',
    createdAt: '2026-02-19T09:00:00Z',
  },
  {
    id: 'task-006',
    tenantId: 'tenant-001',
    locationId: 'loc-001',
    title: 'Deliver Sharma wedding centrepieces to venue',
    description: 'Venue: Grand Hyatt Ballroom A. Setup before 4 PM. Ask for Ritu at reception.',
    relatedEntityType: 'DELIVERY',
    relatedEntityId: 'EVT-001',
    assignedTo: 'staff-008', // Vikram (Driver)
    dueDate: '2026-02-22',
    status: 'PENDING',
    priority: 'MEDIUM',
    createdAt: '2026-02-18T14:30:00Z',
  },
  {
    id: 'task-007',
    tenantId: 'tenant-001',
    locationId: 'loc-002',
    title: 'Afternoon delivery run — 3 orders',
    description: 'ORD-010, ORD-011, ORD-012. All Andheri West addresses.',
    relatedEntityType: 'DELIVERY',
    relatedEntityId: 'ORD-010',
    assignedTo: 'staff-009', // Rajan (Driver, loc-002)
    dueDate: '2026-02-19',
    status: 'PENDING',
    priority: 'MEDIUM',
    createdAt: '2026-02-19T06:00:00Z',
  },
  {
    id: 'task-008',
    tenantId: 'tenant-001',
    locationId: 'loc-001',
    title: 'Process online order ORD-015',
    description: 'Verify payment received, print label, assign to designer.',
    relatedEntityType: 'ORDER',
    relatedEntityId: 'ORD-015',
    assignedTo: 'staff-003', // Amit (Cashier)
    dueDate: '2026-02-19',
    status: 'PENDING',
    priority: 'MEDIUM',
    createdAt: '2026-02-19T10:00:00Z',
  },
  {
    id: 'task-009',
    tenantId: 'tenant-001',
    locationId: 'loc-003',
    title: 'Create 6 corsages for Patel event',
    description: 'White orchid corsages with pearl pins. Pack individually.',
    relatedEntityType: 'EVENT',
    relatedEntityId: 'EVT-003',
    assignedTo: 'staff-006', // Priya G (Designer, loc-003)
    dueDate: '2026-02-20',
    status: 'PENDING',
    priority: 'MEDIUM',
    createdAt: '2026-02-18T10:00:00Z',
  },
  {
    id: 'task-010',
    tenantId: 'tenant-001',
    locationId: 'loc-001',
    title: 'Update window display for Valentine clearance',
    description: 'Remove Valentine signage, put up spring theme.',
    assignedTo: 'staff-004', // Meera (Designer)
    status: 'COMPLETED',
    priority: 'LOW',
    createdAt: '2026-02-17T09:00:00Z',
  },
  {
    id: 'task-011',
    tenantId: 'tenant-001',
    locationId: 'loc-001',
    title: 'Review weekly purchase orders',
    description: 'Verify next week\'s purchase quantities with supplier quotes.',
    assignedTo: 'staff-002', // Priya (Manager)
    dueDate: '2026-02-20',
    status: 'PENDING',
    priority: 'MEDIUM',
    createdAt: '2026-02-19T08:30:00Z',
  },
  {
    id: 'task-012',
    tenantId: 'tenant-001',
    locationId: 'loc-004',
    title: 'Process Pune store opening-day cash register',
    description: 'Count float, ensure POS terminal is synced.',
    assignedTo: 'staff-010', // Neha (Cashier, loc-004)
    dueDate: '2026-02-19',
    status: 'IN_PROGRESS',
    priority: 'HIGH',
    createdAt: '2026-02-19T07:00:00Z',
  },
];

// ─── Data Access Helpers (API-ready) ────────────────────────

let tasks = [...MOCK_TASKS];

/** Get all tasks (admin/manager view) */
export const getAllTasks = (): Task[] => [...tasks];

/** Get tasks assigned to a specific staff member */
export const getTasksForStaff = (staffId: string): Task[] =>
  tasks.filter((t) => t.assignedTo === staffId);

/** Get delivery-related tasks (driver view) */
export const getDeliveryTasks = (): Task[] =>
  tasks.filter((t) => t.relatedEntityType === 'DELIVERY');

/** Get tasks by status */
export const getTasksByStatus = (status: TaskFilterStatus): Task[] =>
  status === 'ALL' ? [...tasks] : tasks.filter((t) => t.status === status);

/** Get a single task */
export const getTaskById = (taskId: string): Task | undefined =>
  tasks.find((t) => t.id === taskId);

/** Update task status (mock — mutates local array) */
export const updateTaskStatus = (taskId: string, newStatus: TaskStatus): Task | undefined => {
  const idx = tasks.findIndex((t) => t.id === taskId);
  if (idx === -1) return undefined;
  tasks[idx] = { ...tasks[idx], status: newStatus };
  return tasks[idx];
};

/** Create a new task (mock — appends to local array) */
export const createTask = (taskData: Omit<Task, 'id' | 'createdAt'>): Task => {
  const newTask: Task = {
    ...taskData,
    id: `task-${String(tasks.length + 1).padStart(3, '0')}`,
    createdAt: new Date().toISOString(),
  };
  tasks = [...tasks, newTask];
  return newTask;
};

/** Summary stats */
export const getTaskSummary = () => {
  const all = tasks;
  return {
    total: all.length,
    pending: all.filter((t) => t.status === 'PENDING').length,
    inProgress: all.filter((t) => t.status === 'IN_PROGRESS').length,
    completed: all.filter((t) => t.status === 'COMPLETED').length,
    highPriority: all.filter((t) => t.priority === 'HIGH' && t.status !== 'COMPLETED').length,
    dueToday: all.filter((t) => t.dueDate === new Date().toISOString().split('T')[0] && t.status !== 'COMPLETED').length,
  };
};
