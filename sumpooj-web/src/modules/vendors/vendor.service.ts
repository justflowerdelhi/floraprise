import type { VendorFlorist } from "./vendor.types"

let vendors: VendorFlorist[] = [
  {
    id: "1",
    name: "Rosewood Florals",
    city: "Pune",
    state: "MH",
    phone: "020-4000-1111",
    email: "orders@rosewoodflorals.com",
    commission: 18,
    status: "ACTIVE"
  },
  {
    id: "2",
    name: "Urban Petals",
    city: "Mumbai",
    state: "MH",
    phone: "022-4555-2222",
    email: "hello@urbanpetals.in",
    commission: 20,
    status: "ACTIVE"
  }
]

export function getVendors() {
  return vendors
}

export function addVendor(vendor: VendorFlorist) {
  vendors.push(vendor)
}

export function updateVendor(updated: VendorFlorist) {
  vendors = vendors.map(v =>
    v.id === updated.id ? updated : v
  )
}

export function deactivateVendor(id: string) {
  vendors = vendors.map(v =>
    v.id === id ? { ...v, status: "INACTIVE" } : v
  )
}
