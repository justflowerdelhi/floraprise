import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Tabs,
  Tab,
  Switch,
  TextField,
  Button,
  RadioGroup,
  FormControlLabel,
  Radio,
  Chip,
  Divider,
  Alert,
  IconButton,
  InputAdornment,
  MenuItem,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Payments,
  QrCode,
  CreditCard,
  Language,
  CheckCircle,
  Error as ErrorIcon,
  ContentCopy,
  Visibility,
  VisibilityOff,
  Tune,
  PlayArrow,
  Storefront,
} from '@mui/icons-material';
import QRCode from 'qrcode';
import {
  type PaymentGatewayConfig,
  getPaymentGatewayConfigs,
  createPaymentGatewayConfig,
  updatePaymentGatewayConfig,
  deletePaymentGatewayConfig,
  testPaymentGatewayConnection,
} from '../../api/payment-gateway.api';
import PaymentGatewaySettings from './PaymentGatewaySettings';
import { useToast } from '../../hooks/useToast';

const LOCAL_STORAGE_KEYS = {
  CASH_ENABLED: 'floraprise_payment_cash_enabled',
  UPI_ENABLED: 'floraprise_payment_upi_enabled',
  UPI_ID: 'floraprise_payment_upi_id',
  UPI_NAME: 'floraprise_payment_upi_name',
  CARD_ENABLED: 'floraprise_payment_card_enabled',
  HAS_CARD_MACHINE: 'floraprise_payment_has_card_machine',
  CARD_TERMINAL_ID: 'floraprise_payment_card_terminal_id',
};

