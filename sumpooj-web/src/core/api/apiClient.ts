/**
 * apiClient.ts
 * Re-export the shared Axios client so all modules use the same
 * base URL, auth token flow, refresh handling, and location scoping.
 */

import api from '../../api/axios';

export const apiClient = api;
