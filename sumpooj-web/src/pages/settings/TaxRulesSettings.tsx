/**
 * TaxRulesSettings.tsx — Tax Rules Configuration UI
 *
 * Features:
 * - List all tax rules by country
 * - Add/Edit/Delete tax rules
 * - Activate/Deactivate rules
 * - Support for inclusive/exclusive tax
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Button,
  IconButton,
  Chip,
  Stack,
  Alert,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Switch,
  Tooltip,
  Divider,
  Paper,
  InputAdornment,
  useTheme,
  alpha,
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  TableContainer,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  CheckCircle,
  Cancel,
  Receipt,
  Refresh,
  Public,
  Percent,
} from '@mui/icons-material';
import {
  type TaxRuleDto,
  type CreateTaxRuleRequest,
  type UpdateTaxRuleRequest,
  getTaxRules,
  getTaxRuleById,
  createTaxRule,
  updateTaxRule,
  deactivateTaxRule,
  activateTaxRule,
} from '../../api/tax.api';
import { useToast } from '../../hooks/useToast';

// ─── Country Options ────────────────────────────────────────

const COUNTRY_OPTIONS = [
  { code: 'US', label: 'United States', flag: '🇺🇸' },
  { code: 'IN', label: 'India', flag: '🇮🇳' },
  { code: 'AE', label: 'UAE', flag: '🇦🇪' },
  { code: 'SA', label: 'Saudi Arabia', flag: '🇸🇦' },
  { code: 'GB', label: 'United Kingdom', flag: '🇬🇧' },
  { code: 'CA', label: 'Canada', flag: '🇨🇦' },
  { code: 'AU', label: 'Australia', flag: '🇦🇺' },
];

const getCountryLabel = (code: string) => {
  const country = COUNTRY_OPTIONS.find((c) => c.code === code);
  return country ? `${country.flag} ${country.label}` : code;
};

// ─── Tax Rule Form Dialog ───────────────────────────────────

interface TaxRuleFormProps {
  open: boolean;
  onClose: () => void;
  onSave: (data: CreateTaxRuleRequest | UpdateTaxRuleRequest, id?: string) => void;
  editRule?: TaxRuleDto | null;
  loading?: boolean;
}

const TaxRuleFormDialog: React.FC<TaxRuleFormProps> = ({
  open,
  onClose,
  onSave,
  editRule,
  loading,
}) => {
  const [countryCode, setCountryCode] = useState('');
  const [name, setName] = useState('');
  const [rate, setRate] = useState<number>(0);
  const [isInclusive, setIsInclusive] = useState(false);

  useEffect(() => {
    if (open) {
      if (editRule) {
        setCountryCode(editRule.countryCode);
        setName(editRule.name);
        setRate(editRule.rate);
        setIsInclusive(editRule.isInclusive);
      } else {
        setCountryCode('');
        setName('');
        setRate(0);
        setIsInclusive(false);
      }
    }
  }, [open, editRule]);

  const handleSubmit = () => {
    const data = {
      countryCode,
      name,
      rate,
      isInclusive,
    };
    onSave(data, editRule?.id);
  };

  const canSubmit = countryCode && name.trim() && rate >= 0;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        <Stack direction="row" spacing={1} alignItems="center">
          <Receipt />
          <Typography variant="h6">
            {editRule ? 'Edit Tax Rule' : 'Add Tax Rule'}
          </Typography>
        </Stack>
      </DialogTitle>

      <DialogContent dividers>
        <Grid container spacing={3}>
          <Grid size={12}>
            <FormControl fullWidth>
              <InputLabel>Country</InputLabel>
              <Select
                value={countryCode}
                onChange={(e) => setCountryCode(e.target.value)}
                label="Country"
                disabled={!!editRule}
              >
                {COUNTRY_OPTIONS.map((c) => (
                  <MenuItem key={c.code} value={c.code}>
                    {c.flag} {c.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid size={12}>
            <TextField
              fullWidth
              label="Tax Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., GST, VAT, Sales Tax"
              required
            />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Tax Rate (%)"
              type="number"
              value={rate}
              onChange={(e) => setRate(parseFloat(e.target.value) || 0)}
              InputProps={{
                endAdornment: <InputAdornment position="end">%</InputAdornment>,
                inputProps: { min: 0, max: 100, step: 0.01 },
              }}
              required
            />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <FormControlLabel
              control={
                <Switch
                  checked={isInclusive}
                  onChange={(e) => setIsInclusive(e.target.checked)}
                  color="primary"
                />
              }
              label="Tax Inclusive (included in price)"
            />
          </Grid>

          <Grid size={12}>
            <Alert severity="info">
              <Typography variant="body2">
                <strong>Inclusive:</strong> Price already includes tax (common in EU/UK).
                <br />
                <strong>Exclusive:</strong> Tax added on top of price (common in US/India).
              </Typography>
            </Alert>
          </Grid>
        </Grid>
      </DialogContent>

      <DialogActions sx={{ p: 2 }}>
        <Button onClick={onClose} disabled={loading}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={!canSubmit || loading}
          startIcon={loading ? <CircularProgress size={20} /> : undefined}
        >
          {editRule ? 'Update' : 'Add Tax Rule'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Main Component ─────────────────────────────────────────

const TaxRulesSettings: React.FC = () => {
  const theme = useTheme();
  const toast = useToast();
  const dk = theme.palette.mode === 'dark';

  const [rules, setRules] = useState<TaxRuleDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showInactive, setShowInactive] = useState(false);

  // Dialogs
  const [formOpen, setFormOpen] = useState(false);
  const [editRule, setEditRule] = useState<TaxRuleDto | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [ruleToDelete, setRuleToDelete] = useState<TaxRuleDto | null>(null);

  // ─── Data Loading ───────────────────────────────────────

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const data = await getTaxRules({ activeOnly: !showInactive });
      setRules(data);
    } catch (err) {
      toast.error('Failed to load tax rules');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [toast, showInactive]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // ─── Handlers ───────────────────────────────────────────

  const handleAdd = () => {
    setEditRule(null);
    setFormOpen(true);
  };

  const handleEdit = (rule: TaxRuleDto) => {
    setEditRule(rule);
    setFormOpen(true);
  };

  const handleSave = async (data: CreateTaxRuleRequest | UpdateTaxRuleRequest, id?: string) => {
    try {
      setSaving(true);
      if (id) {
        await updateTaxRule(id, data as UpdateTaxRuleRequest);
        toast.success('Tax rule updated successfully');
      } else {
        await createTaxRule(data as CreateTaxRuleRequest);
        toast.success('Tax rule added successfully');
      }
      setFormOpen(false);
      loadData();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to save tax rule');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!ruleToDelete) return;
    try {
      setSaving(true);
      await deactivateTaxRule(ruleToDelete.id);
      toast.success('Tax rule deactivated');
      setDeleteDialogOpen(false);
      setRuleToDelete(null);
      loadData();
    } catch (err) {
      toast.error('Failed to deactivate tax rule');
    } finally {
      setSaving(false);
    }
  };

  const handleActivate = async (rule: TaxRuleDto) => {
    try {
      await activateTaxRule(rule.id);
      toast.success('Tax rule activated');
      loadData();
    } catch (err) {
      toast.error('Failed to activate tax rule');
    }
  };

  // ─── Group rules by country ─────────────────────────────

  const rulesByCountry = rules.reduce((acc, rule) => {
    if (!acc[rule.countryCode]) {
      acc[rule.countryCode] = [];
    }
    acc[rule.countryCode].push(rule);
    return acc;
  }, {} as Record<string, TaxRuleDto[]>);

  // ─── Render ─────────────────────────────────────────────

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight={400}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box p={3}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight={700}>
            Tax Rules
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Configure tax rates for different regions
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <FormControlLabel
            control={
              <Switch
                checked={showInactive}
                onChange={(e) => setShowInactive(e.target.checked)}
                size="small"
              />
            }
            label="Show Inactive"
          />
          <Button startIcon={<Refresh />} onClick={loadData} variant="outlined">
            Refresh
          </Button>
          <Button startIcon={<Add />} variant="contained" onClick={handleAdd}>
            Add Tax Rule
          </Button>
        </Stack>
      </Stack>

      {/* No Rules Alert */}
      {rules.length === 0 && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography fontWeight={600}>No tax rules configured</Typography>
          <Typography variant="body2">
            Add tax rules for the countries where you operate to ensure correct tax calculations.
          </Typography>
        </Alert>
      )}

      {/* Rules by Country */}
      {Object.entries(rulesByCountry).map(([countryCode, countryRules]) => (
        <Card key={countryCode} sx={{ mb: 3 }}>
          <CardContent>
            <Stack direction="row" spacing={2} alignItems="center" mb={2}>
              <Public color="primary" />
              <Typography variant="h6" fontWeight={600}>
                {getCountryLabel(countryCode)}
              </Typography>
              <Chip label={`${countryRules.length} rule(s)`} size="small" />
            </Stack>

            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Tax Name</TableCell>
                    <TableCell align="right">Rate</TableCell>
                    <TableCell align="center">Type</TableCell>
                    <TableCell align="center">Status</TableCell>
                    <TableCell align="right">Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {countryRules.map((rule) => (
                    <TableRow
                      key={rule.id}
                      sx={{ opacity: rule.isActive ? 1 : 0.5 }}
                    >
                      <TableCell>
                        <Typography fontWeight={500}>{rule.name}</Typography>
                      </TableCell>
                      <TableCell align="right">
                        <Stack direction="row" spacing={0.5} alignItems="center" justifyContent="flex-end">
                          <Percent sx={{ fontSize: 16, color: 'text.secondary' }} />
                          <Typography fontWeight={600}>{rule.rate.toFixed(2)}</Typography>
                        </Stack>
                      </TableCell>
                      <TableCell align="center">
                        <Chip
                          label={rule.isInclusive ? 'Inclusive' : 'Exclusive'}
                          size="small"
                          color={rule.isInclusive ? 'info' : 'default'}
                          variant="outlined"
                        />
                      </TableCell>
                      <TableCell align="center">
                        {rule.isActive ? (
                          <Chip
                            icon={<CheckCircle sx={{ fontSize: 16 }} />}
                            label="Active"
                            size="small"
                            color="success"
                          />
                        ) : (
                          <Chip
                            icon={<Cancel sx={{ fontSize: 16 }} />}
                            label="Inactive"
                            size="small"
                            color="default"
                          />
                        )}
                      </TableCell>
                      <TableCell align="right">
                        <Stack direction="row" spacing={0.5} justifyContent="flex-end">
                          {!rule.isActive && (
                            <Tooltip title="Activate">
                              <IconButton
                                size="small"
                                color="success"
                                onClick={() => handleActivate(rule)}
                              >
                                <CheckCircle />
                              </IconButton>
                            </Tooltip>
                          )}
                          <Tooltip title="Edit">
                            <IconButton size="small" onClick={() => handleEdit(rule)}>
                              <Edit />
                            </IconButton>
                          </Tooltip>
                          {rule.isActive && (
                            <Tooltip title="Deactivate">
                              <IconButton
                                size="small"
                                color="error"
                                onClick={() => {
                                  setRuleToDelete(rule);
                                  setDeleteDialogOpen(true);
                                }}
                              >
                                <Delete />
                              </IconButton>
                            </Tooltip>
                          )}
                        </Stack>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </CardContent>
        </Card>
      ))}

      {/* Form Dialog */}
      <TaxRuleFormDialog
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSave={handleSave}
        editRule={editRule}
        loading={saving}
      />

      {/* Delete Confirmation */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Deactivate Tax Rule</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            This will deactivate the tax rule. You can reactivate it later.
          </Alert>
          <Typography>
            Are you sure you want to deactivate <strong>{ruleToDelete?.name}</strong>?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)} disabled={saving}>
            Cancel
          </Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleDelete}
            disabled={saving}
            startIcon={saving ? <CircularProgress size={20} /> : <Delete />}
          >
            Deactivate
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default TaxRulesSettings;
