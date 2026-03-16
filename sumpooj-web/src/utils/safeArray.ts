/**
 * safeArray — ensures API responses are always arrays.
 * Prevents ".filter is not a function" crashes when the API returns
 * an error object, HTML (Cloudflare 403), or undefined.
 *
 * Usage:
 *   const data = safeArray(res.data);
 *   const data = safeArray(res.data, 'items');  // unwrap { items: [...] }
 */
export function safeArray<T = any>(data: unknown, itemsKey?: string): T[] {
  if (data == null) return [];
  if (Array.isArray(data)) return data;
  if (typeof data === 'object' && itemsKey && Array.isArray((data as any)[itemsKey])) {
    return (data as any)[itemsKey];
  }
  if (typeof data === 'object' && Array.isArray((data as any).items)) {
    return (data as any).items;
  }
  return [];
}
