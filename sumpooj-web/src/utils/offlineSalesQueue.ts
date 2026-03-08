const STORAGE_KEY = "floraprise_offline_sales";

export const getOfflineSales = () => {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return [];
  return JSON.parse(raw);
};

export const addOfflineSale = (sale: any) => {
  const sales = getOfflineSales();

  sales.push({
    ...sale,
    offlineId: "offline_" + Date.now(),
    createdAt: new Date().toISOString(),
  });

  localStorage.setItem(STORAGE_KEY, JSON.stringify(sales));
};

export const removeOfflineSale = (offlineId: string) => {
  const sales = getOfflineSales().filter((s: any) => s.offlineId !== offlineId);
  localStorage.setItem(STORAGE_KEY, JSON.stringify(sales));
};
