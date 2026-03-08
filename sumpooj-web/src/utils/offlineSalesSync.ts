import axios from "axios";
import { getOfflineSales, removeOfflineSale } from "./offlineSalesQueue";

export const syncOfflineSales = async () => {
  const sales = getOfflineSales();

  if (!sales.length) return;

  console.log("Syncing offline sales:", sales.length);

  for (const sale of sales) {
    try {
      await axios.post("/api/orders/manual-sale", sale);
      removeOfflineSale(sale.offlineId);
      console.log("Synced:", sale.offlineId);
    } catch (err) {
      console.error("Sync failed:", sale.offlineId);
      break;
    }
  }
};
