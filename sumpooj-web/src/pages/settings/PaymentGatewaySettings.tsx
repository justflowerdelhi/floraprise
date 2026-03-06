/**
 * PaymentGatewaySettings.tsx — Payment Gateway Configuration UI
 *
 * Features:
 * - List all configured payment gateways
 * - Add new gateway with type-specific fields
 * - Test gateway connection
 * - Enable/disable gateways
 * - Set default gateway
 * - Delete gateways
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
  Collapse,
  LinearProgress,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  PlayArrow,
  CheckCircle,
  Error,
  Warning,
  CreditCard,
  Settings,
  Visibility,
  VisibilityOff,
  Star,
  StarBorder,
  Refresh,
  OpenInNew,
  ContentCopy,
  Info,
} from '@mui/icons-material';
import {
  type PaymentGatewayConfig,
  type PaymentGatewayInfo,
  type PaymentGatewayConfigCreate,
  type PaymentGatewayConfigUpdate,
  type PaymentGatewayType,
  type GatewayEnvironment,
  getAvailableGateways,
  getPaymentGatewayConfigs,
  createPaymentGatewayConfig,
  updatePaymentGatewayConfig,
  deletePaymentGatewayConfig,
  testPaymentGatewayConnection,
} from '../../api/payment-gateway.api';
import { useToast } from '../../hooks/useToast';

// ─── Gateway Brand Colors & Logos ───────────────────────────

const GATEWAY_BRAND: Record<PaymentGatewayType, { color: string; bg: string; logo?: string }> = {
  Razorpay: { color: '#0066FF', bg: '#E6F0FF' },
  PayU: { color: '#00C26A', bg: '#E6F9F0' },
  Cashfree: { color: '#7F3DFF', bg: '#F0E6FF' },
  Stripe: { color: '#635BFF', bg: '#EDEDFF' },
  Square: { color: '#000000', bg: '#F5F5F5' },
  PayPal: { color: '#003087', bg: '#E6ECFF' },
  PayTabs: { color: '#00A4EF', bg: '#E6F6FF' },
  HyperPay: { color: '#FF6600', bg: '#FFF0E6' },
  TapPayments: { color: '#2ACE80', bg: '#E6FFF2' },
  CheckoutCom: { color: '#0052FF', bg: '#E6EDFF' },
};

const REGION_LABELS: Record<string, string> = {
  IN: '🇮🇳 India',
  US: '🇺🇸 United States',
  GCC: '🇦🇪 GCC / Middle East',
};

// ─── Gateway Card Component ─────────────────────────────────

interface GatewayCardProps {
  config: PaymentGatewayConfig;
  gatewayInfo?: PaymentGatewayInfo;
  onEdit: () => void;
  onDelete: () => void;
  onTest: () => void;
  onToggleActive: () => void;
  onSetDefault: () => void;
  isTesting: boolean;
}

const GatewayCard: React.FC<GatewayCardProps> = ({
  config,
  gatewayInfo,
  onEdit,
  onDelete,
  onTest,
  onToggleActive,
  onSetDefault,
  isTesting,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const brand = GATEWAY_BRAND[config.gatewayType] || { color: '#666', bg: '#f5f5f5' };

  return (
    <Card
      sx={{
        position: 'relative',
        border: `2px solid ${config.isDefault ? brand.color : 'transparent'}`,
        opacity: config.isActive ? 1 : 0.6,
        transition: 'all 0.2s',
        '&:hover': {
          boxShadow: 4,
        },
      }}
    >
      {/* Default Badge */}
      {config.isDefault && (
        <Chip
          icon={<Star sx={{ fontSize: 16 }} />}
          label="DEFAULT"
          size="small"
          sx={{
            position: 'absolute',
            top: 8,
            right: 8,
            bgcolor: brand.color,
            color: 'white',
            fontWeight: 600,
            fontSize: '0.7rem',
          }}
        />
      )}

      <CardContent>
        {/* Header */}
        <Stack direction="row" spacing={2} alignItems="center" mb={2}>
          <Box
            sx={{
              width: 48,
              height: 48,
              borderRadius: 2,
              bgcolor: dk ? alpha(brand.color, 0.2) : brand.bg,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <CreditCard sx={{ color: brand.color, fontSize: 28 }} />
          </Box>
          <Box flex={1}>
            <Typography variant="h6" fontWeight={700}>
              {config.name}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {config.gatewayTypeName}
            </Typography>
          </Box>
        </Stack>

        {/* Details */}
        <Stack spacing={1} mb={2}>
          <Stack direction="row" spacing={1} alignItems="center">
            <Chip
              label={config.environmentName}
              size="small"
              color={config.environment === 'Production' ? 'success' : 'warning'}
              variant="outlined"
            />
            <Chip label={config.currency} size="small" variant="outlined" />
            <Chip
              label={REGION_LABELS[config.region] || config.region}
              size="small"
              variant="outlined"
            />
          </Stack>

          {/* Test Status */}
          {config.lastTestedAt && (
            <Stack direction="row" spacing={0.5} alignItems="center">
              {config.lastTestSuccessful ? (
                <CheckCircle sx={{ fontSize: 16, color: 'success.main' }} />
              ) : (
                <Error sx={{ fontSize: 16, color: 'error.main' }} />
              )}
              <Typography variant="caption" color="text.secondary">
                Last tested: {new Date(config.lastTestedAt).toLocaleString()}
              </Typography>
            </Stack>
          )}
        </Stack>

        <Divider sx={{ my: 1.5 }} />

        {/* Actions */}
        <Stack direction="row" justifyContent="space-between" alignItems="center">
          <FormControlLabel
            control={
              <Switch
                checked={config.isActive}
                onChange={onToggleActive}
                size="small"
                color="success"
              />
            }
            label={config.isActive ? 'Active' : 'Inactive'}
          />

          <Stack direction="row" spacing={0.5}>
            {!config.isDefault && config.isActive && (
              <Tooltip title="Set as Default">
                <IconButton size="small" onClick={onSetDefault}>
                  <StarBorder />
                </IconButton>
              </Tooltip>
            )}
            <Tooltip title="Test Connection">
              <span>
                <IconButton size="small" onClick={onTest} disabled={isTesting}>
                  {isTesting ? <CircularProgress size={20} /> : <PlayArrow />}
                </IconButton>
              </span>
            </Tooltip>
            <Tooltip title="Edit">
              <IconButton size="small" onClick={onEdit}>
                <Edit />
              </IconButton>
            </Tooltip>
            <Tooltip title="Delete">
              <IconButton size="small" color="error" onClick={onDelete}>
                <Delete />
              </IconButton>
            </Tooltip>
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
};

// ─── Gateway Form Dialog ────────────────────────────────────

interface GatewayFormProps {
  open: boolean;
  onClose: () => void;
  onSave: (data: PaymentGatewayConfigCreate | PaymentGatewayConfigUpdate, id?: string) => void;
  editConfig?: PaymentGatewayConfig | null;
  availableGateways: PaymentGatewayInfo[];
  loading?: boolean;
}

const GatewayFormDialog: React.FC<GatewayFormProps> = ({
  open,
  onClose,
  onSave,
  editConfig,
  availableGateways,
  loading,
}) => {
  const [gatewayType, setGatewayType] = useState<PaymentGatewayType | ''>('');
  const [name, setName] = useState('');
  const [publicKey, setPublicKey] = useState('');
  const [secretKey, setSecretKey] = useState('');
  const [webhookSecret, setWebhookSecret] = useState('');
  const [merchantId, setMerchantId] = useState('');
  const [environment, setEnvironment] = useState<GatewayEnvironment>('Sandbox');
  const [currency, setCurrency] = useState('');
  const [isDefault, setIsDefault] = useState(false);
  const [showSecrets, setShowSecrets] = useState(false);

  const selectedGateway = availableGateways.find((g) => g.type === gatewayType);

  // Reset form when dialog opens
  useEffect(() => {
    if (open) {
      if (editConfig) {
        setGatewayType(editConfig.gatewayType);
        setName(editConfig.name);
        setPublicKey(editConfig.publicKey);
        setSecretKey('');
        setWebhookSecret('');
        setMerchantId(editConfig.merchantId || '');
        setEnvironment(editConfig.environment);
        setCurrency(editConfig.currency);
        setIsDefault(editConfig.isDefault);
      } else {
        setGatewayType('');
        setName('');
        setPublicKey('');
        setSecretKey('');
        setWebhookSecret('');
        setMerchantId('');
        setEnvironment('Sandbox');
        setCurrency('');
        setIsDefault(false);
      }
      setShowSecrets(false);
    }
  }, [open, editConfig]);

  // Auto-set currency when gateway is selected
  useEffect(() => {
    if (selectedGateway && !editConfig && selectedGateway.supportedCurrencies.length > 0) {
      setCurrency(selectedGateway.supportedCurrencies[0]);
    }
  }, [selectedGateway, editConfig]);

  const handleSubmit = () => {
    if (editConfig) {
      const update: PaymentGatewayConfigUpdate = {
        name,
        ...(publicKey && { publicKey }),
        ...(secretKey && { secretKey }),
        ...(webhookSecret && { webhookSecret }),
        merchantId: merchantId || undefined,
        environment,
        currency,
        isDefault,
      };
      onSave(update, editConfig.id);
    } else {
      if (!gatewayType) return;
      const create: PaymentGatewayConfigCreate = {
        gatewayType: gatewayType as PaymentGatewayType,
        name,
        publicKey,
        secretKey,
        webhookSecret: webhookSecret || undefined,
        merchantId: merchantId || undefined,
        environment,
        currency,
        isDefault,
      };
      onSave(create);
    }
  };

  const canSubmit =
    name.trim() &&
    (editConfig || gatewayType) &&
    currency &&
    (editConfig || (publicKey && secretKey)) &&
    (!selectedGateway?.requiresMerchantId || merchantId);

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Stack direction="row" spacing={1} alignItems="center">
          <CreditCard />
          <Typography variant="h6">
            {editConfig ? 'Edit Payment Gateway' : 'Add Payment Gateway'}
          </Typography>
        </Stack>
      </DialogTitle>

      <DialogContent dividers>
        <Grid container spacing={3}>
          {/* Gateway Type Selection */}
          {!editConfig && (
            <Grid size={12}>
              <FormControl fullWidth>
                <InputLabel>Gateway Provider</InputLabel>
                <Select
                  value={gatewayType}
                  onChange={(e) => setGatewayType(e.target.value as PaymentGatewayType)}
                  label="Gateway Provider"
                >
                  {availableGateways.map((g) => (
                    <MenuItem key={g.type} value={g.type}>
                      <Stack direction="row" spacing={2} alignItems="center">
                        <Box
                          sx={{
                            width: 24,
                            height: 24,
                            borderRadius: 1,
                            bgcolor: GATEWAY_BRAND[g.type]?.bg || '#f5f5f5',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                          }}
                        >
                          <CreditCard
                            sx={{ fontSize: 16, color: GATEWAY_BRAND[g.type]?.color || '#666' }}
                          />
                        </Box>
                        <Box>
                          <Typography fontWeight={600}>{g.name}</Typography>
                          <Typography variant="caption" color="text.secondary">
                            {REGION_LABELS[g.region] || g.region} • {g.supportedCurrencies.join(', ')}
                          </Typography>
                        </Box>
                      </Stack>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
          )}

          {/* Gateway Info Box */}
          {selectedGateway && (
            <Grid size={12}>
              <Alert
                severity="info"
                icon={<Info />}
                action={
                  <Button
                    size="small"
                    href={selectedGateway.setupDocUrl}
                    target="_blank"
                    endIcon={<OpenInNew />}
                  >
                    Documentation
                  </Button>
                }
              >
                <Typography variant="subtitle2" fontWeight={600}>
                  {selectedGateway.name}
                </Typography>
                <Typography variant="body2">
                  Supported methods: {selectedGateway.supportedPaymentMethods.join(', ')}
                </Typography>
              </Alert>
            </Grid>
          )}

          {/* Display Name */}
          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              fullWidth
              label="Display Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., Main Card Processor"
              required
            />
          </Grid>

          {/* Environment */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormControl fullWidth>
              <InputLabel>Environment</InputLabel>
              <Select
                value={environment}
                onChange={(e) => setEnvironment(e.target.value as GatewayEnvironment)}
                label="Environment"
              >
                <MenuItem value="Sandbox">🧪 Sandbox (Testing)</MenuItem>
                <MenuItem value="Production">🚀 Production (Live)</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          {/* Currency */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormControl fullWidth>
              <InputLabel>Currency</InputLabel>
              <Select value={currency} onChange={(e) => setCurrency(e.target.value)} label="Currency">
                {(selectedGateway?.supportedCurrencies || ['USD', 'INR', 'AED']).map((c) => (
                  <MenuItem key={c} value={c}>
                    {c}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          {/* Merchant ID (if required) */}
          {selectedGateway?.requiresMerchantId && (
            <Grid size={{ xs: 12, md: 6 }}>
              <TextField
                fullWidth
                label="Merchant ID"
                value={merchantId}
                onChange={(e) => setMerchantId(e.target.value)}
                required
              />
            </Grid>
          )}

          <Grid size={12}>
            <Divider>
              <Chip label="API Credentials" size="small" />
            </Divider>
          </Grid>

          {/* Public Key */}
          <Grid size={12}>
            <TextField
              fullWidth
              label={editConfig ? 'Public Key (leave blank to keep existing)' : 'Public Key / Key ID'}
              value={publicKey}
              onChange={(e) => setPublicKey(e.target.value)}
              required={!editConfig}
              placeholder="pk_live_..."
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <Tooltip title="Copy">
                      <IconButton
                        size="small"
                        onClick={() => navigator.clipboard.writeText(publicKey)}
                      >
                        <ContentCopy fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </InputAdornment>
                ),
              }}
            />
          </Grid>

          {/* Secret Key */}
          <Grid size={12}>
            <TextField
              fullWidth
              label={editConfig ? 'Secret Key (leave blank to keep existing)' : 'Secret Key'}
              type={showSecrets ? 'text' : 'password'}
              value={secretKey}
              onChange={(e) => setSecretKey(e.target.value)}
              required={!editConfig}
              placeholder="sk_live_..."
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton size="small" onClick={() => setShowSecrets(!showSecrets)}>
                      {showSecrets ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />
          </Grid>

          {/* Webhook Secret */}
          <Grid size={12}>
            <TextField
              fullWidth
              label="Webhook Secret (optional)"
              type={showSecrets ? 'text' : 'password'}
              value={webhookSecret}
              onChange={(e) => setWebhookSecret(e.target.value)}
              placeholder="whsec_..."
              helperText="Required for secure webhook verification"
            />
          </Grid>

          {/* Default Checkbox */}
          <Grid size={12}>
            <FormControlLabel
              control={
                <Switch
                  checked={isDefault}
                  onChange={(e) => setIsDefault(e.target.checked)}
                  color="primary"
                />
              }
              label="Set as default payment gateway"
            />
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
          {editConfig ? 'Update Gateway' : 'Add Gateway'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Delete Confirmation Dialog ─────────────────────────────

interface DeleteDialogProps {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void;
  gatewayName: string;
  loading?: boolean;
}

const DeleteConfirmDialog: React.FC<DeleteDialogProps> = ({
  open,
  onClose,
  onConfirm,
  gatewayName,
  loading,
}) => (
  <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
    <DialogTitle>Delete Payment Gateway</DialogTitle>
    <DialogContent>
      <Alert severity="warning" sx={{ mb: 2 }}>
        This action cannot be undone.
      </Alert>
      <Typography>
        Are you sure you want to delete <strong>{gatewayName}</strong>?
      </Typography>
    </DialogContent>
    <DialogActions>
      <Button onClick={onClose} disabled={loading}>
        Cancel
      </Button>
      <Button
        variant="contained"
        color="error"
        onClick={onConfirm}
        disabled={loading}
        startIcon={loading ? <CircularProgress size={20} /> : <Delete />}
      >
        Delete
      </Button>
    </DialogActions>
  </Dialog>
);

// ─── Main Component ─────────────────────────────────────────

const PaymentGatewaySettings: React.FC = () => {
  const theme = useTheme();
  const toast = useToast();

  const [configs, setConfigs] = useState<PaymentGatewayConfig[]>([]);
  const [availableGateways, setAvailableGateways] = useState<PaymentGatewayInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [testingId, setTestingId] = useState<string | null>(null);

  // Dialogs
  const [formOpen, setFormOpen] = useState(false);
  const [editConfig, setEditConfig] = useState<PaymentGatewayConfig | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [configToDelete, setConfigToDelete] = useState<PaymentGatewayConfig | null>(null);

  // ─── Data Loading ───────────────────────────────────────

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const [gatewaysRes, configsRes] = await Promise.all([
        getAvailableGateways(),
        getPaymentGatewayConfigs(),
      ]);
      setAvailableGateways(gatewaysRes);
      setConfigs(configsRes);
    } catch (err) {
      toast.error('Failed to load payment gateway configurations');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // ─── Handlers ───────────────────────────────────────────

  const handleAdd = () => {
    setEditConfig(null);
    setFormOpen(true);
  };

  const handleEdit = (config: PaymentGatewayConfig) => {
    setEditConfig(config);
    setFormOpen(true);
  };

  const handleSave = async (
    data: PaymentGatewayConfigCreate | PaymentGatewayConfigUpdate,
    id?: string
  ) => {
    try {
      setSaving(true);
      if (id) {
        await updatePaymentGatewayConfig(id, data as PaymentGatewayConfigUpdate);
        toast.success('Payment gateway updated successfully');
      } else {
        await createPaymentGatewayConfig(data as PaymentGatewayConfigCreate);
        toast.success('Payment gateway added successfully');
      }
      setFormOpen(false);
      loadData();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to save payment gateway');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!configToDelete) return;
    try {
      setSaving(true);
      await deletePaymentGatewayConfig(configToDelete.id);
      toast.success('Payment gateway deleted');
      setDeleteDialogOpen(false);
      setConfigToDelete(null);
      loadData();
    } catch (err) {
      toast.error('Failed to delete payment gateway');
    } finally {
      setSaving(false);
    }
  };

  const handleTest = async (config: PaymentGatewayConfig) => {
    try {
      setTestingId(config.id);
      const result = await testPaymentGatewayConnection(config.id);
      if (result.success) {
        toast.success(`Connection successful: ${result.message}`);
      } else {
        toast.error(`Connection failed: ${result.message}`);
      }
      loadData();
    } catch (err) {
      toast.error('Failed to test connection');
    } finally {
      setTestingId(null);
    }
  };

  const handleToggleActive = async (config: PaymentGatewayConfig) => {
    try {
      await updatePaymentGatewayConfig(config.id, { isActive: !config.isActive });
      toast.success(config.isActive ? 'Gateway disabled' : 'Gateway enabled');
      loadData();
    } catch (err) {
      toast.error('Failed to update gateway status');
    }
  };

  const handleSetDefault = async (config: PaymentGatewayConfig) => {
    try {
      await updatePaymentGatewayConfig(config.id, { isDefault: true });
      toast.success(`${config.name} is now the default gateway`);
      loadData();
    } catch (err) {
      toast.error('Failed to set default gateway');
    }
  };

  // ─── Render ─────────────────────────────────────────────

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight={400}>
        <CircularProgress />
      </Box>
    );
  }

  const activeConfigs = configs.filter((c) => c.isActive);
  const inactiveConfigs = configs.filter((c) => !c.isActive);

  return (
    <Box p={3}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight={700}>
            Payment Gateways
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Configure payment processors for your region
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button startIcon={<Refresh />} onClick={loadData} variant="outlined">
            Refresh
          </Button>
          <Button startIcon={<Add />} variant="contained" onClick={handleAdd}>
            Add Gateway
          </Button>
        </Stack>
      </Stack>

      {/* No Gateways Alert */}
      {configs.length === 0 && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography fontWeight={600}>No payment gateways configured</Typography>
          <Typography variant="body2">
            Add a payment gateway to accept online payments. Choose from providers in your region.
          </Typography>
        </Alert>
      )}

      {/* Active Gateways */}
      {activeConfigs.length > 0 && (
        <Box mb={4}>
          <Typography variant="h6" fontWeight={600} mb={2}>
            Active Gateways ({activeConfigs.length})
          </Typography>
          <Grid container spacing={3}>
            {activeConfigs.map((config) => (
              <Grid key={config.id} size={{ xs: 12, md: 6, lg: 4 }}>
                <GatewayCard
                  config={config}
                  gatewayInfo={availableGateways.find((g) => g.type === config.gatewayType)}
                  onEdit={() => handleEdit(config)}
                  onDelete={() => {
                    setConfigToDelete(config);
                    setDeleteDialogOpen(true);
                  }}
                  onTest={() => handleTest(config)}
                  onToggleActive={() => handleToggleActive(config)}
                  onSetDefault={() => handleSetDefault(config)}
                  isTesting={testingId === config.id}
                />
              </Grid>
            ))}
          </Grid>
        </Box>
      )}

      {/* Inactive Gateways */}
      {inactiveConfigs.length > 0 && (
        <Box>
          <Typography variant="h6" fontWeight={600} mb={2} color="text.secondary">
            Inactive Gateways ({inactiveConfigs.length})
          </Typography>
          <Grid container spacing={3}>
            {inactiveConfigs.map((config) => (
              <Grid key={config.id} size={{ xs: 12, md: 6, lg: 4 }}>
                <GatewayCard
                  config={config}
                  gatewayInfo={availableGateways.find((g) => g.type === config.gatewayType)}
                  onEdit={() => handleEdit(config)}
                  onDelete={() => {
                    setConfigToDelete(config);
                    setDeleteDialogOpen(true);
                  }}
                  onTest={() => handleTest(config)}
                  onToggleActive={() => handleToggleActive(config)}
                  onSetDefault={() => handleSetDefault(config)}
                  isTesting={testingId === config.id}
                />
              </Grid>
            ))}
          </Grid>
        </Box>
      )}

      {/* Available Gateways Info */}
      <Box mt={4}>
        <Divider sx={{ mb: 3 }} />
        <Typography variant="h6" fontWeight={600} mb={2}>
          Available Payment Providers
        </Typography>
        <Grid container spacing={2}>
          {availableGateways.map((gateway) => {
            const isConfigured = configs.some((c) => c.gatewayType === gateway.type);
            const brand = GATEWAY_BRAND[gateway.type];
            return (
              <Grid key={gateway.type} xs={12} sm={6} md={4} lg={3}>
                <Paper
                  variant="outlined"
                  sx={{
                    p: 2,
                    opacity: isConfigured ? 0.7 : 1,
                    border: isConfigured ? '2px solid' : '1px solid',
                    borderColor: isConfigured ? 'success.main' : 'divider',
                  }}
                >
                  <Stack direction="row" spacing={2} alignItems="center">
                    <Box
                      sx={{
                        width: 40,
                        height: 40,
                        borderRadius: 1,
                        bgcolor: brand?.bg || '#f5f5f5',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    >
                      <CreditCard sx={{ color: brand?.color || '#666' }} />
                    </Box>
                    <Box flex={1}>
                      <Stack direction="row" spacing={1} alignItems="center">
                        <Typography fontWeight={600}>{gateway.name}</Typography>
                        {isConfigured && (
                          <CheckCircle sx={{ fontSize: 16, color: 'success.main' }} />
                        )}
                      </Stack>
                      <Typography variant="caption" color="text.secondary">
                        {REGION_LABELS[gateway.region]}
                      </Typography>
                    </Box>
                  </Stack>
                </Paper>
              </Grid>
            );
          })}
        </Grid>
      </Box>

      {/* Form Dialog */}
      <GatewayFormDialog
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSave={handleSave}
        editConfig={editConfig}
        availableGateways={availableGateways}
        loading={saving}
      />

      {/* Delete Confirmation */}
      <DeleteConfirmDialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
        onConfirm={handleDelete}
        gatewayName={configToDelete?.name || ''}
        loading={saving}
      />
    </Box>
  );
};

export default PaymentGatewaySettings;
