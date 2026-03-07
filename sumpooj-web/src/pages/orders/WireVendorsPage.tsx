import React from "react";
import Button from "@mui/material/Button";
import IconButton from "@mui/material/IconButton";

import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";

import type { VendorFlorist } from "../../modules/vendors/vendor.types";

import VendorForm from "../../modules/vendors/components/VendorForm";

import {
  getVendors,
  addVendor,
  updateVendor,
  deactivateVendor
} from "../../modules/vendors/vendor.service";

import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  useTheme,
  alpha,
} from "@mui/material";
import { MOCK_VENDOR_FLORISTS } from './WireMockData';

const WireVendorsPage: React.FC = () => {
  const handleSaveVendor = (data: any) => {
    if (editingVendor) {
      updateVendor({
        ...editingVendor,
        ...data
      });
    } else {
      addVendor({
        id: Date.now().toString(),
        status: "ACTIVE",
        ...data
      });
    }
    setVendors(getVendors());
  };
  const [vendors, setVendors] = React.useState(getVendors());
  const [openForm, setOpenForm] = React.useState(false);
  const [editingVendor, setEditingVendor] = React.useState<any>(null);
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bg = dk ? '#0f0f0f' : '#f8f9fa';

  const headerSx = {
    fontWeight: 700,
    fontSize: '0.7rem',
    textTransform: 'uppercase' as const,
    letterSpacing: 0.5,
    whiteSpace: 'nowrap' as const,
    color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
    bgcolor: dk ? '#1a1a2e' : '#f5f5f5',
    borderBottom: `2px solid ${dk ? 'rgba(255,255,255,0.08)' : '#ddd'}`,
  };

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bg, minHeight: '100vh' }}>
      <Typography variant="h4" sx={{ fontWeight: 800, mb: 0.5 }}>
        Vendor Florists
      </Typography>
      <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 3 }}>
        Active vendors used for outgoing wire orders
      </Typography>

      <Box sx={{ mb: 2 }}>
        <Button
          startIcon={<AddIcon />}
          variant="contained"
          onClick={() => {
            setEditingVendor(null);
            setOpenForm(true);
          }}
        >
          Add Vendor
        </Button>
      </Box>
      <VendorForm
        open={openForm}
        vendor={editingVendor}
        onClose={() => setOpenForm(false)}
        onSave={handleSaveVendor}
      />
      <Typography variant="h4" sx={{ fontWeight: 800, mb: 0.5 }}>
        Vendor Florists
      </Typography>
      <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 3 }}>
        Active vendors used for outgoing wire orders
      </Typography>

      <TableContainer
        component={Paper}
        elevation={dk ? 0 : 1}
        sx={{
          bgcolor: dk ? '#0f0f0f' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
          borderRadius: 2,
        }}
      >
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell sx={headerSx}>Vendor</TableCell>
              <TableCell sx={headerSx}>City</TableCell>
              <TableCell sx={headerSx}>State</TableCell>
              <TableCell sx={headerSx}>Address</TableCell>
              <TableCell sx={headerSx}>Zip</TableCell>
              <TableCell sx={headerSx}>Contact</TableCell>
              <TableCell sx={headerSx} align="right">Commission %</TableCell>
              <TableCell sx={headerSx} align="right">Status</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {vendors.map((vendor) => (
              <TableRow
                key={vendor.id}
                hover
                sx={{ '&:hover': { bgcolor: dk ? alpha('#fff', 0.03) : alpha('#000', 0.02) } }}
              >
                <TableCell>
                  <Typography variant="body2" sx={{ fontWeight: 700 }}>
                    {vendor.name}
                  </Typography>
                </TableCell>
                <TableCell>{vendor.city}</TableCell>
                <TableCell>{vendor.state}</TableCell>
                                <TableCell>
                                  {vendor.address ?? "—"}
                                </TableCell>
                                <TableCell>
                                  {vendor.zipCode ?? "—"}
                                </TableCell>
                <TableCell>
                  <Typography variant="body2">{vendor.phone ?? '—'}</Typography>
                  <Typography variant="caption" color="text.secondary">
                    {vendor.email ?? '—'}
                  </Typography>
                </TableCell>
                <TableCell align="right">
                  {vendor.defaultCommissionRate != null ? `${vendor.defaultCommissionRate}%` : '—'}
                </TableCell>
                <TableCell align="right">
                  <Chip
                    label={vendor.isActive ? 'Active' : 'Inactive'}
                    size="small"
                    color={vendor.isActive ? 'success' : 'default'}
                    variant={dk ? 'outlined' : 'filled'}
                    sx={{ fontWeight: 700 }}
                  />
                  {/* Edit Button */}
                  <IconButton
                    onClick={() => {
                      setEditingVendor(vendor);
                      setOpenForm(true);
                    }}
                  >
                    <EditIcon />
                  </IconButton>
                  {/* Deactivate Button */}
                  <IconButton
                    onClick={() => {
                      deactivateVendor(vendor.id);
                      setVendors(getVendors());
                    }}
                  >
                    <DeleteIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default WireVendorsPage;