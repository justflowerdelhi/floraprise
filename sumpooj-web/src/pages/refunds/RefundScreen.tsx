/**
 * RefundScreen.tsx — Full Refund Processing Screen
 */

import React, { useState, useEffect, useMemo } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  Box,
  Typography,
  Paper,
  Button,
  TextField,
  Divider,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Checkbox,
  CircularProgress,
} from "@mui/material";

import { MoneyOff as RefundIcon } from "@mui/icons-material";

import { formatCurrency } from "../../core/i18n";
import { getOrderById, updateOrderStatus } from "../../api/order.api";
import { createRefund } from "../../api/refund.api";
import { useToast } from "../../hooks/useToast";

const fmtCurrency = (v: number) => formatCurrency(v);

interface RefundItem {
  lineItemId: string;
  productId: string;
  productName: string;
  sku?: string;
  orderedQty: number;
  quantity: number;
  unitPrice: number;
}

const RefundScreen: React.FC = () => {
  const navigate = useNavigate();
  const { orderId } = useParams<{ orderId: string }>();
  const toast = useToast();

  const [order, setOrder] = useState<any>(null);
  const [items, setItems] = useState<RefundItem[]>([]);
  const [reason, setReason] = useState("");

  /* ---------------- Load Order ---------------- */

  useEffect(() => {
    if (!orderId) return;

    getOrderById(orderId)
      .then((data) => {
        setOrder(data);

        const mapped: RefundItem[] =
          data.items?.map((i: any) => ({
            lineItemId: i.id,
            productId: i.productId,
            productName: i.productName,
            sku: i.sku,
            orderedQty: i.quantity,
            quantity: 0,
            unitPrice: i.unitPrice,
          })) ?? [];

        setItems(mapped);
      })
      .catch(() => toast.error("Failed to load order"));
  }, [orderId]);

  /* ---------------- Calculations ---------------- */

  const orderTotal =
    order?.totals?.grandTotal ??
    order?.grandTotal ??
    order?.total ??
    0;

  const totalRefund = useMemo(
    () =>
      items.reduce(
        (sum, item) => sum + item.quantity * item.unitPrice,
        0
      ),
    [items]
  );

  const hasSelection = items.some((i) => i.quantity > 0);

  const isValid =
    hasSelection &&
    reason.trim().length >= 3 &&
    totalRefund > 0;

  /* ---------------- Handlers ---------------- */

  const changeQty = (id: string, qty: number) => {
    setItems((prev) =>
      prev.map((item) =>
        item.lineItemId === id
          ? {
              ...item,
              quantity: Math.max(
                0,
                Math.min(qty, item.orderedQty)
              ),
            }
          : item
      )
    );
  };

  const handleRefund = async () => {
    if (!order || !isValid) return;

    const selected = items.filter((i) => i.quantity > 0);

    try {
      await createRefund({
        orderId: order.id,
        method: "ORIGINAL",
        reason,
        items: selected.map((i) => ({
          productId: i.productId,
          productName: i.productName,
          quantity: i.quantity,
          unitPrice: i.unitPrice,
          restock: false,
        })),
      });

      await updateOrderStatus(order.id, {
        status: "REFUNDED",
      });

      toast.success("Refund processed");

      navigate("/order-list");
    } catch {
      toast.error("Refund failed");
    }
  };

  /* ---------------- Guards ---------------- */

  if (!order) {
    return (
      <Box sx={{ p: 4, textAlign: "center" }}>
        <CircularProgress />
      </Box>
    );
  }

  /* ---------------- UI ---------------- */

  return (
    <Box sx={{ p: 3 }}>
      <Typography
        variant="h5"
        sx={{ mb: 2, fontWeight: 700 }}
      >
        <RefundIcon sx={{ mr: 1 }} />
        Process Refund
      </Typography>

      <Box sx={{ display: "flex", gap: 3 }}>
        {/* LEFT */}

        <Paper sx={{ flex: 2, p: 2 }}>
          <Typography sx={{ fontWeight: 700, mb: 2 }}>
            Select Items to Refund
          </Typography>

          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell />
                <TableCell>Product</TableCell>
                <TableCell align="center">
                  Ordered
                </TableCell>
                <TableCell align="center">
                  Refund Qty
                </TableCell>
                <TableCell align="right">
                  Unit Price
                </TableCell>
                <TableCell align="right">
                  Refund Amt
                </TableCell>
              </TableRow>
            </TableHead>

            <TableBody>
              {items.map((item) => {
                const selected = item.quantity > 0;

                return (
                  <TableRow key={item.lineItemId}>
                    <TableCell>
                      <Checkbox
                        checked={selected}
                        onChange={(e) =>
                          changeQty(
                            item.lineItemId,
                            e.target.checked
                              ? item.orderedQty
                              : 0
                          )
                        }
                      />
                    </TableCell>

                    <TableCell>
                      {item.productName}
                    </TableCell>

                    <TableCell align="center">
                      {item.orderedQty}
                    </TableCell>

                    <TableCell align="center">
                      <TextField
                        type="number"
                        size="small"
                        value={item.quantity}
                        onChange={(e) =>
                          changeQty(
                            item.lineItemId,
                            Number(
                              e.target.value || 0
                            )
                          )
                        }
                        sx={{ width: 70 }}
                      />
                    </TableCell>

                    <TableCell align="right">
                      {fmtCurrency(item.unitPrice)}
                    </TableCell>

                    <TableCell align="right">
                      {selected
                        ? fmtCurrency(
                            item.quantity *
                              item.unitPrice
                          )
                        : "—"}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </Paper>

        {/* RIGHT */}

        <Paper sx={{ flex: 1, p: 3 }}>
          <Typography
            sx={{ fontWeight: 700, mb: 2 }}
          >
            Refund Summary
          </Typography>

          <Typography>
            Order Total: {fmtCurrency(orderTotal)}
          </Typography>

          <Typography>
            This Refund: {fmtCurrency(totalRefund)}
          </Typography>

          <Divider sx={{ my: 2 }} />

          <Typography>Reason *</Typography>

          <TextField
            multiline
            rows={3}
            fullWidth
            value={reason}
            onChange={(e) =>
              setReason(e.target.value)
            }
            sx={{ mb: 2 }}
          />

          <Button
            fullWidth
            variant="contained"
            color="warning"
            disabled={!isValid}
            onClick={handleRefund}
          >
            Process Refund — {fmtCurrency(totalRefund)}
          </Button>
        </Paper>
      </Box>
    </Box>
  );
};

export default RefundScreen;