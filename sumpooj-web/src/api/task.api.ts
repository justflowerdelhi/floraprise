/**
 * task.api.ts — Tasks API Service
 *
 * Endpoints:
 *   GET  /Tasks/search
 *   GET  /Tasks/pending
 *   GET  /Tasks/by-staff/:staffId
 *   GET  /Tasks/:id
 *   PUT  /Tasks/:id
 *   POST /Tasks
 *   POST /Tasks/:id/start
 *   POST /Tasks/:id/complete
 *   POST /Tasks/:id/reopen
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface TaskSearchParams {
  AssignedToStaffId?: string;
  LocationId?: string;
  Status?: string;
  Priority?: string;
  DueDateFrom?: string;
  DueDateTo?: string;
  Page?: number;
  PageSize?: number;
}

export interface CreateTaskRequest {
  locationId: string;
  title: string;
  description?: string | null;
  priority: string;
  assignedToStaffId: string;
  dueDate?: string | null;
  relatedEntityType?: string | null;
  relatedEntityId?: string | null;
}

export interface UpdateTaskRequest {
  title?: string | null;
  description?: string | null;
  priority?: string | null;
  assignedToStaffId?: string | null;
  dueDate?: string | null;
}

// ─── API Functions ──────────────────────────────────────────

export const searchTasks = async (params: TaskSearchParams = {}) => {
  const res = await api.get('/Tasks/search', { params });
  return res.data;
};

export const getPendingTasks = async (locationId?: string) => {
  const res = await api.get('/Tasks/pending', { params: { locationId } });
  return res.data;
};

export const getTasksByStaff = async (staffId: string) => {
  const res = await api.get(`/Tasks/by-staff/${staffId}`);
  return res.data;
};

export const getTaskById = async (id: string) => {
  const res = await api.get(`/Tasks/${id}`);
  return res.data;
};

export const updateTask = async (id: string, data: UpdateTaskRequest) => {
  const res = await api.put(`/Tasks/${id}`, data);
  return res.data;
};

export const createTask = async (data: CreateTaskRequest) => {
  const res = await api.post('/Tasks', data);
  return res.data;
};

export const startTask = async (id: string) => {
  const res = await api.post(`/Tasks/${id}/start`);
  return res.data;
};

export const completeTask = async (id: string) => {
  const res = await api.post(`/Tasks/${id}/complete`);
  return res.data;
};

export const reopenTask = async (id: string) => {
  const res = await api.post(`/Tasks/${id}/reopen`);
  return res.data;
};
