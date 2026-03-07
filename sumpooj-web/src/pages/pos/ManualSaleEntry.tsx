import axios from "axios";
import React, { useState } from "react";
import {
  Box,
  Typography,
  Card,
  Grid,
  TextField,
  Button,
  MenuItem,
  Snackbar,
  Alert
} from "@mui/material";

import { postAccountingEvent } from '../../modules/accounting/accountingEvents';

const paymentMethods = ["Cash", "Card", "UPI"];

const ManualSaleEntry: React.FC = () => {

  const [form, setForm] = useState({
    orderDate: "",
    product: "",
    quantity: 1,
    price: "",
    paymentMethod: "Cash"
  });

  const [success, setSuccess] = useState(false);

  const handleChange = (field: string, value: any) => {
    setForm({
      ...form,
      [field]: value
    });
  };

  const handleSubmit = async () => {
    const orderPayload = {
      orderSource: "MANUAL",
      orderDate: form.orderDate,
      paymentMethod: form.paymentMethod,

      items: [
        {
          productName: form.product,
          quantity: Number(form.quantity),
          price: Number(form.price)
        }
      ]
    };

    try {

      const response = await axios.post(
        "/api/orders",
        orderPayload
      );

      console.log("Manual order created:", response.data);

      setSuccess(true);

      setForm({
        orderDate: "",
        product: "",
        quantity: 1,
        price: "",
        paymentMethod: "Cash"
      });

    } catch (error) {

      console.error("Manual sale failed:", error);

    }
  };

  return (
    <Box p={3}>
      <Typography variant="h5" fontWeight={700} mb={3}>
        Manual Sale Entry
      </Typography>
      <Card sx={{ p:3 }}>
        <Grid container spacing={2}>
          <Grid item xs={6}>
            <TextField
              fullWidth
              type="date"
              label="Sale Date"
              InputLabelProps={{ shrink: true }}
              value={form.orderDate}
              onChange={(e) => handleChange("orderDate", e.target.value)}
            />
          </Grid>
          <Grid item xs={6}>
            <TextField
              fullWidth
              label="Product Name"
              value={form.product}
              onChange={(e) => handleChange("product", e.target.value)}
            />
          </Grid>
          <Grid item xs={4}>
            <TextField
              fullWidth
              label="Quantity"
              type="number"
              value={form.quantity}
              onChange={(e) => handleChange("quantity", e.target.value)}
            />
          </Grid>
          <Grid item xs={4}>
            <TextField
              fullWidth
              label="Price"
              type="number"
              value={form.price}
              onChange={(e) => handleChange("price", e.target.value)}
            />
          </Grid>
          <Grid item xs={4}>
            <TextField
              select
              fullWidth
              label="Payment Method"
              value={form.paymentMethod}
              onChange={(e) => handleChange("paymentMethod", e.target.value)}
            >
              {paymentMethods.map((p) => (
                <MenuItem key={p} value={p}>
                  {p}
                </MenuItem>
              ))}
            </TextField>
          </Grid>
          <Grid item xs={12}>
            <Button
              variant="contained"
              fullWidth
              size="large"
              onClick={handleSubmit}
            >
              Save Manual Sale
            </Button>
          </Grid>
        </Grid>
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