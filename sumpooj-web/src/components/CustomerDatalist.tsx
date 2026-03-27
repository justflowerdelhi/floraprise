import React from 'react';
import {
  normalizeCustomerName,
  normalizeCustomerPhone,
  type CustomerLookupCandidate,
} from '../utils/customerLookup';

type CustomerDatalistProps<T extends CustomerLookupCandidate & { id?: string | number; email?: string | null }> = {
  id: string;
  customers: T[];
  field: 'name' | 'phone';
};

export function CustomerDatalist<T extends CustomerLookupCandidate & { id?: string | number; email?: string | null }>({
  id,
  customers,
  field,
}: CustomerDatalistProps<T>) {
  const seen = new Set<string>();

  const options = customers.filter((customer) => {
    const rawValue = field === 'name' ? (customer.name ?? '') : (customer.phone ?? '');
    const normalizedValue = field === 'name'
      ? normalizeCustomerName(rawValue)
      : normalizeCustomerPhone(rawValue);

    if (!normalizedValue || seen.has(normalizedValue)) {
      return false;
    }

    seen.add(normalizedValue);
    return true;
  });

  return (
    <datalist id={id}>
      {options.map((customer, index) => {
        const value = field === 'name' ? (customer.name ?? '') : (customer.phone ?? '');
        const label = field === 'name'
          ? (customer.phone || customer.email || '')
          : (customer.name || customer.email || '');
        const keyBase = customer.id ?? `${field}-${index}`;

        return <option key={String(keyBase)} value={value} label={label} />;
      })}
    </datalist>
  );
}