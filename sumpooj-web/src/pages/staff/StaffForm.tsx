/**
 * StaffForm.tsx — Create / Edit Staff Member
 *
 * Features:
 * - Required fields: Name, Role
 * - Optional: Location, Phone, Email, Commission, Hourly Rate
 * - Active toggle (Admin only — soft-delete via isActive=false)
 * - Role-based field visibility:
 *     Admin  → all fields, add/edit/deactivate
 *     Manager → edit limited fields (phone, email, commission, hourly rate)
 * - Prevents deletion if staff has historical orders (deactivate instead)
 */
import React, { useState, useEffect, useMemo } from 'react';
import {
  Box, Typography, TextField, Button, Card, Grid, MenuItem,
  Select, FormControl, InputLabel, Switch, FormControlLabel,
  useTheme, alpha, Divider, InputAdornment, Snackbar, Alert,
  Breadcrumbs, Link, Chip,
} from '@mui/material';
import {
  Save as SaveIcon,
  Cancel as CancelIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Badge as BadgeIcon,
  Store as LocationIcon,
  AttachMoney as MoneyIcon,
  Schedule as HourlyIcon,
  ArrowBack as BackIcon,
  NavigateNext as NavIcon,
  ToggleOn as ActiveIcon,
  Warning as WarnIcon,
} from '@mui/icons-material';
import { useNavigate, useParams, Link as RouterLink } from 'react-router-dom';
import { useRBAC } from '../../core/rbac/RBACContext';
import type { Staff, StaffFormData, StaffRole, CommissionType } from './StaffTypes';
import {
  STAFF_ROLES,
  STAFF_ROLE_CONFIG,
  COMMISSION_TYPE_CONFIG,
  COMMISSION_TYPES,
  getInitialFormData,
} from './StaffTypes';
import { getStaffById, staffHasOrders, MOCK_STAFF } from './StaffMockData';
import { MOCK_LOCATIONS } from '../../core/location/LocationTypes';

// ─── Form Section ────────────────────────────────────────────

interface FormSectionProps {
  title: string;
  icon?: React.ReactNode;
  children: React.ReactNode;
}

const FormSection: React.FC<FormSectionProps> = ({ title, icon, children }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Box sx={{ mb: 3 }}>
      <Typography
        variant="subtitle2"
        sx={{
          fontWeight: 700,
          mb: 2,
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary',
        }}
      >
        {icon}
        {title}
      </Typography>
      {children}
    </Box>
  );
};

// ─── Main Component ──────────────────────────────────────────

