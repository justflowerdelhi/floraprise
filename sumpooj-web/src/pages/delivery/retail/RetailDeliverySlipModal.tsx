/**
 * RetailDeliverySlipModal.tsx — Printable Thermal Packing Slip & Greeting Card
 */

import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Divider,
  Chip,
  IconButton,
  ToggleButtonGroup,
  ToggleButton,
  useTheme,
} from '@mui/material';
import {
  Print as PrintIcon,
  Close as CloseIcon,
  CardGiftcard as GiftIcon,
  ReceiptLong as ReceiptIcon,
} from '@mui/icons-material';
import type { RetailDeliveryItem } from './retailDelivery.types';

interface RetailDeliverySlipModalProps {
  open: boolean;
  onClose: () => void;
  delivery: RetailDeliveryItem | null;
}

export const RetailDeliverySlipModal: React.FC<RetailDeliverySlipModalProps> = ({
  open,
  onClose,
  delivery,
}) => {
  const theme = useTheme();
  const [paperWidth, setPaperWidth] = useState<'80mm' | '58mm'>('80mm');

  if (!delivery) return null;

  const handlePrint = () => {
    const printContent = document.getElementById('retail-delivery-slip-printable');
    if (!printContent) return;

    const printWindow = window.open('', '_blank', 'width=600,height=800');
    if (!printWindow) {
      window.print();
      return;
    }

    const widthPx = paperWidth === '80mm' ? '302px' : '220px';

    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Delivery Slip - ${delivery.orderNumber}</title>
          <style>
            @page {
              size: auto;
              margin: 4mm;
            }
            body {
              font-family: 'Courier New', Courier, monospace, sans-serif;
              width: ${widthPx};
              margin: 0 auto;
              padding: 6px;
              color: #000;
              font-size: ${paperWidth === '80mm' ? '12px' : '10px'};
              line-height: 1.35;
            }
            .center { text-align: center; }
            .bold { font-weight: bold; }
            .divider { border-top: 1px dashed #000; margin: 8px 0; }
            .double-divider { border-top: 2px solid #000; margin: 8px 0; }
            .card-box {
              border: 1.5px solid #000;
              padding: 8px;
              margin: 8px 0;
              background-color: #fafafa;
            }
            .row { display: flex; justify-content: space-between; }
            .items-table { width: 100%; border-collapse: collapse; margin-top: 4px; }
            .items-table th { text-align: left; border-bottom: 1px dashed #000; padding: 2px 0; }
            .items-table td { padding: 3px 0; }
            .signature-area { margin-top: 20px; border-top: 1px dotted #000; padding-top: 4px; text-align: center; }
          </style>
        </head>
        <body>
          ${printContent.innerHTML}
          <script>
            window.onload = function() {
              window.print();
              setTimeout(function() { window.close(); }, 500);
            };
          </script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  const isExpress = delivery.deliveryPriority.toLowerCase() === 'express';
  const isPaid = delivery.paymentStatus.toLowerCase() === 'paid';

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', pb: 1 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <ReceiptIcon color="primary" />
          <Typography variant="h6" sx={{ fontWeight: 700 }}>
            Delivery Slip & Gift Card
          </Typography>
        </Box>
        <IconButton size="small" onClick={onClose}>
          <CloseIcon fontSize="small" />
        </IconButton>
      </DialogTitle>

      <DialogContent dividers sx={{ bgcolor: '#f5f5f5', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        {/* Width format selector */}
        <Box sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary' }}>
            Paper Format:
          </Typography>
          <ToggleButtonGroup
            size="small"
            value={paperWidth}
            exclusive
            onChange={(_, val) => {
              if (val) setPaperWidth(val);
            }}
          >
            <ToggleButton value="80mm">80mm (Standard)</ToggleButton>
            <ToggleButton value="58mm">58mm (Narrow)</ToggleButton>
          </ToggleButtonGroup>
        </Box>

        {/* Printable Slip Container */}
        <Box
          id="retail-delivery-slip-printable"
          sx={{
            width: paperWidth === '80mm' ? 302 : 220,
            bgcolor: '#ffffff',
            color: '#000000',
            p: 2,
            boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
            fontFamily: '"Courier New", Courier, monospace',
            fontSize: paperWidth === '80mm' ? '12px' : '10px',
            lineHeight: 1.35,
          }}
        >
          {/* Header */}
          <Box sx={{ textAlign: 'center', mb: 1 }}>
            <Typography sx={{ fontWeight: 'bold', fontSize: '15px', letterSpacing: 1 }}>
              FLORAPRISE
            </Typography>
            <Typography sx={{ fontSize: '11px', color: '#555' }}>
              Fresh Floral Atelier & Delivery
            </Typography>
            <Typography sx={{ fontWeight: 'bold', fontSize: '13px', mt: 0.5 }}>
              DISPATCH PACKING SLIP
            </Typography>
          </Box>

          <Box sx={{ borderTop: '1px dashed #000', my: 1 }} />

          {/* Order Info */}
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <span>Order #:</span>
            <span style={{ fontWeight: 'bold' }}>{delivery.orderNumber}</span>
          </Box>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <span>Date:</span>
            <span>{new Date(delivery.deliveryDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}</span>
          </Box>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <span>Slot:</span>
            <span style={{ fontWeight: 'bold' }}>{delivery.timeSlot}</span>
          </Box>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <span>Priority:</span>
            <span style={{ fontWeight: isExpress ? 'bold' : 'normal' }}>
              {delivery.deliveryPriority.toUpperCase()}
            </span>
          </Box>
          {delivery.deliveryPersonName && (
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <span>Driver:</span>
              <span>{delivery.deliveryPersonName}</span>
            </Box>
          )}

          <Box sx={{ borderTop: '1px dashed #000', my: 1 }} />

          {/* Recipient Details */}
          <Box sx={{ mb: 1 }}>
            <Box sx={{ fontWeight: 'bold', mb: 0.3 }}>DELIVER TO:</Box>
            <Box sx={{ fontSize: '13px', fontWeight: 'bold' }}>{delivery.recipientName}</Box>
            {delivery.recipientPhone && <Box>Phone: {delivery.recipientPhone}</Box>}
            <Box sx={{ mt: 0.5 }}>{delivery.address}</Box>
            {delivery.postalCode && <Box>Pincode: {delivery.postalCode}</Box>}
          </Box>

          {/* Sender / Customer Details */}
          <Box sx={{ mb: 1, fontSize: '11px', color: '#333' }}>
            <span>Ordered by: </span>
            <span style={{ fontWeight: 'bold' }}>{delivery.customerName}</span>
            {delivery.phone && <span> ({delivery.phone})</span>}
          </Box>

          {/* Greeting Card Message */}
          {delivery.cardMessage && (
            <Box
              sx={{
                border: '1.5px solid #000',
                p: 1,
                my: 1,
                bgcolor: '#fafafa',
                borderRadius: '4px',
              }}
            >
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, fontWeight: 'bold', mb: 0.5 }}>
                <GiftIcon sx={{ fontSize: 14 }} />
                <span>GREETING CARD MESSAGE:</span>
              </Box>
              <Typography
                sx={{
                  fontStyle: 'italic',
                  fontSize: paperWidth === '80mm' ? '12px' : '10px',
                  whiteFontWeight: 500,
                  whiteSpace: 'pre-wrap',
                }}
              >
                "{delivery.cardMessage}"
              </Typography>
            </Box>
          )}

          <Box sx={{ borderTop: '1px dashed #000', my: 1 }} />

          {/* Items Breakdown */}
          <Box sx={{ mb: 1 }}>
            <Box sx={{ fontWeight: 'bold', mb: 0.5 }}>ITEMS TO DELIVER ({delivery.itemCount}):</Box>
            <Typography sx={{ fontSize: paperWidth === '80mm' ? '11px' : '9.5px', lineHeight: 1.4 }}>
              {delivery.itemsSummary || 'Floral Arrangements'}
            </Typography>
          </Box>

          <Box sx={{ borderTop: '1px dashed #000', my: 1 }} />

          {/* Payment & Collection */}
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5, fontWeight: 'bold' }}>
            <span>TOTAL:</span>
            <span>₹{delivery.totalAmount.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
          </Box>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <span>PAYMENT:</span>
            <span style={{ fontWeight: 'bold', color: isPaid ? '#2e7d32' : '#d32f2f' }}>
              {isPaid ? 'PAID IN FULL' : `COLLECT COD ₹${delivery.totalAmount.toFixed(2)}`}
            </span>
          </Box>

          <Box sx={{ borderTop: '1px dotted #000', mt: 3, pt: 0.5, textAlign: 'center', fontSize: '10px' }}>
            <span>Recipient Signature / Date</span>
          </Box>
          <Box sx={{ textAlign: 'center', mt: 1, fontSize: '9px', color: '#666' }}>
            Thank you for choosing Floraprise!
          </Box>
        </Box>
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} color="inherit">
          Close
        </Button>
        <Button
          variant="contained"
          startIcon={<PrintIcon />}
          onClick={handlePrint}
          sx={{ fontWeight: 700 }}
        >
          Print Slip
        </Button>
      </DialogActions>
    </Dialog>
  );
};
