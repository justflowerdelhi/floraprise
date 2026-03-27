export type CustomerLookupCandidate = {
  name?: string | null;
  phone?: string | null;
};

export const normalizeCustomerName = (value: string): string =>
  value.trim().toLowerCase().replace(/\s+/g, ' ');

export const normalizeCustomerPhone = (value: string): string =>
  value.replace(/[^\d+]/g, '');

export const findCustomerByName = <T extends CustomerLookupCandidate>(
  customers: T[],
  value: string,
): T | null => {
  const normalizedInput = normalizeCustomerName(value);
  if (!normalizedInput) return null;

  const exactMatch = customers.find(
    (customer) => normalizeCustomerName(customer.name ?? '') === normalizedInput,
  );

  if (exactMatch) return exactMatch;

  const prefixMatches = customers.filter((customer) =>
    normalizeCustomerName(customer.name ?? '').startsWith(normalizedInput),
  );

  if (prefixMatches.length === 1) return prefixMatches[0];

  const containsMatches = customers.filter((customer) =>
    normalizeCustomerName(customer.name ?? '').includes(normalizedInput),
  );

  return containsMatches.length === 1 ? containsMatches[0] : null;
};

export const findCustomerByPhone = <T extends CustomerLookupCandidate>(
  customers: T[],
  value: string,
): T | null => {
  const normalizedInput = normalizeCustomerPhone(value);
  if (!normalizedInput) return null;

  return (
    customers.find(
      (customer) => normalizeCustomerPhone(customer.phone ?? '') === normalizedInput,
    ) ?? null
  );
};