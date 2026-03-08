import type { Product } from "../../orders/OrderTypes";

let catalogCache: Product[] = [];

export const setPOSCatalogCache = (products: Product[]) => {
  catalogCache = products;
};

export const getPOSCatalogCache = (): Product[] => {
  return catalogCache;
};

export const clearPOSCatalogCache = () => {
  catalogCache = [];
};