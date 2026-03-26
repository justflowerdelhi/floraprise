import { useState } from 'react';
import { getDailyInventoryReport } from '../../api/inventory.api';
import type { DailyInventoryReportRow } from '../../api/inventory.api';

export default function DailyInventoryReportPage() {
  const today = new Date().toISOString().split('T')[0];
  const [date, setDate] = useState(today);
  const [rows, setRows] = useState<DailyInventoryReportRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searched, setSearched] = useState(false);

  const load = async () => {
    setLoading(true);
    setError(null);
    setSearched(true);
    try {
      const data = await getDailyInventoryReport(date);
      setRows(data);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? err?.message ?? 'Failed to load report.');
      setRows([]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Daily Inventory Report</h1>

      <div className="flex gap-3 mb-6 items-end">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Date</label>
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="border border-gray-300 rounded px-3 py-2 text-sm"
          />
        </div>
        <button
          onClick={load}
          disabled={loading}
          className="bg-blue-600 text-white px-4 py-2 rounded text-sm hover:bg-blue-700 disabled:opacity-50"
        >
          {loading ? 'Loading...' : 'Load Report'}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-300 text-red-700 rounded px-4 py-3 mb-4 text-sm">
          {error}
        </div>
      )}

      {searched && !loading && !error && rows.length === 0 && (
        <div className="bg-yellow-50 border border-yellow-300 text-yellow-700 rounded px-4 py-3 mb-4 text-sm">
          No inventory movements found for {date}.
        </div>
      )}

      {rows.length > 0 && (
        <div className="overflow-x-auto">
          <table className="min-w-full border border-gray-200 text-sm">
            <thead className="bg-gray-100">
              <tr>
                <th className="text-left px-4 py-2 border-b">Product</th>
                <th className="text-right px-4 py-2 border-b">Opening</th>
                <th className="text-right px-4 py-2 border-b">Purchased</th>
                <th className="text-right px-4 py-2 border-b">Sold</th>
                <th className="text-right px-4 py-2 border-b">Adjustments</th>
                <th className="text-right px-4 py-2 border-b">Closing</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.productId} className="hover:bg-gray-50">
                  <td className="px-4 py-2 border-b font-medium">{row.productName}</td>
                  <td className="px-4 py-2 border-b text-right">{row.openingStock}</td>
                  <td className="px-4 py-2 border-b text-right text-green-700">
                    {row.purchased > 0 ? `+${row.purchased}` : row.purchased}
                  </td>
                  <td className="px-4 py-2 border-b text-right text-red-600">
                    {row.sold > 0 ? `-${row.sold}` : row.sold}
                  </td>
                  <td className={`px-4 py-2 border-b text-right ${row.adjustments < 0 ? 'text-orange-600' : 'text-gray-700'}`}>
                    {row.adjustments > 0 ? `+${row.adjustments}` : row.adjustments}
                  </td>
                  <td className="px-4 py-2 border-b text-right font-semibold">{row.closingStock}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
