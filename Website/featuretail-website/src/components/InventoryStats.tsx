export default function InventoryStats({ data }: { data: any[] }) {
  const total = data.length;
  const low = data.filter(
    (i) => i.stock <= i.lowStockThreshold
  ).length;
  const units = data.reduce((sum, i) => sum + i.stock, 0);

  const value = data.reduce((sum, i) => {
    return sum + i.stock * (i.purchasePrice || 0);
  }, 0);

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">

      <div className="p-4 bg-blue-50 rounded border">
        <p className="text-sm">Total SKUs</p>
        <h2 className="text-xl font-bold">{total}</h2>
      </div>

      <div className="p-4 bg-red-50 rounded border">
        <p className="text-sm">Low Stock</p>
        <h2 className="text-xl font-bold">{low}</h2>
      </div>

      <div className="p-4 bg-gray-50 rounded border">
        <p className="text-sm">Total Units</p>
        <h2 className="text-xl font-bold">{units}</h2>
      </div>

      <div className="p-4 bg-green-50 rounded border">
        <p className="text-sm">Inventory Value</p>
        <h2 className="text-xl font-bold text-green-700">
          ₹ {value.toLocaleString()}
        </h2>
      </div>

    </div>
  );
}