import type { VendorFlorist } from "./vendor.types"
import { getAllSuppliers, createSupplier, updateSupplier as apiUpdateSupplier, deactivateSupplier } from "../../api/supplier.api"

export async function getVendors(): Promise<VendorFlorist[]> {
  try {
    const data = await getAllSuppliers();
    const items = Array.isArray(data) ? data : data.items ?? [];
    return items.map((s: any) => ({
      id: s.id,
      name: s.name,
      city: s.city ?? '',
      state: s.state ?? '',
      phone: s.phone ?? '',
      email: s.email ?? '',
      defaultCommissionRate: s.commissionRate ?? 0,
      isActive: s.isActive ?? true,
    }));
  } catch {
    return [];
  }
}

export async function addVendor(vendor: VendorFlorist) {
  await createSupplier({
    name: vendor.name,
    email: vendor.email,
    phone: vendor.phone,
    address: vendor.address,
    paymentTermsDays: 0,
  });
}

export async function updateVendor(updated: VendorFlorist) {
  await apiUpdateSupplier(updated.id, {
    name: updated.name,
    email: updated.email,
    phone: updated.phone,
    address: updated.address,
  });
}

export async function deactivateVendor(id: string) {
  await deactivateSupplier(id);
}
