import React, { useEffect, useState } from "react";
import { Button, Card, Table, DatePicker, Select } from "antd";
import axios from "axios";

interface RevenueBreakdown {
  Account: string;
  Amount: number;
}
interface ExpenseBreakdown {
  Account: string;
  Amount: number;
}
interface ProfitLossData {
  RevenueBreakdown: RevenueBreakdown[];
  COGSTotal: number;
  ExpenseBreakdown: ExpenseBreakdown[];
  GrossProfit: number;
  NetProfit: number;
}

const ProfitLossPage: React.FC = () => {
  const [data, setData] = useState<ProfitLossData | null>(null);
  const [startDate, setStartDate] = useState<string>("");
  const [endDate, setEndDate] = useState<string>("");
  const [locationId, setLocationId] = useState<string>("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (startDate && endDate) fetchData();
    // eslint-disable-next-line
  }, [startDate, endDate, locationId]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const params: any = { startDate, endDate };
      if (locationId) params.locationId = locationId;
      const res = await axios.get("/accounting/profit-loss", { params });
      setData(res.data);
    } catch (e) {
      setData(null);
    }
    setLoading(false);
  };

  const exportCSV = () => {
    // Simple CSV export
    if (!data) return;
    let csv = "Section,Account,Amount\n";
    data.RevenueBreakdown.forEach(r => csv += `Revenue,${r.Account},${r.Amount}\n`);
    csv += `COGS,,${data.COGSTotal}\n`;
    data.ExpenseBreakdown.forEach(e => csv += `Expense,${e.Account},${e.Amount}\n`);
    csv += `Gross Profit,,${data.GrossProfit}\n`;
    csv += `Net Profit,,${data.NetProfit}\n`;
    const blob = new Blob([csv], { type: "text/csv" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "profit_loss_report.csv";
    a.click();
    window.URL.revokeObjectURL(url);
  };

  // Placeholder for PDF export
  const exportPDF = () => {
    window.print();
  };

  return (
    <div>
      <h2>Profit & Loss Report</h2>
      <div style={{ display: "flex", gap: 16, marginBottom: 16 }}>
        <DatePicker
          placeholder="Start Date"
          onChange={(_, dateStr) => setStartDate(dateStr)}
        />
        <DatePicker
          placeholder="End Date"
          onChange={(_, dateStr) => setEndDate(dateStr)}
        />
        <Select
          placeholder="Location"
          style={{ width: 200 }}
          allowClear
          onChange={v => setLocationId(v || "")}
          options={[]}
        />
        <Button onClick={exportCSV}>Export CSV</Button>
        <Button onClick={exportPDF}>Export PDF</Button>
      </div>
      {data && (
        <div style={{ display: "flex", gap: 16, marginBottom: 16 }}>
          <Card title="Revenue" style={{ flex: 1 }}>{data.RevenueBreakdown.reduce((sum, r) => sum + r.Amount, 0)}</Card>
          <Card title="COGS" style={{ flex: 1 }}>{data.COGSTotal}</Card>
          <Card title="Gross Profit" style={{ flex: 1 }}>{data.GrossProfit}</Card>
          <Card title="Expenses" style={{ flex: 1 }}>{data.ExpenseBreakdown.reduce((sum, e) => sum + e.Amount, 0)}</Card>
          <Card title="Net Profit" style={{ flex: 1 }}>{data.NetProfit}</Card>
        </div>
      )}
      <Table
        loading={loading}
        dataSource={data ? [
          ...data.RevenueBreakdown.map(r => ({ section: "Revenue", account: r.Account, amount: r.Amount })),
          { section: "COGS", account: "", amount: data.COGSTotal },
          ...data.ExpenseBreakdown.map(e => ({ section: "Expense", account: e.Account, amount: e.Amount })),
          { section: "Gross Profit", account: "", amount: data.GrossProfit },
          { section: "Net Profit", account: "", amount: data.NetProfit }
        ] : []}
        columns={[
          { title: "Section", dataIndex: "section" },
          { title: "Account", dataIndex: "account" },
          { title: "Amount", dataIndex: "amount" }
        ]}
        pagination={false}
        rowKey={(_, idx) => idx.toString()}
      />
    </div>
  );
};

export default ProfitLossPage;
