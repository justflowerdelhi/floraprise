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
import React, { useState, useEffect, useCallback } from 'react';
import { Box, Typography, TextField, Button, Card, Grid, MenuItem, Select, FormControl, InputLabel, Switch, FormControlLabel, useTheme, alpha, Divider, InputAdornment, CircularProgress, Alert, Breadcrumbs, Link, Chip, Checkbox, Dialog, DialogTitle, DialogContent, DialogActions } from '@mui/material';
import type { SelectChangeEvent } from '@mui/material';
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
  VpnKey as LoginIcon,
  Lock as LockIcon,
} from '@mui/icons-material';
import { useNavigate, useParams, Link as RouterLink } from 'react-router-dom';
import { useRBAC } from '../../core/rbac/RBACContext';
import type { Staff, StaffFormData, StaffRole, CommissionType } from './StaffTypes';
import {
  STAFF_ROLES,
  STAFF_ROLE_CONFIG,
  COMMISSION_TYPE_CONFIG,
  COMMISSION_TYPES,
  LOGIN_ROLES,
  getInitialFormData,
  normalizeRole,
} from './StaffTypes';
import { getStaffById as getStaffByIdApi, createStaff as createStaffApi, updateStaff as updateStaffApi, enableStaffLogin, resetStaffPassword, disableStaffLogin, checkStaffHasOrders } from '../../api/staff.api';
import { getLocations } from '../../api/location.api';
import { useToast } from '../../hooks/useToast';
import { useApiCall } from '../../hooks/useApiCall';
import { useCurrency } from '../../core/i18n';

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
  const { currencySymbol } = useCurrency();
  const navigate = useNavigate();
  const { staffId } = useParams<{ staffId: string }>();
  const isEdit = Boolean(staffId);
  const { can } = useRBAC();

  // Permission flags
  const isAdmin = can('users:manage');
  const canManageStaff = can('staff:manage');

  // If neither admin nor manager, redirect (shouldn't happen with route guards)
  const canAccess = isAdmin || canManageStaff;

  const toast = useToast();
  const { loading, execute } = useApiCall();

  // State
  const [formData, setFormData] = useState<StaffFormData>(getInitialFormData());
  const [locationId, setLocationId] = useState<string>('');
  const [errors, setErrors] = useState<Partial<Record<keyof StaffFormData | 'locationId', string>>>({});
  const [existingStaff, setExistingStaff] = useState<Staff | null>(null);
  const [hasOrders, setHasOrders] = useState(false);
  const [activeLocations, setActiveLocations] = useState<{ id: string; name: string; isActive: boolean; code?: string }[]>([]);
  const [loadingStaff, setLoadingStaff] = useState(false);

  // Login management state (edit mode)
  const [loginActionLoading, setLoginActionLoading] = useState(false);
  const [disableConfirmOpen, setDisableConfirmOpen] = useState(false);

  // Load existing staff for edit
  const loadStaff = useCallback(async () => {
    if (!isEdit || !staffId) return;
    setLoadingStaff(true);
    try {
      const [staff, orderCheck] = await Promise.all([
        getStaffByIdApi(staffId),
        checkStaffHasOrders(staffId).catch(() => ({ hasOrders: false, orderCount: 0 })),
      ]);
      const normalized = { ...staff, role: normalizeRole(staff.role) };
      setExistingStaff(normalized);
      setFormData(getInitialFormData(normalized));
      setLocationId(staff.locationId || '');
      setHasOrders(orderCheck.hasOrders);
    } catch {
      toast.error('Failed to load staff member');
    } finally {
      setLoadingStaff(false);
    }
  }, [isEdit, staffId]);

  // Load locations
  const loadLocations = useCallback(async () => {
    try {
      const data = await getLocations();
      const list = Array.isArray(data) ? data : data.items ?? [];
      setActiveLocations(list.filter((l: any) => l.isActive));
    } catch { /* ignore */ }
  }, []);

  useEffect(() => {
    loadStaff();
    loadLocations();
  }, [loadStaff, loadLocations]);

  // Handlers
  const handleChange = (field: keyof StaffFormData) => (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement> | { target: { value: unknown } },
  ) => {
    setFormData({ ...formData, [field]: (e.target as HTMLInputElement).value });
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

    // Login access validation
    if (formData.enableLogin) {
      if (!formData.loginIdentifier.trim()) {
        newErrors.loginIdentifier = 'Login identifier (email or phone) is required';
      }
      if (!formData.loginRole) {
        newErrors.loginRole = 'Login role is required';
      }
      if (!formData.password || formData.password.length < 8) {
        newErrors.password = 'Password must be at least 8 characters';
      }
      if (formData.password !== formData.confirmPassword) {
        newErrors.confirmPassword = 'Passwords do not match';
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;

    const payload = {
      name: formData.name.trim(),
      role: formData.role,
      email: formData.email || null,
      phone: formData.phone || null,
      commissionType: formData.commissionType || null,
      commissionRate: formData.commissionRate ? Number(formData.commissionRate) : null,
      hourlyRate: formData.hourlyRate ? Number(formData.hourlyRate) : null,
      primaryLocationId: locationId || null,
      isActive: formData.isActive,
      // Login fields — only sent on create when enabled
      ...(!isEdit && formData.enableLogin
        ? {
            enableLogin: true,
            loginIdentifier: formData.loginIdentifier.trim(),
            loginRole: formData.loginRole,
            password: formData.password,
          }
        : {}),
    };

    const result = await execute(
      () => isEdit && staffId ? updateStaffApi(staffId, payload) : createStaffApi(payload as any),
      {
        successMessage: isEdit ? 'Staff member updated successfully!' : 'Staff member created successfully!',
        errorMessage: isEdit ? 'Failed to update staff member' : 'Failed to create staff member',
      }
    );

    if (result) {
      setTimeout(() => navigate('/staff'), 800);
    }
  };

  // ── Login management handlers (edit mode) ─────────────────

  const handleEnableLogin = async () => {
    if (!staffId) return;
    // Validate login fields first
    const newErrors: Partial<Record<keyof StaffFormData, string>> = {};
    if (!formData.loginIdentifier.trim()) newErrors.loginIdentifier = 'Login identifier is required';
    if (!formData.loginRole) newErrors.loginRole = 'Login role is required';
    if (!formData.password || formData.password.length < 8) newErrors.password = 'Password must be at least 8 characters';
    if (formData.password !== formData.confirmPassword) newErrors.confirmPassword = 'Passwords do not match';
    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    setLoginActionLoading(true);
    try {
      await enableStaffLogin(staffId, {
        loginIdentifier: formData.loginIdentifier.trim(),
        loginRole: formData.loginRole,
        password: formData.password,
      });
      // Refresh staff data so UI shows login-enabled state
      await loadStaff();
      toast.success('Login access enabled successfully!');
    } catch (err: any) {
      toast.error(err?.response?.data?.message || err?.message || 'Failed to enable login');
    } finally {
      setLoginActionLoading(false);
    }
  };

  const handleResetPassword = async () => {
    if (!staffId) return;
    // Validate password
    if (!formData.password || formData.password.length < 8) {
      setErrors({ password: 'Password must be at least 8 characters' });
      return;
    }
    if (formData.password !== formData.confirmPassword) {
      setErrors({ confirmPassword: 'Passwords do not match' });
      return;
    }

    setLoginActionLoading(true);
    try {
      await resetStaffPassword(staffId, { password: formData.password });
      setFormData((prev) => ({ ...prev, password: '', confirmPassword: '' }));
      toast.success('Password reset successfully!');
    } catch (err: any) {
      toast.error(err?.response?.data?.message || err?.message || 'Failed to reset password');
    } finally {
      setLoginActionLoading(false);
    }
  };

  const handleDisableLogin = async () => {
    if (!staffId) return;
    setDisableConfirmOpen(false);
    setLoginActionLoading(true);
    try {
      await disableStaffLogin(staffId);
      // Refresh staff data so UI shows login-disabled state
      await loadStaff();
      toast.success('Login access disabled successfully');
    } catch (err: any) {
      toast.error(err?.response?.data?.message || err?.message || 'Failed to disable login');
    } finally {
      setLoginActionLoading(false);
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
              <FormControl fullWidth required disabled={!canEditRole} sx={{ minWidth: 220 }}>
                <InputLabel>Role</InputLabel>
                <Select
                  value={formData.role}
                  label="Role"
                  onChange={(e: SelectChangeEvent) =>
                    setFormData({ ...formData, role: e.target.value as StaffRole })
                  }
                  MenuProps={{ PaperProps: { sx: { minWidth: 220 } } }}
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
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}>
              <FormControl fullWidth disabled={!canEditRole} sx={{ minWidth: 220 }}>
                <InputLabel>Location</InputLabel>
                <Select
                  value={locationId}
                  label="Location"
                  onChange={(e: SelectChangeEvent) => setLocationId(e.target.value as string)}
                  MenuProps={{ PaperProps: { sx: { minWidth: 220 } } }}
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
              <FormControl fullWidth sx={{ minWidth: 220 }}>
                <InputLabel>Salary Type</InputLabel>
                <Select
                  value={formData.salaryType || ''}
                  label="Salary Type"
                  onChange={(e: SelectChangeEvent) => setFormData({ ...formData, salaryType: e.target.value as 'MONTHLY' | 'HOURLY' | '' })}
                  MenuProps={{ PaperProps: { sx: { minWidth: 220 } } }}
                >
                  <MenuItem value="MONTHLY">Monthly Salary</MenuItem>
                  <MenuItem value="HOURLY">Hourly</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            {formData.salaryType === 'MONTHLY' && (
              <Grid size={{ xs: 12, md: 4 }}>
                <TextField
                  label="Monthly Salary"
                  fullWidth
                  type="number"
                  InputProps={{ startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment> }}
                  value={formData.monthlySalary}
                  onChange={handleChange('monthlySalary')}
                />
              </Grid>
            )}
            <Grid size={{ xs: 12, md: 4 }}>
              <TextField
                label="Overtime Rate"
                type="number"
                InputProps={{ endAdornment: <InputAdornment position="end">{`${currencySymbol} / hr`}</InputAdornment> }}
                value={formData.overtimeRate}
                onChange={handleChange('overtimeRate')}
                fullWidth
              />
            </Grid>
            <Grid size={{ xs: 12, md: 4 }}>
              <FormControl fullWidth sx={{ minWidth: 220 }}>
                <InputLabel>Weekly Off</InputLabel>
                <Select
                  multiple
                  value={Array.isArray(formData.weeklyOff) ? formData.weeklyOff : []}
                  onChange={(e: any) => setFormData({ ...formData, weeklyOff: typeof e.target.value === 'string' ? (e.target.value as string).split(',') : e.target.value as string[] })}
                  MenuProps={{ PaperProps: { sx: { minWidth: 220 } } }}
                >
                  <MenuItem value="Sunday">Sunday</MenuItem>
                  <MenuItem value="Monday">Monday</MenuItem>
                  <MenuItem value="Tuesday">Tuesday</MenuItem>
                  <MenuItem value="Wednesday">Wednesday</MenuItem>
                  <MenuItem value="Thursday">Thursday</MenuItem>
                  <MenuItem value="Friday">Friday</MenuItem>
                  <MenuItem value="Saturday">Saturday</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid size={12}>
              <Grid container spacing={2}>
                <Grid size={6}>
                  <TextField
                    label="Shift Start"
                    type="time"
                    InputLabelProps={{ shrink: true }}
                    value={formData.shiftStart}
                    onChange={handleChange('shiftStart')}
                    fullWidth
                  />
                </Grid>
                <Grid size={6}>
                  <TextField
                    label="Shift End"
                    type="time"
                    InputLabelProps={{ shrink: true }}
                    value={formData.shiftEnd}
                    onChange={handleChange('shiftEnd')}
                    fullWidth
                  />
                </Grid>
              </Grid>
            </Grid>
          </Grid>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 4 }}>
              <FormControl fullWidth sx={{ minWidth: 220 }}>
                <InputLabel>Commission Type</InputLabel>
                <Select
                  value={formData.commissionType}
                  label="Commission Type"
                  onChange={(e: SelectChangeEvent) => setFormData({ ...formData, commissionType: e.target.value as CommissionType | '' })}
                  MenuProps={{ PaperProps: { sx: { minWidth: 220 } } }}
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

        {/* ─── Login Access (Admin only) ────────────── */}
        {isAdmin && (
          <>
            <Divider sx={{ my: 3 }} />
            <FormSection title="Login Access" icon={<LoginIcon fontSize="small" />}>
              {/* ── EDIT Mode: Staff already has login ── */}
              {isEdit && existingStaff?.identityUserId && (
                <>
                  {/* Read-only login info */}
                  <Box sx={{
                    bgcolor: dk ? 'rgba(255,255,255,0.04)' : '#f8f9fa',
                    border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
                    borderRadius: 2, p: 2, mb: 2,
                  }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1.5 }}>
                      <Chip
                        label="Login Enabled"
                        size="small"
                        sx={{ bgcolor: alpha('#4caf50', 0.15), color: '#4caf50', fontWeight: 700, fontSize: '0.7rem' }}
                      />
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>
                        Login Identifier
                      </Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600, fontFamily: 'monospace' }}>
                        {existingStaff.loginIdentifier || '—'}
                      </Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>
                        Login Role
                      </Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {existingStaff.loginRole || '—'}
                      </Typography>
                    </Box>
                  </Box>

                  {/* Action buttons */}
                  <Grid container spacing={2} sx={{ mt: 1 }}>
                    <Grid size={{ xs: 12, md: 6 }}>
                      <TextField
                        label="New Password"
                        value={formData.password}
                        onChange={handleChange('password')}
                        fullWidth
                        type="password"
                        error={Boolean(errors.password)}
                        helperText={errors.password || 'Min 8 characters'}
                        placeholder="Enter new password"
                        InputProps={{
                          startAdornment: (
                            <InputAdornment position="start">
                              <LockIcon sx={{ color: 'text.secondary' }} />
                            </InputAdornment>
                          ),
                        }}
                      />
                    </Grid>
                    <Grid size={{ xs: 12, md: 6 }}>
                      <TextField
                        label="Confirm New Password"
                        value={formData.confirmPassword}
                        onChange={handleChange('confirmPassword')}
                        fullWidth
                        type="password"
                        error={Boolean(errors.confirmPassword)}
                        helperText={errors.confirmPassword || 'Re-enter the new password'}
                        placeholder="Confirm new password"
                        InputProps={{
                          startAdornment: (
                            <InputAdornment position="start">
                              <LockIcon sx={{ color: 'text.secondary' }} />
                            </InputAdornment>
                          ),
                        }}
                      />
                    </Grid>
                    <Grid size={12}>
                      <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                        <Button
                          variant="outlined"
                          size="small"
                          startIcon={<LockIcon />}
                          onClick={handleResetPassword}
                          disabled={loginActionLoading}
                          sx={{ textTransform: 'none', fontWeight: 600 }}
                        >
                          {loginActionLoading ? <CircularProgress size={16} sx={{ mr: 1 }} /> : null}
                          Reset Password
                        </Button>
                        <Button
                          variant="outlined"
                          size="small"
                          color="error"
                          onClick={() => setDisableConfirmOpen(true)}
                          disabled={loginActionLoading}
                          sx={{ textTransform: 'none', fontWeight: 600 }}
                        >
                          Disable Login
                        </Button>
                      </Box>
                    </Grid>
                  </Grid>
                </>
              )}

              {/* ── EDIT Mode: No login yet — offer to enable ── */}
              {isEdit && !existingStaff?.identityUserId && (
                <>
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={formData.enableLogin}
                        onChange={(e) => {
                          setFormData({
                            ...formData,
                            enableLogin: e.target.checked,
                            loginIdentifier: e.target.checked
                              ? formData.email || formData.phone || ''
                              : '',
                            loginRole: e.target.checked
                              ? formData.role.charAt(0) + formData.role.slice(1).toLowerCase()
                              : '',
                          });
                          if (!e.target.checked) {
                            setErrors((prev) => {
                              const next = { ...prev };
                              delete next.loginIdentifier;
                              delete next.loginRole;
                              delete next.password;
                              delete next.confirmPassword;
                              return next;
                            });
                          }
                        }}
                        color="primary"
                      />
                    }
                    label={
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          Enable Login Access
                        </Typography>
                        <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                          Creates an identity account so this staff member can log in to the system
                        </Typography>
                      </Box>
                    }
                  />

                  {formData.enableLogin && (
                    <Grid container spacing={2} sx={{ mt: 1 }}>
                      <Grid size={{ xs: 12, md: 6 }}>
                        <TextField
                          label="Login Identifier (Email or Phone)"
                          value={formData.loginIdentifier}
                          onChange={handleChange('loginIdentifier')}
                          fullWidth
                          required
                          error={Boolean(errors.loginIdentifier)}
                          helperText={errors.loginIdentifier || 'Used as the username for login'}
                          placeholder="staff@florist.com or +91 98765 43210"
                          InputProps={{
                            startAdornment: (
                              <InputAdornment position="start">
                                <LockIcon sx={{ color: 'text.secondary' }} />
                              </InputAdornment>
                            ),
                          }}
                        />
                      </Grid>
                      <Grid size={{ xs: 12, md: 6 }}>
                        <FormControl fullWidth required error={Boolean(errors.loginRole)}>
                          <InputLabel>Login Role</InputLabel>
                          <Select
                            value={formData.loginRole}
                            label="Login Role"
                            onChange={(e) => {
                              setFormData({ ...formData, loginRole: e.target.value });
                              if (errors.loginRole) setErrors({ ...errors, loginRole: undefined });
                            }}
                          >
                            {LOGIN_ROLES.map((r) => (
                              <MenuItem key={r} value={r}>{r}</MenuItem>
                            ))}
                          </Select>
                          {errors.loginRole ? (
                            <Typography variant="caption" sx={{ color: 'error.main', mt: 0.5, ml: 1.75 }}>
                              {errors.loginRole}
                            </Typography>
                          ) : (
                            <Typography variant="caption" sx={{ color: 'text.secondary', mt: 0.5, ml: 1.75 }}>
                              Determines system permissions for this user
                            </Typography>
                          )}
                        </FormControl>
                      </Grid>

                      <Grid size={{ xs: 12, md: 6 }}>
                        <TextField
                          label="Password"
                          value={formData.password}
                          onChange={handleChange('password')}
                          fullWidth
                          required
                          type="password"
                          error={Boolean(errors.password)}
                          helperText={errors.password || 'Min 8 characters'}
                          placeholder="Enter password"
                          InputProps={{
                            startAdornment: (
                              <InputAdornment position="start">
                                <LockIcon sx={{ color: 'text.secondary' }} />
                              </InputAdornment>
                            ),
                          }}
                        />
                      </Grid>
                      <Grid size={{ xs: 12, md: 6 }}>
                        <TextField
                          label="Confirm Password"
                          value={formData.confirmPassword}
                          onChange={handleChange('confirmPassword')}
                          fullWidth
                          required
                          type="password"
                          error={Boolean(errors.confirmPassword)}
                          helperText={errors.confirmPassword || 'Re-enter the password'}
                          placeholder="Confirm password"
                          InputProps={{
                            startAdornment: (
                              <InputAdornment position="start">
                                <LockIcon sx={{ color: 'text.secondary' }} />
                              </InputAdornment>
                            ),
                          }}
                        />
                      </Grid>

                      <Grid size={12}>
                        <Button
                          variant="contained"
                          startIcon={<LoginIcon />}
                          onClick={handleEnableLogin}
                          disabled={loginActionLoading}
                          sx={{
                            bgcolor: '#7c4dff', '&:hover': { bgcolor: '#651fff' },
                            fontWeight: 700, textTransform: 'none',
                          }}
                        >
                          {loginActionLoading ? <CircularProgress size={16} sx={{ mr: 1, color: '#fff' }} /> : null}
                          Enable Login
                        </Button>
                      </Grid>
                    </Grid>
                  )}
                </>
              )}

              {/* ── CREATE Mode: Offer login during creation ── */}
              {!isEdit && (
                <>
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={formData.enableLogin}
                        onChange={(e) => {
                          setFormData({
                            ...formData,
                            enableLogin: e.target.checked,
                            loginIdentifier: e.target.checked
                              ? formData.email || formData.phone || ''
                              : '',
                            loginRole: e.target.checked
                              ? formData.role.charAt(0) + formData.role.slice(1).toLowerCase()
                              : '',
                          });
                          if (!e.target.checked) {
                            setErrors((prev) => {
                              const next = { ...prev };
                              delete next.loginIdentifier;
                              delete next.loginRole;
                              delete next.password;
                              delete next.confirmPassword;
                              return next;
                            });
                          }
                        }}
                        color="primary"
                      />
                    }
                    label={
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          Enable Login Access
                        </Typography>
                        <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                          Creates an identity account so this staff member can log in to the system
                        </Typography>
                      </Box>
                    }
                  />

                  {formData.enableLogin && (
                    <Grid container spacing={2} sx={{ mt: 1 }}>
                      <Grid size={{ xs: 12, md: 6 }}>
                        <TextField
                          label="Login Identifier (Email or Phone)"
                          value={formData.loginIdentifier}
                          onChange={handleChange('loginIdentifier')}
                          fullWidth
                          required
                          error={Boolean(errors.loginIdentifier)}
                          helperText={errors.loginIdentifier || 'Used as the username for login'}
                          placeholder="staff@florist.com or +91 98765 43210"
                          InputProps={{
                            startAdornment: (
                              <InputAdornment position="start">
                                <LockIcon sx={{ color: 'text.secondary' }} />
                              </InputAdornment>
                            ),
                          }}
                        />
                      </Grid>
                      <Grid size={{ xs: 12, md: 6 }}>
                        <FormControl fullWidth required error={Boolean(errors.loginRole)}>
                          <InputLabel>Login Role</InputLabel>
                          <Select
                            value={formData.loginRole}
                            label="Login Role"
                            onChange={(e) => {
                              setFormData({ ...formData, loginRole: e.target.value });
                              if (errors.loginRole) setErrors({ ...errors, loginRole: undefined });
                            }}
                          >
                            {LOGIN_ROLES.map((r) => (
                              <MenuItem key={r} value={r}>{r}</MenuItem>
                            ))}
                          </Select>
                          {errors.loginRole ? (
                            <Typography variant="caption" sx={{ color: 'error.main', mt: 0.5, ml: 1.75 }}>
                              {errors.loginRole}
                            </Typography>
                          ) : (
                            <Typography variant="caption" sx={{ color: 'text.secondary', mt: 0.5, ml: 1.75 }}>
                              Determines system permissions for this user
                            </Typography>
                          )}
                        </FormControl>
                      </Grid>

                      <Grid size={{ xs: 12, md: 6 }}>
                        <TextField
                          label="Password"
                          value={formData.password}
                          onChange={handleChange('password')}
                          fullWidth
                          required
                          type="password"
                          error={Boolean(errors.password)}
                          helperText={errors.password || 'Min 8 characters'}
                          placeholder="Enter password"
                          InputProps={{
                            startAdornment: (
                              <InputAdornment position="start">
                                <LockIcon sx={{ color: 'text.secondary' }} />
                              </InputAdornment>
                            ),
                          }}
                        />
                      </Grid>
                      <Grid size={{ xs: 12, md: 6 }}>
                        <TextField
                          label="Confirm Password"
                          value={formData.confirmPassword}
                          onChange={handleChange('confirmPassword')}
                          fullWidth
                          required
                          type="password"
                          error={Boolean(errors.confirmPassword)}
                          helperText={errors.confirmPassword || 'Re-enter the password'}
                          placeholder="Confirm password"
                          InputProps={{
                            startAdornment: (
                              <InputAdornment position="start">
                                <LockIcon sx={{ color: 'text.secondary' }} />
                              </InputAdornment>
                            ),
                          }}
                        />
                      </Grid>

                      <Grid size={12}>
                        <Button
                          variant="contained"
                          startIcon={<LoginIcon />}
                          onClick={handleEnableLogin}
                          disabled={loginActionLoading}
                          sx={{
                            bgcolor: '#7c4dff', '&:hover': { bgcolor: '#651fff' },
                            fontWeight: 700, textTransform: 'none',
                          }}
                        >
                          {loginActionLoading ? <CircularProgress size={16} sx={{ mr: 1, color: '#fff' }} /> : null}
                          Enable Login
                        </Button>
                      </Grid>
                    </Grid>
                  )}
                </>
              )}
            </FormSection>
          </>
        )}

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

      {/* ─── Disable Login Confirmation Dialog ───────── */}
      <Dialog
        open={disableConfirmOpen}
        onClose={() => setDisableConfirmOpen(false)}
        maxWidth="xs"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <Box sx={{
          bgcolor: alpha('#f44336', 0.08),
          px: 3, py: 2.5,
          display: 'flex', alignItems: 'center', gap: 1.5,
          borderBottom: `1px solid ${alpha('#f44336', 0.2)}`,
        }}>
          <WarnIcon sx={{ color: '#f44336' }} />
          <DialogTitle sx={{ p: 0, fontSize: '1rem', fontWeight: 700 }}>
            Disable Login Access
          </DialogTitle>
        </Box>
        <DialogContent sx={{ px: 3, py: 2.5 }}>
          <Typography variant="body2" sx={{ mb: 1.5 }}>
            This will permanently delete the identity account for <strong>{existingStaff?.loginIdentifier}</strong>.
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary' }}>
            The staff member will no longer be able to log in. You can re-enable login later, but a new account and password will be created.
          </Typography>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button onClick={() => setDisableConfirmOpen(false)} sx={{ textTransform: 'none' }}>
            Cancel
          </Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleDisableLogin}
            disabled={loginActionLoading}
            sx={{ fontWeight: 600, textTransform: 'none' }}
          >
            {loginActionLoading ? <CircularProgress size={16} sx={{ mr: 1 }} /> : null}
            Disable Login
          </Button>
        </DialogActions>
      </Dialog>

    </Box>
  );
};

export default StaffForm;
