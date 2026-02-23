import React, { useEffect, useState } from 'react';
import {
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  Divider,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,
} from '@mui/material';
import { Print as PrintIcon } from '@mui/icons-material';
import { getInvoice, type InvoiceResponse } from './phoneOrders.api';

// Print-friendly styles
const printStyles = `
@media print {
  body * {
    visibility: hidden;
  }
  .invoice-print-area, .invoice-print-area * {
    visibility: visible;
  }
  .invoice-print-area {
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    padding: 20px;
    background: white !important;
  }
  .no-print {
    display: none !important;
  }
  .MuiDialog-root {
    position: static !important;
  }
  .MuiDialog-paper {
    box-shadow: none !important;
    margin: 0 !important;
    max-width: 100% !important;
  }
  .MuiDialogActions-root {
    display: none !important;
  }
}
`;

interface InvoiceDialogProps {
  open: boolean;
  orderId: string;
  onClose: () => void;
}

const InvoiceDialog: React.FC<InvoiceDialogProps> = ({ open, orderId, onClose }) => {
  const [loading, setLoading] = useState(false);
  const [invoice, setInvoice] = useState<InvoiceResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open && orderId) {
      setLoading(true);
      setError(null);
      getInvoice(orderId)
        .then((data) => {
          setInvoice(data);
        })
        .catch((err) => {
          console.error('Failed to load invoice:', err);
          setError('Failed to load invoice');
        })
        .finally(() => {
          setLoading(false);
        });
    }
  }, [open, orderId]);

  const handleClose = () => {
    setInvoice(null);
    setError(null);
    onClose();
  };

  const handlePrint = () => {
    window.print();
  };

  const formatDate = (dateStr?: string) => {
    if (!dateStr) return '—';
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  };

  return (
    <>
      <style>{printStyles}</style>
      <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogContent sx={{ p: 0 }}>
          {loading && (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
              <CircularProgress />
            </Box>
          )}

          {error && (
            <Box sx={{ p: 3 }}>
              <Typography color="error">{error}</Typography>
            </Box>
          )}

          {!loading && !error && invoice && (
            <Box
              className="invoice-print-area"
              sx={{
                bgcolor: 'white',
                p: 4,
                minHeight: 500,
              }}
            >
              {/* ═══════════════════════════════════════════════════════════════
                  HEADER - Shop Name & Invoice Info
              ═══════════════════════════════════════════════════════════════ */}
              <Box sx={{ textAlign: 'center', mb: 3 }}>
                <Typography variant="h5" sx={{ fontWeight: 700, color: 'primary.main' }}>
                  Sumpooj Florist
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Fresh Flowers & Beautiful Arrangements
                </Typography>
              </Box>

              <Box
                sx={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'flex-start',
                  mb: 3,
                  pb: 2,
                  borderBottom: '2px solid',
                  borderColor: 'divider',
                }}
              >
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 700 }}>
                    INVOICE
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {invoice.invoiceNumber}
                  </Typography>
                </Box>
                <Box sx={{ textAlign: 'right' }}>
                  <Typography variant="body2" color="text.secondary">
                    Order #
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {invoice.orderNumber}
                  </Typography>
                </Box>
              </Box>

              {/* ═══════════════════════════════════════════════════════════════
                  CUSTOMER SECTION
              ═══════════════════════════════════════════════════════════════ */}
              <Box
                sx={{
                  bgcolor: 'grey.50',
                  borderRadius: 1,
                  p: 2,
                  mb: 3,
                }}
              >
                <Typography
                  variant="overline"
                  sx={{ fontWeight: 600, color: 'text.secondary', display: 'block', mb: 1 }}
                >
                  Customer Details
                </Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3 }}>
                  <Box sx={{ minWidth: 120 }}>
                    <Typography variant="caption" color="text.secondary">
                      Name
                    </Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {invoice.customerName}
                    </Typography>
                  </Box>
                  {invoice.phone && (
                    <Box sx={{ minWidth: 120 }}>
                      <Typography variant="caption" color="text.secondary">
                        Phone
                      </Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {invoice.phone}
                      </Typography>
                    </Box>
                  )}
                  <Box sx={{ minWidth: 120 }}>
                    <Typography variant="caption" color="text.secondary">
                      Delivery Date
                    </Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {formatDate(invoice.deliveryDate)}
                    </Typography>
                  </Box>
                  <Box sx={{ minWidth: 100 }}>
                    <Typography variant="caption" color="text.secondary">
                      Order Type
                    </Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {invoice.orderType}
                    </Typography>
                  </Box>
                </Box>
              </Box>

              {/* ═══════════════════════════════════════════════════════════════
                  ITEMS TABLE
              ═══════════════════════════════════════════════════════════════ */}
              <Table size="small" sx={{ mb: 3 }}>
                <TableHead>
                  <TableRow sx={{ bgcolor: 'grey.100' }}>
                    <TableCell sx={{ fontWeight: 600 }}>Description</TableCell>
                    <TableCell align="center" sx={{ fontWeight: 600, width: 60 }}>
                      Qty
                    </TableCell>
                    <TableCell align="right" sx={{ fontWeight: 600, width: 100 }}>
                      Unit Price
                    </TableCell>
                    <TableCell align="right" sx={{ fontWeight: 600, width: 100 }}>
                      Total
                    </TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {invoice.items.map((item, idx) => (
                    <TableRow key={idx}>
                      <TableCell>{item.description}</TableCell>
                      <TableCell align="center">{item.quantity}</TableCell>
                      <TableCell align="right">₹{item.unitPrice.toLocaleString()}</TableCell>
                      <TableCell align="right">₹{item.total.toLocaleString()}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>

              {/* ═══════════════════════════════════════════════════════════════
                  SUMMARY SECTION
              ═══════════════════════════════════════════════════════════════ */}
              <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
                <Box sx={{ width: 220 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.5 }}>
                    <Typography variant="body2" color="text.secondary">
                      Subtotal
                    </Typography>
                    <Typography variant="body2">₹{invoice.subtotal.toLocaleString()}</Typography>
                  </Box>

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.5 }}>
                    <Typography variant="body2" color="text.secondary">
                      Delivery Charge
                    </Typography>
                    <Typography variant="body2">
                      {invoice.deliveryCharge > 0
                        ? `₹${invoice.deliveryCharge.toLocaleString()}`
                        : '—'}
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.5 }}>
                    <Typography variant="body2" color="text.secondary">
                      Discount
                    </Typography>
                    <Typography variant="body2" color="success.main">
                      {invoice.discount > 0 ? `-₹${invoice.discount.toLocaleString()}` : '—'}
                    </Typography>
                  </Box>

                  <Divider sx={{ my: 1 }} />

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.5 }}>
                    <Typography variant="body1" sx={{ fontWeight: 700 }}>
                      Grand Total
                    </Typography>
                    <Typography variant="body1" sx={{ fontWeight: 700 }}>
                      ₹{invoice.total.toLocaleString()}
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.5 }}>
                    <Typography variant="body2" color="text.secondary">
                      Paid
                    </Typography>
                    <Typography variant="body2" sx={{ color: 'success.main', fontWeight: 600 }}>
                      ₹{invoice.paidAmount.toLocaleString()}
                    </Typography>
                  </Box>

                  <Box
                    sx={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      py: 0.5,
                      bgcolor: invoice.balance > 0 ? 'warning.lighter' : 'success.lighter',
                      px: 1,
                      borderRadius: 0.5,
                      mt: 0.5,
                    }}
                  >
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      Balance
                    </Typography>
                    <Typography
                      variant="body2"
                      sx={{
                        fontWeight: 700,
                        color: invoice.balance > 0 ? 'warning.dark' : 'success.dark',
                      }}
                    >
                      ₹{invoice.balance.toLocaleString()}
                    </Typography>
                  </Box>
                </Box>
              </Box>

              {/* ═══════════════════════════════════════════════════════════════
                  FOOTER
              ═══════════════════════════════════════════════════════════════ */}
              <Box
                sx={{
                  mt: 4,
                  pt: 2,
                  borderTop: '1px dashed',
                  borderColor: 'divider',
                  textAlign: 'center',
                }}
              >
                <Typography variant="body2" sx={{ fontStyle: 'italic', color: 'text.secondary' }}>
                  Thank you for your order!
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  For queries, contact us at support@sumpooj.com
                </Typography>
              </Box>
            </Box>
          )}
        </DialogContent>

        <DialogActions className="no-print" sx={{ px: 3, py: 2, borderTop: '1px solid', borderColor: 'divider' }}>
          <Button onClick={handleClose} color="inherit">
            Close
          </Button>
          {invoice && (
            <Button
              variant="contained"
              startIcon={<PrintIcon />}
              onClick={handlePrint}
            >
              Print
            </Button>
          )}
        </DialogActions>
      </Dialog>
    </>
  );
};

export default InvoiceDialog;
