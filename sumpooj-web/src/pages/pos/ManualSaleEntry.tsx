import api from "../../api/axios";
import React, { useState } from "react";
import {
  Box,
  Paper,
  Card,
  Grid,
  Typography,
  Button,
  TextField,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody,
  Select,
  MenuItem,
  Snackbar,
  Alert
} from "@mui/material";

import Autocomplete from "@mui/material/Autocomplete";

import { postAccountingEvent } from '../../modules/accounting/accountingEvents';
  import { formatCurrency } from '../../core/i18n';
import { MOCK_PRODUCTS } from "../../modules/orders/mock/manualSaleMock";
import { addOfflineSale } from "../../utils/offlineSalesQueue";

const paymentMethods = ["Cash", "Card", "UPI"];

type ManualSaleItem = {
  productId: string;
  name: string;
  qty: number;
  price: number;
};

const ManualSaleEntry: React.FC = () => {
  const [success, setSuccess] = useState(false);
  const [items, setItems] = useState<ManualSaleItem[]>([]);
  const [paymentMethod, setPaymentMethod] = useState("CASH");
  const [saleDate, setSaleDate] = useState("");
  const [reason, setReason] = useState("");

  const addProduct = (product: any) => {
    if (!product) return;
    const existing = items.find(i => i.productId === product.id);
    if (existing) {
      setItems(
        items.map(i =>
          i.productId === product.id
            ? { ...i, qty: i.qty + 1 }
            : i
        )
      );
    } else {
      setItems([
        ...items,
        {
          productId: product.id,
          name: product.name,
          qty: 1,
          price: product.price
        }
      ]);
    }
  };

  const updateQty = (productId: string, qty: number) => {
    setItems(
      items.map(i =>
        i.productId === productId
          ? { ...i, qty }
          : i
      )
    );
  };

  const removeItem = (productId: string) => {
    setItems(items.filter(i => i.productId !== productId));
  };

  const total = items.reduce(
    (sum, i) => sum + (i.qty * i.price),
    0
  );

  const saveManualSale = async () => {
    if (items.length === 0) {
      alert("Add at least one product");
      return;
    }

    const payload = {
      orderSource: "MANUAL",
      saleDate,
      paymentMethod,
      items,
      total
    };

    try {
      await api.post("/orders/manual-sale", payload);
      alert("Sale saved successfully");
    } catch (error) {
      console.warn("Offline mode — saving locally");
      addOfflineSale(payload);
      alert("Internet unavailable. Sale saved offline and will sync automatically.");
    }

    setItems([]);
  };

  return (
    <Box p={3}>
      <Typography variant="h5" fontWeight={700} mb={3}>
        Manual Sale Entry
      </Typography>
      <Card sx={{ p:3 }}>
        {/* Reason */}
        <Select
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          displayEmpty
          sx={{ mt: 2, mb: 2 }}
        >
          <MenuItem value="" disabled>Select Reason</MenuItem>
          <MenuItem value="Power Failure">Power Failure</MenuItem>
          <MenuItem value="Offline Sale">Offline Sale</MenuItem>
          <MenuItem value="Owner Sale">Owner Sale</MenuItem>
          <MenuItem value="Adjustment">Adjustment</MenuItem>
        </Select>

        {/* Payment */}
        <Select
          value={paymentMethod}
          onChange={(e) => setPaymentMethod(e.target.value)}
          sx={{ mt: 2, mb: 2 }}
        >
          <MenuItem value="CASH">Cash</MenuItem>
          <MenuItem value="CARD">Card</MenuItem>
          <MenuItem value="UPI">UPI</MenuItem>
        </Select>

        {/* Product Search */}
        <Autocomplete
          options={MOCK_PRODUCTS}
          getOptionLabel={(option) => option.name}
          onChange={(e, value) => addProduct(value)}
          renderInput={(params) =>
            <TextField {...params} label="Search Product" />
          }
        />

        {/* Cart */}
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Product</TableCell>
              <TableCell>Qty</TableCell>
              <TableCell>Price</TableCell>
              <TableCell>Total</TableCell>
              <TableCell></TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {items.length === 0 && (
              <TableRow>
                <TableCell colSpan={5} align="center">
                  No products added
                </TableCell>
              </TableRow>
            )}
            {items.map(item => (
              <TableRow key={item.productId}>
                <TableCell>{item.name}</TableCell>
                <TableCell>
                  <TextField
                    type="number"
                    size="small"
                    value={item.qty}
                    onChange={(e) =>
                      updateQty(item.productId, Number(e.target.value))
                    }
                  />
                </TableCell>
                <TableCell>{item.price}</TableCell>
                <TableCell>{item.qty * item.price}</TableCell>
                <TableCell>
                  <Button
                    color="error"
                    onClick={() => removeItem(item.productId)}
                  >
                    Remove
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        {/* Total */}
        <Typography variant="h6" sx={{ mt:2 }}>
          Total: {formatCurrency(total)}
        </Typography>

        {/* Save */}
        <Button
          variant="contained"
          onClick={saveManualSale}
        >
          Save Manual Sale
        </Button>
      </Card>
      <Snackbar
        open={success}
        autoHideDuration={3000}
        onClose={() => setSuccess(false)}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        <Alert onClose={() => setSuccess(false)} severity="success" sx={{ width: '100%' }}>
          Manual sale saved successfully!
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default ManualSaleEntry;