const PaymentSettingsPage: React.FC = () => {
  const { showSuccess, showError } = useToast();
  const [activeTab, setActiveTab] = useState<number>(0);

  // Florist Settings State
  const [cashEnabled, setCashEnabled] = useState<boolean>(true);
  const [upiEnabled, setUpiEnabled] = useState<boolean>(true);
  const [upiId, setUpiId] = useState<string>('');
  const [upiName, setUpiName] = useState<string>('');
  const [qrDataUrl, setQrDataUrl] = useState<string>('');
  const [qrModalOpen, setQrModalOpen] = useState<boolean>(false);

  const [cardEnabled, setCardEnabled] = useState<boolean>(true);
  const [hasCardMachine, setHasCardMachine] = useState<boolean>(false);
  const [cardTerminalId, setCardTerminalId] = useState<string>('');

  // Online Gateway State
  const [gateways, setGateways] = useState<PaymentGatewayConfig[]>([]);
  const [loadingGateways, setLoadingGateways] = useState<boolean>(false);
  const [selectedProvider, setSelectedProvider] = useState<'Razorpay' | 'PayU' | 'Cashfree'>('Razorpay');
  const [gatewayEnv, setGatewayEnv] = useState<'Production' | 'Sandbox'>('Production');
  const [keyId, setKeyId] = useState<string>('');
  const [keySecret, setKeySecret] = useState<string>('');
  const [showSecret, setShowSecret] = useState<boolean>(false);
  const [testingGateway, setTestingGateway] = useState<boolean>(false);
  const [savingGateway, setSavingGateway] = useState<boolean>(false);

  // Load settings on mount
  useEffect(() => {
    // Load local storage values
    setCashEnabled(localStorage.getItem(LOCAL_STORAGE_KEYS.CASH_ENABLED) !== 'false');
    setUpiEnabled(localStorage.getItem(LOCAL_STORAGE_KEYS.UPI_ENABLED) !== 'false');
    const savedUpiId = localStorage.getItem(LOCAL_STORAGE_KEYS.UPI_ID) || '';
    const savedUpiName = localStorage.getItem(LOCAL_STORAGE_KEYS.UPI_NAME) || 'Floraprise Boutique';
    setUpiId(savedUpiId);
    setUpiName(savedUpiName);

    setCardEnabled(localStorage.getItem(LOCAL_STORAGE_KEYS.CARD_ENABLED) !== 'false');
    setHasCardMachine(localStorage.getItem(LOCAL_STORAGE_KEYS.HAS_CARD_MACHINE) === 'true');
    setCardTerminalId(localStorage.getItem(LOCAL_STORAGE_KEYS.CARD_TERMINAL_ID) || '');

    // Generate QR if UPI ID exists
    if (savedUpiId.trim()) {
      generateQr(savedUpiId, savedUpiName);
    }

    loadGateways();
  }, []);

  const loadGateways = async () => {
    setLoadingGateways(true);
    try {
      const data = await getPaymentGatewayConfigs();
      setGateways(data);
      if (data.length > 0) {
        const defaultGw = data.find((g) => g.isDefault || g.isActive) || data[0];
        if (defaultGw.gatewayType === 'Razorpay' || defaultGw.gatewayType === 'PayU' || defaultGw.gatewayType === 'Cashfree') {
          setSelectedProvider(defaultGw.gatewayType);
        }
        setGatewayEnv(defaultGw.environment);
        setKeyId(defaultGw.publicKey);
      }
    } catch {
      // Ignored if unconfigured
    } finally {
      setLoadingGateways(false);
    }
  };

  const generateQr = async (vpa: string, name: string) => {
    if (!vpa.trim()) {
      setQrDataUrl('');
      return;
    }
    const upiUri = `upi://pay?pa=${encodeURIComponent(vpa.trim())}&pn=${encodeURIComponent(name.trim() || 'Florist')}&cu=INR`;
    try {
      const url = await QRCode.toDataURL(upiUri, { width: 300, margin: 1 });
      setQrDataUrl(url);
    } catch {
      setQrDataUrl('');
    }
  };

  const handleSaveLocalSettings = () => {
    localStorage.setItem(LOCAL_STORAGE_KEYS.CASH_ENABLED, cashEnabled.toString());
    localStorage.setItem(LOCAL_STORAGE_KEYS.UPI_ENABLED, upiEnabled.toString());
    localStorage.setItem(LOCAL_STORAGE_KEYS.UPI_ID, upiId.trim());
    localStorage.setItem(LOCAL_STORAGE_KEYS.UPI_NAME, upiName.trim());
    localStorage.setItem(LOCAL_STORAGE_KEYS.CARD_ENABLED, cardEnabled.toString());
    localStorage.setItem(LOCAL_STORAGE_KEYS.HAS_CARD_MACHINE, hasCardMachine.toString());
    localStorage.setItem(LOCAL_STORAGE_KEYS.CARD_TERMINAL_ID, cardTerminalId.trim());

    if (upiId.trim()) {
      generateQr(upiId, upiName);
    }

    showSuccess('Payment method settings saved successfully!');
  };

  const activeOnlineConfig = gateways.find(
    (g) => g.gatewayType === selectedProvider && g.isActive
  ) || gateways.find((g) => g.gatewayType === selectedProvider);

  const handleSaveGateway = async () => {
    if (!keyId.trim()) {
      showError('Please enter a Key ID / Client ID');
      return;
    }

    setSavingGateway(true);
    try {
      if (activeOnlineConfig) {
        await updatePaymentGatewayConfig(activeOnlineConfig.id, {
          name: `${selectedProvider} Gateway`,
          publicKey: keyId.trim(),
          secretKey: keySecret.trim() ? keySecret.trim() : undefined,
          environment: gatewayEnv,
          isActive: true,
          isDefault: true,
        });
        showSuccess(`${selectedProvider} updated successfully`);
      } else {
        if (!keySecret.trim()) {
          showError('Please enter the Key Secret for initial setup');
          setSavingGateway(false);
          return;
        }
        await createPaymentGatewayConfig({
          gatewayType: selectedProvider,
          name: `${selectedProvider} Gateway`,
          publicKey: keyId.trim(),
          secretKey: keySecret.trim(),
          environment: gatewayEnv,
          currency: 'INR',
          isDefault: true,
        });
        showSuccess(`${selectedProvider} connected successfully`);
      }
      setKeySecret('');
      await loadGateways();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to save gateway configuration';
      showError(msg);
    } finally {
      setSavingGateway(false);
    }
  };

  const handleTestGateway = async () => {
    if (!activeOnlineConfig) {
      showError('Please save the gateway configuration before testing');
      return;
    }

    setTestingGateway(true);
    try {
      const res = await testPaymentGatewayConnection(activeOnlineConfig.id);
      if (res.success) {
        showSuccess('Connection successful! Online payment gateway is ready.');
      } else {
        showError(`Connection test failed: ${res.message}`);
      }
      await loadGateways();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Connection test failed';
      showError(msg);
    } finally {
      setTestingGateway(false);
    }
  };

  const handleDisconnectGateway = async () => {
    if (!activeOnlineConfig) return;
    try {
      await deletePaymentGatewayConfig(activeOnlineConfig.id);
      setKeyId('');
      setKeySecret('');
      showSuccess(`${selectedProvider} disconnected`);
      await loadGateways();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to disconnect gateway';
      showError(msg);
    }
  };

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1200, mx: 'auto' }}>
      {/* Page Title & Navigation Tabs */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700} gutterBottom>
          Payment Settings
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Configure counter payment methods, UPI QR codes, card swipe machines, and online payment gateways.
        </Typography>

        <Box sx={{ borderBottom: 1, borderColor: 'divider', mt: 2 }}>
          <Tabs value={activeTab} onChange={(_, val) => setActiveTab(val)}>
            <Tab icon={<Storefront fontSize="small" />} iconPosition="start" label="Florist Payment Methods" />
            <Tab icon={<Tune fontSize="small" />} iconPosition="start" label="Advanced Gateway Settings" />
          </Tabs>
        </Box>
      </Box>

      {/* TAB 1: Florist Simple View */}
      {activeTab === 0 && (
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
          {/* ── 1. Cash Card ── */}
          <Card variant="outlined" sx={{ borderRadius: 3 }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                  <Box
                    sx={{
                      p: 1.5,
                      borderRadius: 2,
                      bgcolor: 'success.light',
                      color: 'success.dark',
                      display: 'flex',
                    }}
                  >
                    <Payments />
                  </Box>
                  <Box>
                    <Typography variant="subtitle1" fontWeight={700}>
                      Cash Payments
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Accept cash at counter and on home delivery.
                    </Typography>
                  </Box>
                </Box>
                <Switch
                  checked={cashEnabled}
                  onChange={(e) => setCashEnabled(e.target.checked)}
                  color="success"
                />
              </Box>

              {cashEnabled && (
                <Alert severity="info" sx={{ mt: 2, borderRadius: 2 }}>
                  Cash receipts are automatically logged to your <strong>Daily Cash Book</strong> and included in Day Close reports.
                </Alert>
              )}
            </CardContent>
          </Card>

          {/* ── 2. UPI / QR Card ── */}
          <Card variant="outlined" sx={{ borderRadius: 3 }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                  <Box
                    sx={{
                      p: 1.5,
                      borderRadius: 2,
                      bgcolor: 'info.light',
                      color: 'info.dark',
                      display: 'flex',
                    }}
                  >
                    <QrCode />
                  </Box>
                  <Box>
                    <Typography variant="subtitle1" fontWeight={700}>
                      UPI / QR Code
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Instant customer scan-and-pay with Google Pay, PhonePe, Paytm, or BHIM.
                    </Typography>
                  </Box>
                </Box>
                <Switch
                  checked={upiEnabled}
                  onChange={(e) => setUpiEnabled(e.target.checked)}
                  color="info"
                />
              </Box>

              {upiEnabled && (
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
                  <Divider />
                  <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
                    <TextField
                      label="Store UPI ID / VPA"
                      placeholder="e.g. florist@icici or 9876543210@upi"
                      value={upiId}
                      onChange={(e) => {
                        setUpiId(e.target.value);
                        generateQr(e.target.value, upiName);
                      }}
                      helperText="Your shop's bank UPI address"
                      fullWidth
                    />
                    <TextField
                      label="Business / Payee Name"
                      placeholder="e.g. Flora Flower Boutique"
                      value={upiName}
                      onChange={(e) => {
                        setUpiName(e.target.value);
                        generateQr(upiId, e.target.value);
                      }}
                      helperText="Displayed to customer on payment app"
                      fullWidth
                    />
                  </Box>

                  {qrDataUrl && (
                    <Box
                      sx={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 2,
                        p: 2,
                        bgcolor: 'background.default',
                        borderRadius: 2,
                        border: '1px solid',
                        borderColor: 'divider',
                      }}
                    >
                      <Box
                        component="img"
                        src={qrDataUrl}
                        alt="UPI QR Code"
                        sx={{ width: 80, height: 80, borderRadius: 1, border: '1px solid #ddd' }}
                      />
                      <Box sx={{ flex: 1 }}>
                        <Typography variant="subtitle2" fontWeight={700}>
                          Static Store QR Code Ready
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {upiId} ({upiName || 'Florist'})
                        </Typography>
                      </Box>
                      <Button
                        variant="outlined"
                        startIcon={<QrCode />}
                        onClick={() => setQrModalOpen(true)}
                      >
                        Preview & Print QR
                      </Button>
                    </Box>
                  )}
                </Box>
              )}
            </CardContent>
          </Card>

          {/* ── 3. Card Payments & Machine ── */}
          <Card variant="outlined" sx={{ borderRadius: 3 }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                  <Box
                    sx={{
                      p: 1.5,
                      borderRadius: 2,
                      bgcolor: 'secondary.light',
                      color: 'secondary.dark',
                      display: 'flex',
                    }}
                  >
                    <CreditCard />
                  </Box>
                  <Box>
                    <Typography variant="subtitle1" fontWeight={700}>
                      Card Payments
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Accept Debit and Credit cards at counter.
                    </Typography>
                  </Box>
                </Box>
                <Switch
                  checked={cardEnabled}
                  onChange={(e) => setCardEnabled(e.target.checked)}
                  color="secondary"
                />
              </Box>

              {cardEnabled && (
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <Divider />
                  <Typography variant="subtitle2" fontWeight={600}>
                    Card Swipe Machine Mode:
                  </Typography>

                  <RadioGroup
                    value={hasCardMachine ? 'machine' : 'manual'}
                    onChange={(e) => setHasCardMachine(e.target.value === 'machine')}
                  >
                    <FormControlLabel
                      value="machine"
                      control={<Radio size="small" />}
                      label={
                        <Box>
                          <Typography variant="body2" fontWeight={600}>
                            I have a physical card machine / swipe terminal (EDC)
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            Allows recording Terminal ID, Card Brand (Visa, MC, RuPay), and approval reference code.
                          </Typography>
                        </Box>
                      }
                    />
                    <FormControlLabel
                      value="manual"
                      control={<Radio size="small" />}
                      label={
                        <Box>
                          <Typography variant="body2" fontWeight={600}>
                            I don't have a dedicated card machine
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            Simple card payment recording without terminal details.
                          </Typography>
                        </Box>
                      }
                    />
                  </RadioGroup>

                  {hasCardMachine && (
                    <TextField
                      label="Default Terminal Name / Identifier"
                      placeholder="e.g. Counter 1 - HDFC EDC, Pine Labs 01"
                      value={cardTerminalId}
                      onChange={(e) => setCardTerminalId(e.target.value)}
                      helperText="Auto-populated during POS card checkout"
                      sx={{ maxWidth: 400 }}
                    />
                  )}
                </Box>
              )}
            </CardContent>
          </Card>

          {/* ── Save Local Buttons ── */}
          <Box sx={{ display: 'flex', justifyContent: 'flex-start' }}>
            <Button
              variant="contained"
              size="large"
              onClick={handleSaveLocalSettings}
              sx={{ px: 4, py: 1.2, borderRadius: 2 }}
            >
              Save Counter Payment Settings
            </Button>
          </Box>

          {/* ── 4. Online Payment Gateway (Cloud) ── */}
          <Card variant="outlined" sx={{ borderRadius: 3, mt: 1 }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                  <Box
                    sx={{
                      p: 1.5,
                      borderRadius: 2,
                      bgcolor: 'primary.light',
                      color: 'primary.dark',
                      display: 'flex',
                    }}
                  >
                    <Language />
                  </Box>
                  <Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Typography variant="subtitle1" fontWeight={700}>
                        Online Payment Gateway
                      </Typography>
                      {activeOnlineConfig ? (
                        <Chip
                          size="small"
                          color={activeOnlineConfig.lastTestSuccessful === false ? 'error' : 'success'}
                          icon={activeOnlineConfig.lastTestSuccessful === false ? <ErrorIcon /> : <CheckCircle />}
                          label={activeOnlineConfig.lastTestSuccessful === false ? 'Connection Error' : 'Connected'}
                        />
                      ) : (
                        <Chip size="small" variant="outlined" label="Not Connected" />
                      )}
                    </Box>
                    <Typography variant="body2" color="text.secondary">
                      Accept online customer payments via Razorpay, PayU, or Cashfree.
                    </Typography>
                  </Box>
                </Box>
              </Box>

              <Divider sx={{ my: 2 }} />

              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
                <TextField
                  select
                  label="Online Provider"
                  value={selectedProvider}
                  onChange={(e) => setSelectedProvider(e.target.value as 'Razorpay' | 'PayU' | 'Cashfree')}
                  fullWidth
                >
                  <MenuItem value="Razorpay">Razorpay (India - Cards, UPI, NetBanking)</MenuItem>
                  <MenuItem value="PayU">PayU (India - Cards, UPI, NetBanking)</MenuItem>
                  <MenuItem value="Cashfree">Cashfree (India - Cards, UPI, NetBanking)</MenuItem>
                </TextField>

                <TextField
                  select
                  label="Environment"
                  value={gatewayEnv}
                  onChange={(e) => setGatewayEnv(e.target.value as 'Production' | 'Sandbox')}
                  fullWidth
                >
                  <MenuItem value="Production">Live / Production</MenuItem>
                  <MenuItem value="Sandbox">Test / Sandbox</MenuItem>
                </TextField>

                <TextField
                  label="Key ID / Client ID"
                  placeholder={selectedProvider === 'Razorpay' ? 'rzp_live_...' : 'API Key ID'}
                  value={keyId}
                  onChange={(e) => setKeyId(e.target.value)}
                  fullWidth
                />

                <TextField
                  label="Key Secret"
                  type={showSecret ? 'text' : 'password'}
                  placeholder={activeOnlineConfig ? '•••••••• (Leave blank to keep current)' : 'Enter Secret Key'}
                  value={keySecret}
                  onChange={(e) => setKeySecret(e.target.value)}
                  InputProps={{
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton onClick={() => setShowSecret(!showSecret)} edge="end">
                          {showSecret ? <VisibilityOff /> : <Visibility />}
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                  helperText="Never shared with customers; stored securely encrypted."
                  fullWidth
                />
              </Box>

              {activeOnlineConfig?.webhookUrl && (
                <Box
                  sx={{
                    mt: 2,
                    p: 1.5,
                    bgcolor: 'grey.50',
                    borderRadius: 2,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                  }}
                >
                  <Box>
                    <Typography variant="caption" fontWeight={700} color="text.secondary">
                      WEBHOOK NOTIFICATION URL:
                    </Typography>
                    <Typography variant="body2" fontFamily="monospace">
                      {activeOnlineConfig.webhookUrl}
                    </Typography>
                  </Box>
                  <IconButton
                    size="small"
                    onClick={() => {
                      navigator.clipboard.writeText(activeOnlineConfig.webhookUrl || '');
                      showSuccess('Webhook URL copied');
                    }}
                  >
                    <ContentCopy fontSize="small" />
                  </IconButton>
                </Box>
              )}

              <Box sx={{ mt: 3, display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
                <Button
                  variant="contained"
                  color="primary"
                  onClick={handleSaveGateway}
                  disabled={savingGateway || loadingGateways}
                  startIcon={savingGateway ? <CircularProgress size={16} color="inherit" /> : undefined}
                >
                  {activeOnlineConfig ? 'Update Online Gateway' : 'Connect Online Gateway'}
                </Button>

                {activeOnlineConfig && (
                  <>
                    <Button
                      variant="outlined"
                      color="secondary"
                      onClick={handleTestGateway}
                      disabled={testingGateway}
                      startIcon={testingGateway ? <CircularProgress size={16} /> : <PlayArrow />}
                    >
                      Test Connection
                    </Button>

                    <Button
                      variant="text"
                      color="error"
                      onClick={handleDisconnectGateway}
                    >
                      Disconnect
                    </Button>
                  </>
                )}
              </Box>
            </CardContent>
          </Card>
        </Box>
      )}

      {/* TAB 2: Advanced Technical Configuration */}
      {activeTab === 1 && (
        <Box>
          <PaymentGatewaySettings />
        </Box>
      )}

      {/* QR Code Dialog */}
      <Dialog open={qrModalOpen} onClose={() => setQrModalOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ textAlign: 'center', fontWeight: 700 }}>
          Store UPI QR Code
        </DialogTitle>
        <DialogContent sx={{ textAlign: 'center', py: 2 }}>
          {qrDataUrl && (
            <Box
              component="img"
              src={qrDataUrl}
              alt="Store QR Code"
              sx={{ width: 240, height: 240, mx: 'auto', display: 'block', mb: 2 }}
            />
          )}
          <Typography variant="subtitle1" fontWeight={700}>
            {upiName || 'Florist'}
          </Typography>
          <Typography variant="body2" color="text.secondary" gutterBottom>
            {upiId}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Scan with Google Pay, PhonePe, Paytm, BHIM, or any UPI banking app.
          </Typography>
        </DialogContent>
        <DialogActions sx={{ justifyContent: 'center', pb: 2 }}>
          <Button
            variant="outlined"
            onClick={() => {
              const upiUri = `upi://pay?pa=${encodeURIComponent(upiId)}&pn=${encodeURIComponent(upiName)}&cu=INR`;
              navigator.clipboard.writeText(upiUri);
              showSuccess('UPI link copied');
            }}
          >
            Copy Link
          </Button>
          <Button variant="contained" onClick={() => setQrModalOpen(false)}>
            Close
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default PaymentSettingsPage;
