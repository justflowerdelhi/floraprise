/**
 * useApiCall.ts — Reusable hook for API calls with loading state,
 * error handling, and toast notifications.
 *
 * Usage:
 *   const { execute, loading } = useApiCall();
 *   const data = await execute(() => fetchCustomers(), {
 *     successMessage: 'Customers loaded',
 *     errorMessage: 'Failed to load customers',
 *   });
 */
import { useState, useCallback } from 'react';
import type { AxiosError } from 'axios';
import { useToast } from './useToast';

interface ApiCallOptions {
  /** Toast message on success (omit to skip success toast) */
  successMessage?: string;
  /** Custom error message prefix (defaults to 'Something went wrong') */
  errorMessage?: string;
  /** Show error toast (defaults to true) */
  showErrorToast?: boolean;
}

interface ApiCallReturn {
  loading: boolean;
  execute: <T>(fn: () => Promise<T>, options?: ApiCallOptions) => Promise<T | undefined>;
}

/**
 * Extracts a human-readable error message from an AxiosError or generic Error.
 */
function extractErrorMessage(err: unknown): string {
  if (typeof err === 'object' && err !== null && 'response' in err) {
    const axiosErr = err as AxiosError<{ message?: string; title?: string; errors?: Record<string, string[]> }>;
    const data = axiosErr.response?.data;

    // Validation errors (ASP.NET style)
    if (data?.errors) {
      const messages = Object.values(data.errors).flat();
      if (messages.length > 0) return messages.join('. ');
    }

    // Standard message field
    if (data?.message) return data.message;
    if (data?.title) return data.title;

    // HTTP status fallback
    const status = axiosErr.response?.status;
    if (status === 400) return 'Invalid request. Please check your input.';
    if (status === 401) return 'Session expired. Please log in again.';
    if (status === 403) return 'You do not have permission for this action.';
    if (status === 404) return 'The requested resource was not found.';
    if (status === 409) return 'A conflict occurred. The resource may have been modified.';
    if (status === 422) return 'Validation failed. Please check your input.';
    if (status === 500) return 'Server error. Please try again later.';
  }

  if (err instanceof Error) return err.message;
  return 'An unexpected error occurred.';
}

export function useApiCall(): ApiCallReturn {
  const [loading, setLoading] = useState(false);
  const toast = useToast();

  const execute = useCallback(
    async <T>(fn: () => Promise<T>, options?: ApiCallOptions): Promise<T | undefined> => {
      const {
        successMessage,
        errorMessage = 'Something went wrong',
        showErrorToast = true,
      } = options ?? {};

      setLoading(true);
      try {
        const result = await fn();
        if (successMessage) toast.success(successMessage);
        return result;
      } catch (err: unknown) {
        const message = extractErrorMessage(err);
        if (showErrorToast) {
          toast.error(`${errorMessage}: ${message}`);
        }
        return undefined;
      } finally {
        setLoading(false);
      }
    },
    [toast],
  );

  return { loading, execute };
}
