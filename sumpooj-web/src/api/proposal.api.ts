import api from './axios';
import type { PagedResult } from './types';

// ─── Types ──────────────────────────────────────────────────

export type ProposalStatus = 'DRAFT' | 'SENT' | 'VIEWED' | 'REVISION_REQUESTED' | 'ACCEPTED' | 'DECLINED' | 'EXPIRED';
export type ProposalItemType = 'PRODUCT' | 'SERVICE' | 'PACKAGE';

export interface ProposalItem {
  id: string;
  type: ProposalItemType;
  name: string;
  category: string;
  description?: string;
  linkedProductId?: string;
  linkedProductSku?: string;
  quantity: number;
  unitPrice: number;
  unitCost: number;
  totalPrice: number;
  totalCost: number;
  marginPercentage: number;
  notes?: string;
  sortOrder: number;
}

export interface Proposal {
  id: string;
  eventId: string;
  eventName?: string;
  proposalNumber: string;
  versionName: string;
  title: string;
  versionNumber: number;
  status: ProposalStatus;
  validUntil?: string;
  sentAt?: string;
  approvedAt?: string;
  respondedAt?: string;
  
  // Client
  clientName: string;
  clientEmail: string;
  clientPhone?: string;
  
  // Content
  introduction?: string;
  termsAndConditions?: string;
  paymentTerms?: string;
  notes?: string;
  internalNotes?: string;
  
  // Pricing
  subtotal: number;
  discountType: 'PERCENTAGE' | 'FIXED';
  discountValue: number;
  discount: number;
  taxRate: number;
  tax: number;
  grandTotal: number;
  totalCost: number;
  grossProfit: number;
  marginPercentage: number;
  depositAmount: number;
  depositPercent: number;
  
  clientFeedback?: string;
  declineReason?: string;
  
  items: ProposalItem[];
  
  createdAt: string;
  updatedAt: string;
}

export interface CreateProposalItemRequest {
  type: ProposalItemType;
  name: string;
  category: string;
  description?: string;
  linkedProductId?: string;
  quantity: number;
  unitPrice: number;
  unitCost: number;
  notes?: string;
  sortOrder: number;
}

export interface CreateProposalRequest {
  eventId: string;
  title: string;
  versionName?: string;
  clientName: string;
  clientEmail: string;
  clientPhone?: string;
  validUntil?: string;
  introduction?: string;
  termsAndConditions?: string;
  paymentTerms?: string;
  notes?: string;
  internalNotes?: string;
  discountType?: 'PERCENTAGE' | 'FIXED';
  discountValue?: number;
  taxRate?: number;
  depositPercent?: number;
  items: CreateProposalItemRequest[];
}

export interface UpdateProposalRequest extends CreateProposalRequest {}

export interface ProposalSearchParams {
  eventId?: string;
  status?: ProposalStatus;
  query?: string;
  page?: number;
  pageSize?: number;
}

// ─── API Functions ──────────────────────────────────────────

/** GET /proposals/search - Search proposals */
export const searchProposals = async (params: ProposalSearchParams): Promise<PagedResult<Proposal>> => {
  const res = await api.get('/proposals/search', { params });
  return res.data;
};

/** GET /proposals/:id - Get proposal by ID */
export const getProposalById = async (id: string): Promise<Proposal> => {
  const res = await api.get(`/proposals/${id}`);
  return res.data;
};

/** GET /proposals/by-event/:eventId - Get proposals for an event */
export const getProposalsByEvent = async (eventId: string): Promise<Proposal[]> => {
  const res = await api.get(`/proposals/by-event/${eventId}`);
  return res.data;
};

/** POST /proposals - Create new proposal */
export const createProposal = async (data: CreateProposalRequest): Promise<Proposal> => {
  const res = await api.post('/proposals', data);
  return res.data;
};

/** PUT /proposals/:id - Update proposal */
export const updateProposal = async (id: string, data: UpdateProposalRequest): Promise<Proposal> => {
  const res = await api.put(`/proposals/${id}`, data);
  return res.data;
};

/** POST /proposals/:id/send - Send proposal to client */
export const sendProposal = async (id: string): Promise<Proposal> => {
  const res = await api.post(`/proposals/${id}/send`);
  return res.data;
};

/** POST /proposals/:id/mark-viewed - Mark as viewed (client opened) */
export const markProposalViewed = async (id: string, companyId: string): Promise<Proposal> => {
  const res = await api.post(`/proposals/${id}/mark-viewed`, null, { params: { companyId } });
  return res.data;
};

/** POST /proposals/:id/accept - Accept proposal */
export const acceptProposal = async (id: string, feedback?: string): Promise<Proposal> => {
  const res = await api.post(`/proposals/${id}/accept`, { feedback });
  return res.data;
};

/** POST /proposals/:id/decline - Decline proposal */
export const declineProposal = async (id: string, reason: string, feedback?: string): Promise<Proposal> => {
  const res = await api.post(`/proposals/${id}/decline`, { reason, feedback });
  return res.data;
};

/** POST /proposals/:id/request-revision - Request revision */
export const requestProposalRevision = async (id: string, feedback: string): Promise<Proposal> => {
  const res = await api.post(`/proposals/${id}/request-revision`, { feedback });
  return res.data;
};

/** POST /proposals/:id/create-revision - Create new revision */
export const createProposalRevision = async (id: string): Promise<Proposal> => {
  const res = await api.post(`/proposals/${id}/create-revision`);
  return res.data;
};
