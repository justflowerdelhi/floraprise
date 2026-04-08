/**
 * Purchase Entry Form — API Re-exports
 *
 * Re-exports from the real API services.
 * Local mock data has been removed.
 */

export {
  searchPurchases,
  getPurchaseById,
  createPurchaseOrder,
  submitPurchaseOrder,
  approvePurchaseOrder,
  receivePurchaseOrder,
  cancelPurchaseOrder,
} from '../../../api/purchase.api';

export type {
  PurchaseSearchParams,
  PurchaseOrderItemRequest,
  CreatePurchaseOrderRequest,
  ReceivePurchaseOrderRequest,
  ReceiveItemRequest,
  SubmitPurchaseOrderResponse,
} from '../../../api/purchase.api';

export {
  searchSuppliers,
  getAllSuppliers,
  createSupplier,
  getSupplierById,
  updateSupplier,
  deactivateSupplier,
} from '../../../api/supplier.api';

export type {
  SupplierSearchParams,
  CreateSupplierRequest,
  UpdateSupplierRequest,
} from '../../../api/supplier.api';

export { searchProducts } from '../../../api/product.api';
