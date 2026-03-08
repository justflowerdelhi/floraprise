import { apiClient } from "../../../core/api/apiClient";

export interface POSCatalogProduct {
  id: string;
  name: string;
  sku: string;
  category: string;
  sellingPrice: number;
  availableStock: number;
  barcode?: string;
  imageUrl?: string;
}

export interface POSCatalogResponse {
  products: POSCatalogProduct[];
  finishedGoods: POSCatalogProduct[];
}

export const getPOSCatalog = async (): Promise<POSCatalogResponse> => {
  const res = await apiClient.get("/pos/catalog");
  return res.data;
};