const StaffForm: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const { staffId } = useParams<{ staffId: string }>();
  const isEdit = Boolean(staffId);
  const { can } = useRBAC();

  // Permission flags
  const isAdmin = can('users:manage');
  const canManageStaff = can('staff:manage');

  // If neither admin nor manager, redirect (shouldn't happen with route guards)
  const canAccess = isAdmin || canManageStaff;

  // State
  const [formData, setFormData] = useState<StaffFormData>(getInitialFormData());
  const [locationId, setLocationId] = useState<string>('');
  const [errors, setErrors] = useState<Partial<Record<keyof StaffFormData | 'locationId', string>>>({});
  const [loading, setLoading] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  // Load existing staff for edit
  const existingStaff = useMemo(() => {
    if (isEdit && staffId) {
      return getStaffById(staffId);
    }
    return null;
  }, [isEdit, staffId]);

  // Check if staff has historical orders (prevents deletion)
  const hasOrders = useMemo(() => {
    if (!existingStaff) return false;
    return staffHasOrders(existingStaff.id);
  }, [existingStaff]);

  useEffect(() => {
    if (existingStaff) {
      setFormData(getInitialFormData(existingStaff));
      setLocationId(existingStaff.locationId || '');
    }
  }, [existingStaff]);

  // Active locations for dropdown
  const activeLocations = useMemo(
    () => MOCK_LOCATIONS.filter((l) => l.isActive),
    [],
  );

  // Handlers
  const handleChange = (field: keyof StaffFormData) => (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement> | { target: { value: string } },
  ) => {
    setFormData({ ...formData, [field]: e.target.value });
    if (errors[field]) {
      setErrors({ ...errors, [field]: undefined });
    }
  };

  const validate = (): boolean => {
    const newErrors: Partial<Record<keyof StaffFormData | 'locationId', string>> = {};

    if (!formData.name.trim()) newErrors.name = 'Name is required';

    if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Enter a valid email';
    }

    if (formData.phone && !/^[+\d\s-]{7,}$/.test(formData.phone)) {
      newErrors.phone = 'Enter a valid phone number';
    }

    if (formData.commissionRate && (isNaN(Number(formData.commissionRate)) || Number(formData.commissionRate) < 0 || Number(formData.commissionRate) > 100)) {
      newErrors.commissionRate = 'Enter a value between 0 and 100';
    }

    if (formData.hourlyRate && (isNaN(Number(formData.hourlyRate)) || Number(formData.hourlyRate) < 0)) {
      newErrors.hourlyRate = 'Enter a valid amount';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;

    setLoading(true);
    try {
      const now = new Date().toISOString();
      const staffData: Staff = {
        id: existingStaff?.id || `staff-${Date.now()}`,
        name: formData.name.trim(),
        role: formData.role,
        locationId: locationId || undefined,
        phone: formData.phone || undefined,
        email: formData.email || undefined,
        commissionType: (formData.commissionType as CommissionType) || undefined,
        commissionRate: formData.commissionRate ? Number(formData.commissionRate) : undefined,
        hourlyRate: formData.hourlyRate ? Number(formData.hourlyRate) : undefined,
        isActive: formData.isActive,
        hireDate: existingStaff?.hireDate || now.split('T')[0],
        createdAt: existingStaff?.createdAt || now,
        updatedAt: now,
      };

      // Simulate API call
      console.log(isEdit ? 'Updating staff:' : 'Creating staff:', staffData);
      await new Promise((resolve) => setTimeout(resolve, 600));

      // Mock: update in-memory array
      if (isEdit) {
        const idx = MOCK_STAFF.findIndex((s) => s.id === staffData.id);
        if (idx >= 0) MOCK_STAFF[idx] = staffData;
      } else {
        MOCK_STAFF.push(staffData);
      }

      setSnackbar({
        open: true,
        message: isEdit ? 'Staff member updated successfully!' : 'Staff member created successfully!',
        severity: 'success',
      });

      setTimeout(() => navigate('/staff'), 800);
    } catch {
      setSnackbar({
        open: true,
        message: 'Failed to save. Please try again.',
        severity: 'error',
      });
    } finally {
      setLoading(false);
    }
  };

  // Not found
  if (isEdit && !existingStaff) {
    return (
      <Box sx={{ p: { xs: 2, md: 3 }, textAlign: 'center', maxWidth: 450, mx: 'auto', mt: 8 }}>
        <WarnIcon sx={{ fontSize: 64, color: '#f44336', opacity: 0.5, mb: 2 }} />
        <Typography variant="h5" sx={{ fontWeight: 700, mb: 1 }}>Staff Not Found</Typography>
        <Button variant="contained" startIcon={<BackIcon />} onClick={() => navigate('/staff')}
          sx={{ mt: 2, bgcolor: '#7c4dff', '&:hover': { bgcolor: '#651fff' } }}>
          Back to Staff
        </Button>
      </Box>
    );
  }

  // Access denied
  if (!canAccess) {
    return (
      <Box sx={{ p: { xs: 2, md: 3 }, textAlign: 'center', maxWidth: 450, mx: 'auto', mt: 8 }}>
        <WarnIcon sx={{ fontSize: 64, color: '#ff9800', opacity: 0.5, mb: 2 }} />
        <Typography variant="h5" sx={{ fontWeight: 700, mb: 1 }}>Access Denied</Typography>
        <Typography variant="body2" sx={{ color: 'text.secondary', mb: 3 }}>
          You don't have permission to {isEdit ? 'edit' : 'add'} staff members.
        </Typography>
        <Button variant="contained" startIcon={<BackIcon />} onClick={() => navigate('/staff')}
          sx={{ bgcolor: '#7c4dff', '&:hover': { bgcolor: '#651fff' } }}>
          Back to Staff
        </Button>
      </Box>
    );
  }

  // Manager cannot create new staff or change role/active status
  const canEditRole = isAdmin;
  const canEditActive = isAdmin;
  const canCreate = isAdmin;

  if (!isEdit && !canCreate) {
    return (
      <Box sx={{ p: { xs: 2, md: 3 }, textAlign: 'center', maxWidth: 450, mx: 'auto', mt: 8 }}>
        <WarnIcon sx={{ fontSize: 64, color: '#ff9800', opacity: 0.5, mb: 2 }} />
        <Typography variant="h5" sx={{ fontWeight: 700, mb: 1 }}>Admin Only</Typography>
        <Typography variant="body2" sx={{ color: 'text.secondary', mb: 3 }}>
          Only administrators can add new staff members.
        </Typography>
        <Button variant="contained" startIcon={<BackIcon />} onClick={() => navigate('/staff')}
          sx={{ bgcolor: '#7c4dff', '&:hover': { bgcolor: '#651fff' } }}>
          Back to Staff
        </Button>
      </Box>
    );
  }

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 900, mx: 'auto' }}>
      {/* Breadcrumbs */}
      <Breadcrumbs separator={<NavIcon sx={{ fontSize: 16 }} />} sx={{ mb: 2 }}>
        <Link component={RouterLink} to="/staff"
          sx={{ color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary', textDecoration: 'none' }}>
          Staff
        </Link>
        <Typography sx={{ color: dk ? '#fff' : 'text.primary', fontWeight: 600 }}>
          {isEdit ? existingStaff?.name : 'New Staff'}
        </Typography>
      </Breadcrumbs>

      {/* Header */}
      <Box sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
        <BadgeIcon sx={{ fontSize: 32, color: '#7c4dff' }} />
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800 }}>
            {isEdit ? 'Edit Staff Member' : 'Add New Staff Member'}
          </Typography>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            {isEdit ? 'Update staff details and settings' : 'Add a team member to your florist operation'}
          </Typography>
        </Box>
      </Box>

      {/* Form Card */}
      <Card
        sx={{
          p: { xs: 2, md: 3 },
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          borderRadius: 3,
        }}
      >
        {/* ─── Basic Information ──────────────────────── */}
        <FormSection title="Basic Information" icon={<PersonIcon fontSize="small" />}>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 6 }}>
              <TextField
                label="Full Name"
                value={formData.name}
                onChange={handleChange('name')}
                fullWidth
                required
                error={Boolean(errors.name)}
                helperText={errors.name}
                placeholder="e.g., Priya Sharma"
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <PersonIcon sx={{ color: 'text.secondary' }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}>
              <FormControl fullWidth required disabled={!canEditRole}>
                <InputLabel>Role</InputLabel>
                <Select
                  value={formData.role}
                  label="Role"
                  onChange={(e) => setFormData({ ...formData, role: e.target.value as StaffRole })}
                >
                  {STAFF_ROLES.map((r) => (
                    <MenuItem key={r} value={r}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Typography>{STAFF_ROLE_CONFIG[r].icon}</Typography>
                        <Typography>{STAFF_ROLE_CONFIG[r].label}</Typography>
                      </Box>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              {!canEditRole && (
                <Typography variant="caption" sx={{ color: 'text.secondary', mt: 0.5, display: 'block' }}>
                  Only administrators can change roles
                </Typography>
              )}
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}>
              <FormControl fullWidth disabled={!canEditRole}>
                <InputLabel>Location</InputLabel>
                <Select
                  value={locationId}
                  label="Location"
                  onChange={(e) => setLocationId(e.target.value)}
                  startAdornment={
                    <InputAdornment position="start">
                      <LocationIcon sx={{ color: 'text.secondary' }} />
                    </InputAdornment>
                  }
                >
                  <MenuItem value="">
                    <em>No specific location</em>
                  </MenuItem>
                  {activeLocations.map((loc) => (
                    <MenuItem key={loc.id} value={loc.id}>
                      {loc.name} ({loc.code})
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              {!canEditRole && (
                <Typography variant="caption" sx={{ color: 'text.secondary', mt: 0.5, display: 'block' }}>
                  Only administrators can change location
                </Typography>
              )}
            </Grid>
          </Grid>
        </FormSection>

        <Divider sx={{ my: 3 }} />

        {/* ─── Contact Information ────────────────────── */}
        <FormSection title="Contact Information" icon={<PhoneIcon fontSize="small" />}>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 6 }}>
              <TextField
                label="Phone"
                value={formData.phone}
                onChange={handleChange('phone')}
                fullWidth
                error={Boolean(errors.phone)}
                helperText={errors.phone}
                placeholder="+91 98765 43210"
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <PhoneIcon sx={{ color: 'text.secondary' }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}>
              <TextField
                label="Email"
                value={formData.email}
                onChange={handleChange('email')}
                fullWidth
                error={Boolean(errors.email)}
                helperText={errors.email}
                placeholder="priya@florist.com"
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <EmailIcon sx={{ color: 'text.secondary' }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Grid>
          </Grid>
        </FormSection>

        <Divider sx={{ my: 3 }} />

        {/* ─── Compensation ───────────────────────────── */}
        <FormSection title="Compensation" icon={<MoneyIcon fontSize="small" />}>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 4 }}>
              <FormControl fullWidth>
                <InputLabel>Commission Type</InputLabel>
                <Select
                  value={formData.commissionType}
                  label="Commission Type"
                  onChange={(e) => setFormData({ ...formData, commissionType: e.target.value as CommissionType | '' })}
                >
                  <MenuItem value="">
                    <em>None</em>
                  </MenuItem>
                  {COMMISSION_TYPES.map((ct) => (
                    <MenuItem key={ct} value={ct}>
                      {COMMISSION_TYPE_CONFIG[ct].label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid size={{ xs: 12, md: 4 }}>
              <TextField
                label="Commission Rate (%)"
                value={formData.commissionRate}
                onChange={handleChange('commissionRate')}
                fullWidth
                type="number"
                error={Boolean(errors.commissionRate)}
                helperText={errors.commissionRate || (formData.commissionType ? `% of ${formData.commissionType.toLowerCase()}` : '')}
                disabled={!formData.commissionType}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <MoneyIcon sx={{ color: 'text.secondary' }} />
                    </InputAdornment>
                  ),
                  endAdornment: <InputAdornment position="end">%</InputAdornment>,
                }}
              />
            </Grid>
            <Grid size={{ xs: 12, md: 4 }}>
              <TextField
                label="Hourly Rate"
                value={formData.hourlyRate}
                onChange={handleChange('hourlyRate')}
                fullWidth
                type="number"
                error={Boolean(errors.hourlyRate)}
                helperText={errors.hourlyRate}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <HourlyIcon sx={{ color: 'text.secondary' }} />
                    </InputAdornment>
                  ),
                  endAdornment: <InputAdornment position="end">/hr</InputAdornment>,
                }}
              />
            </Grid>
          </Grid>
        </FormSection>

        <Divider sx={{ my: 3 }} />

        {/* ─── Active Status (Admin only) ─────────────── */}
        <FormSection title="Status" icon={<ActiveIcon fontSize="small" />}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
            <FormControlLabel
              control={
                <Switch
                  checked={formData.isActive}
                  onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  disabled={!canEditActive}
                  color="success"
                />
              }
              label={
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {formData.isActive ? 'Active' : 'Inactive'}
                  </Typography>
                  <Chip
                    label={formData.isActive ? '● Active' : '○ Inactive'}
                    size="small"
                    sx={{
                      bgcolor: formData.isActive ? alpha('#4caf50', 0.15) : alpha('#9e9e9e', 0.15),
                      color: formData.isActive ? '#4caf50' : '#9e9e9e',
                      fontWeight: 600,
                      fontSize: '0.7rem',
                    }}
                  />
                </Box>
              }
            />

            {!canEditActive && (
              <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                Only administrators can change active status
              </Typography>
            )}
          </Box>

          {isEdit && !formData.isActive && hasOrders && (
            <Alert severity="info" sx={{ mt: 2 }}>
              <Typography variant="body2">
                This staff member has historical orders and cannot be permanently deleted.
                Setting them to <strong>Inactive</strong> will prevent them from being assigned to new orders.
              </Typography>
            </Alert>
          )}

          {isEdit && formData.isActive && existingStaff && !existingStaff.isActive && (
            <Alert severity="success" sx={{ mt: 2 }}>
              <Typography variant="body2">
                Reactivating this staff member will allow them to be assigned to new orders again.
              </Typography>
            </Alert>
          )}
        </FormSection>

        {/* ─── Action Buttons ─────────────────────────── */}
        <Box sx={{ display: 'flex', gap: 2, mt: 4, justifyContent: 'flex-end' }}>
          <Button
            variant="outlined"
            startIcon={<CancelIcon />}
            onClick={() => navigate('/staff')}
            disabled={loading}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            startIcon={<SaveIcon />}
            onClick={handleSubmit}
            disabled={loading}
            sx={{
              bgcolor: '#7c4dff',
              '&:hover': { bgcolor: '#651fff' },
              fontWeight: 700,
              px: 4,
            }}
          >
            {loading ? 'Saving...' : isEdit ? 'Update Staff' : 'Add Staff Member'}
          </Button>
        </Box>
      </Card>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity={snackbar.severity} onClose={() => setSnackbar({ ...snackbar, open: false })}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default StaffForm;
