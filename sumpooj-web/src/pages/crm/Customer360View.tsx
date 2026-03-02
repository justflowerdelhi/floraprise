// =============================================================================
// CUSTOMER 360 VIEW - Complete Customer Profile Page
// Florist ERP SaaS — CRM & Customer Intelligence
// =============================================================================

import { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Chip,
  Avatar,
  Tabs,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Button,
  Card,
  CardContent,
  Divider,
  LinearProgress,
  Stack,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Tooltip,
  Alert,
  useTheme,
} from '@mui/material';
import {
  Person,
  Phone,
  Email,
  LocationOn,
  Cake,
  Favorite,
  TrendingUp,
  ShoppingCart,
  Event,
  Star,
  Edit,
  LocalOffer,
  CardGiftcard,
  Timeline,
  AttachMoney,
  Loyalty,
  Notes,
  WhatsApp,
  ArrowBack,
  EmojiEvents,
  Warning,
} from '@mui/icons-material';
import type {
  Customer,
  CustomerOrderSummary,
  CustomerEventSummary,
  LoyaltyTransaction,
} from './CRMTypes';
import {
  CUSTOMER_TAGS,
  LOYALTY_TIER_CONFIGS,
  formatCurrency,
  getPointsToNextTier,
  daysSince,
  MOCK_CUSTOMERS,
  MOCK_CUSTOMER_ORDERS,
  MOCK_CUSTOMER_EVENTS,
  MOCK_LOYALTY_TRANSACTIONS,
} from './CRMTypes';
import { updateCustomerNotes } from '../../api/customer.api';

// -----------------------------------------------------------------------------
// Tab Panel Component
// -----------------------------------------------------------------------------

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel({ children, value, index }: TabPanelProps) {
  return (
    <div hidden={value !== index} style={{ paddingTop: 16 }}>
      {value === index && children}
    </div>
  );
}

// -----------------------------------------------------------------------------
// Loyalty Status Card
// -----------------------------------------------------------------------------

interface LoyaltyStatusCardProps {
  customer: Customer;
}

function LoyaltyStatusCard({ customer }: LoyaltyStatusCardProps) {
  const tierConfig = LOYALTY_TIER_CONFIGS[customer.loyaltyTier];
  const pointsToNext = getPointsToNextTier(customer.loyaltyPoints, customer.loyaltyTier);
  const nextTier = customer.loyaltyTier === 'SILVER' ? 'GOLD' : customer.loyaltyTier === 'GOLD' ? 'PLATINUM' : null;
  
  const progressValue = nextTier
    ? (customer.loyaltyPoints / LOYALTY_TIER_CONFIGS[nextTier].minPoints) * 100
    : 100;

  return (
    <Card sx={{ bgcolor: tierConfig.backgroundColor, border: `1px solid ${tierConfig.color}` }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
          <EmojiEvents sx={{ color: tierConfig.color, fontSize: 40 }} />
          <Box>
            <Typography variant="h6" sx={{ color: tierConfig.color, fontWeight: 600 }}>
              {tierConfig.label} Member
            </Typography>
            <Typography variant="body2" sx={{ opacity: 0.8 }}>
              {tierConfig.description}
            </Typography>
          </Box>
        </Box>

        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
          <Typography variant="h4" fontWeight={600}>
            {customer.loyaltyPoints.toLocaleString()}
          </Typography>
          <Typography variant="body2" sx={{ opacity: 0.7, alignSelf: 'flex-end' }}>
            points available
          </Typography>
        </Box>

        {nextTier && pointsToNext !== null && (
          <>
            <LinearProgress
              variant="determinate"
              value={Math.min(progressValue, 100)}
              sx={{
                height: 8,
                borderRadius: 4,
                bgcolor: 'rgba(255,255,255,0.1)',
                '& .MuiLinearProgress-bar': { bgcolor: tierConfig.color },
              }}
            />
            <Typography variant="caption" sx={{ opacity: 0.7, mt: 0.5, display: 'block' }}>
              {pointsToNext.toLocaleString()} points to {nextTier}
            </Typography>
          </>
        )}

        <Divider sx={{ my: 2, borderColor: 'rgba(255,255,255,0.1)' }} />

        <Grid container spacing={2}>
          <Grid size={{ xs: 6 }}>
            <Typography variant="caption" sx={{ opacity: 0.7 }}>Total Earned</Typography>
            <Typography variant="body1" fontWeight={500}>
              {customer.loyaltyPointsEarned.toLocaleString()}
            </Typography>
          </Grid>
          <Grid size={{ xs: 6 }}>
            <Typography variant="caption" sx={{ opacity: 0.7 }}>Redeemed</Typography>
            <Typography variant="body1" fontWeight={500}>
              {customer.loyaltyPointsRedeemed.toLocaleString()}
            </Typography>
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );
}

// -----------------------------------------------------------------------------
// Metric Card
// -----------------------------------------------------------------------------

interface MetricCardProps {
  icon: React.ReactNode;
  label: string;
  value: string | number;
  subValue?: string;
  color?: string;
}

function MetricCard({ icon, label, value, subValue, color = '#fdd835' }: MetricCardProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  return (
    <Paper sx={{ p: 2, bgcolor: dk ? '#1a1a2e' : '#fff' }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
        <Box sx={{ color, opacity: 0.9 }}>{icon}</Box>
        <Box>
          <Typography variant="caption" sx={{ opacity: 0.7, display: 'block' }}>
            {label}
          </Typography>
          <Typography variant="h6" fontWeight={600}>
            {value}
          </Typography>
          {subValue && (
            <Typography variant="caption" sx={{ opacity: 0.6 }}>
              {subValue}
            </Typography>
          )}
        </Box>
      </Box>
    </Paper>
  );
}

// -----------------------------------------------------------------------------
// Orders Tab
// -----------------------------------------------------------------------------

interface OrdersTabProps {
  orders: CustomerOrderSummary[];
}

function OrdersTab({ orders }: OrdersTabProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  return (
    <TableContainer component={Paper} sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>Order #</TableCell>
            <TableCell>Date</TableCell>
            <TableCell>Source</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Payment</TableCell>
            <TableCell align="right">Total</TableCell>
            <TableCell align="right">Profit</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {orders.map((order) => (
            <TableRow key={order.orderId} hover>
              <TableCell>
                <Typography variant="body2" fontWeight={500} sx={{ color: '#90caf9' }}>
                  {order.orderNumber}
                </Typography>
              </TableCell>
              <TableCell>{new Date(order.orderDate).toLocaleDateString()}</TableCell>
              <TableCell>
                <Chip label={order.orderSource} size="small" variant="outlined" />
              </TableCell>
              <TableCell>
                <Chip
                  label={order.fulfillmentStatus}
                  size="small"
                  sx={{
                    bgcolor: order.fulfillmentStatus === 'COMPLETED' ? 'rgba(76,175,80,0.2)' : 'rgba(255,193,7,0.2)',
                    color: order.fulfillmentStatus === 'COMPLETED' ? '#4caf50' : '#ffc107',
                  }}
                />
              </TableCell>
              <TableCell>
                <Chip
                  label={order.paymentStatus}
                  size="small"
                  sx={{
                    bgcolor: order.paymentStatus === 'PAID' ? 'rgba(76,175,80,0.2)' : 'rgba(255,152,0,0.2)',
                    color: order.paymentStatus === 'PAID' ? '#4caf50' : '#ff9800',
                  }}
                />
              </TableCell>
              <TableCell align="right">{formatCurrency(order.total)}</TableCell>
              <TableCell align="right" sx={{ color: '#4caf50' }}>
                {formatCurrency(order.profit)}
              </TableCell>
            </TableRow>
          ))}
          {orders.length === 0 && (
            <TableRow>
              <TableCell colSpan={7} align="center" sx={{ py: 4, opacity: 0.6 }}>
                No orders found
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );
}

// -----------------------------------------------------------------------------
// Events Tab
// -----------------------------------------------------------------------------

interface EventsTabProps {
  events: CustomerEventSummary[];
}

function EventsTab({ events }: EventsTabProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  return (
    <TableContainer component={Paper} sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>Event Name</TableCell>
            <TableCell>Type</TableCell>
            <TableCell>Date</TableCell>
            <TableCell>Status</TableCell>
            <TableCell align="right">Est. Value</TableCell>
            <TableCell align="right">Paid</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {events.map((event) => (
            <TableRow key={event.eventId} hover>
              <TableCell>
                <Typography variant="body2" fontWeight={500} sx={{ color: '#ce93d8' }}>
                  {event.eventName}
                </Typography>
              </TableCell>
              <TableCell>
                <Chip label={event.eventType} size="small" variant="outlined" />
              </TableCell>
              <TableCell>{new Date(event.eventDate).toLocaleDateString()}</TableCell>
              <TableCell>
                <Chip
                  label={event.status}
                  size="small"
                  sx={{
                    bgcolor: event.status === 'COMPLETED' ? 'rgba(76,175,80,0.2)' : 'rgba(33,150,243,0.2)',
                    color: event.status === 'COMPLETED' ? '#4caf50' : '#2196f3',
                  }}
                />
              </TableCell>
              <TableCell align="right">{formatCurrency(event.estimatedValue)}</TableCell>
              <TableCell align="right" sx={{ color: '#4caf50' }}>
                {formatCurrency(event.totalPaid)}
              </TableCell>
            </TableRow>
          ))}
          {events.length === 0 && (
            <TableRow>
              <TableCell colSpan={6} align="center" sx={{ py: 4, opacity: 0.6 }}>
                No events found
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );
}

// -----------------------------------------------------------------------------
// Loyalty Transactions Tab
// -----------------------------------------------------------------------------

interface LoyaltyTabProps {
  transactions: LoyaltyTransaction[];
}

function LoyaltyTab({ transactions }: LoyaltyTabProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  return (
    <TableContainer component={Paper} sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>Date</TableCell>
            <TableCell>Type</TableCell>
            <TableCell>Description</TableCell>
            <TableCell align="right">Points</TableCell>
            <TableCell align="right">Balance</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {transactions.map((tx) => (
            <TableRow key={tx.id} hover>
              <TableCell>
                {new Date(tx.createdAt).toLocaleDateString()}
              </TableCell>
              <TableCell>
                <Chip
                  label={tx.type}
                  size="small"
                  sx={{
                    bgcolor: tx.type === 'EARN' || tx.type === 'BONUS'
                      ? 'rgba(76,175,80,0.2)'
                      : tx.type === 'REDEEM'
                        ? 'rgba(33,150,243,0.2)'
                        : 'rgba(255,152,0,0.2)',
                    color: tx.type === 'EARN' || tx.type === 'BONUS'
                      ? '#4caf50'
                      : tx.type === 'REDEEM'
                        ? '#2196f3'
                        : '#ff9800',
                  }}
                />
              </TableCell>
              <TableCell>{tx.description}</TableCell>
              <TableCell align="right" sx={{
                color: tx.points > 0 ? '#4caf50' : '#f44336',
                fontWeight: 500,
              }}>
                {tx.points > 0 ? '+' : ''}{tx.points}
              </TableCell>
              <TableCell align="right">{tx.balance.toLocaleString()}</TableCell>
            </TableRow>
          ))}
          {transactions.length === 0 && (
            <TableRow>
              <TableCell colSpan={5} align="center" sx={{ py: 4, opacity: 0.6 }}>
                No loyalty transactions found
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );
}

// -----------------------------------------------------------------------------
// Notes Dialog
// -----------------------------------------------------------------------------

interface NotesDialogProps {
  open: boolean;
  onClose: () => void;
  notes: string;
  onSave: (notes: string) => void;
}

function NotesDialog({ open, onClose, notes, onSave }: NotesDialogProps) {
  const [editedNotes, setEditedNotes] = useState(notes);

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Customer Notes</DialogTitle>
      <DialogContent>
        <TextField
          multiline
          rows={6}
          fullWidth
          value={editedNotes}
          onChange={(e) => setEditedNotes(e.target.value)}
          placeholder="Add notes about this customer..."
          sx={{ mt: 1 }}
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button
          variant="contained"
          onClick={() => {
            onSave(editedNotes);
            onClose();
          }}
          sx={{ bgcolor: '#fdd835', color: '#000' }}
        >
          Save Notes
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// -----------------------------------------------------------------------------
// Main Customer360View Component
// -----------------------------------------------------------------------------

interface Customer360ViewProps {
  customerId?: string;
  onBack?: () => void;
}

export default function Customer360View({ customerId, onBack }: Customer360ViewProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  const [tabValue, setTabValue] = useState(0);
  const [notesDialogOpen, setNotesDialogOpen] = useState(false);

  // Mock data - replace with API call
  const customer = MOCK_CUSTOMERS.find((c) => c.id === customerId) || MOCK_CUSTOMERS[0];
  const orders = MOCK_CUSTOMER_ORDERS;
  const events = MOCK_CUSTOMER_EVENTS;
  const loyaltyTransactions = MOCK_LOYALTY_TRANSACTIONS;

  const tierConfig = LOYALTY_TIER_CONFIGS[customer.loyaltyTier];
  const lastOrderDays = daysSince(customer.lastOrderDate);

  const handleSaveNotes = async (notes: string) => {
    if (!customerId) return;
    try {
      await updateCustomerNotes(customerId, notes || null);
    } catch (err) {
      console.error('Failed to save notes:', err);
    }
  };

  return (
    <Box sx={{ p: 3, bgcolor: dk ? '#0f0f0f' : '#f8f9fa', minHeight: '100vh' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        {onBack && (
          <IconButton onClick={onBack}>
            <ArrowBack />
          </IconButton>
        )}
        <Typography variant="h5" fontWeight={600}>
          Customer Profile
        </Typography>
      </Box>

      <Grid container spacing={3}>
        {/* Left Column - Profile Info */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Paper sx={{ p: 3, bgcolor: dk ? '#1a1a2e' : '#fff', mb: 3 }}>
            {/* Avatar & Basic Info */}
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
              <Avatar
                sx={{
                  width: 80,
                  height: 80,
                  bgcolor: tierConfig.color,
                  fontSize: 32,
                }}
              >
                {customer.name.charAt(0)}
              </Avatar>
              <Box>
                <Typography variant="h5" fontWeight={600}>
                  {customer.name}
                </Typography>
                <Chip
                  icon={<Star sx={{ fontSize: 16 }} />}
                  label={tierConfig.label}
                  size="small"
                  sx={{
                    bgcolor: tierConfig.backgroundColor,
                    color: tierConfig.color,
                    fontWeight: 500,
                    mt: 0.5,
                  }}
                />
              </Box>
            </Box>

            {/* Contact Info */}
            <Stack spacing={2}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                <Phone sx={{ color: '#4caf50', fontSize: 20 }} />
                <Typography>{customer.phone}</Typography>
                <IconButton size="small" sx={{ ml: 'auto', color: '#25D366' }}>
                  <WhatsApp />
                </IconButton>
              </Box>

              {customer.email && (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <Email sx={{ color: '#ff9800', fontSize: 20 }} />
                  <Typography>{customer.email}</Typography>
                </Box>
              )}

              {customer.preferredAddress && (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <LocationOn sx={{ color: '#f44336', fontSize: 20 }} />
                  <Typography variant="body2" sx={{ opacity: 0.9 }}>
                    {customer.preferredAddress}
                  </Typography>
                </Box>
              )}

              {customer.birthday && (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <Cake sx={{ color: '#e91e63', fontSize: 20 }} />
                  <Typography>
                    {new Date(customer.birthday).toLocaleDateString('en-IN', {
                      month: 'long',
                      day: 'numeric',
                    })}
                  </Typography>
                </Box>
              )}

              {customer.anniversary && (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <Favorite sx={{ color: '#f44336', fontSize: 20 }} />
                  <Typography>
                    Anniversary: {new Date(customer.anniversary).toLocaleDateString('en-IN', {
                      month: 'long',
                      day: 'numeric',
                    })}
                  </Typography>
                </Box>
              )}
            </Stack>

            <Divider sx={{ my: 2, borderColor: 'rgba(255,255,255,0.1)' }} />

            {/* Tags */}
            <Typography variant="subtitle2" sx={{ mb: 1, opacity: 0.7 }}>
              Tags
            </Typography>
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
              {customer.tags.map((tagType) => {
                const tag = CUSTOMER_TAGS[tagType];
                return (
                  <Chip
                    key={tagType}
                    label={tag.label}
                    size="small"
                    sx={{
                      bgcolor: `${tag.color}20`,
                      color: tag.color,
                      fontSize: 11,
                    }}
                  />
                );
              })}
            </Box>

            <Divider sx={{ my: 2, borderColor: 'rgba(255,255,255,0.1)' }} />

            {/* Notes */}
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
              <Typography variant="subtitle2" sx={{ opacity: 0.7 }}>
                Notes
              </Typography>
              <IconButton size="small" onClick={() => setNotesDialogOpen(true)}>
                <Edit sx={{ fontSize: 16 }} />
              </IconButton>
            </Box>
            <Typography variant="body2" sx={{ opacity: 0.8, fontStyle: customer.notes ? 'normal' : 'italic' }}>
              {customer.notes || 'No notes added'}
            </Typography>

            {/* Marketing Consent */}
            <Box sx={{ mt: 2 }}>
              <Chip
                label={customer.marketingConsent ? 'Marketing: Opted In' : 'Marketing: Opted Out'}
                size="small"
                sx={{
                  bgcolor: customer.marketingConsent ? 'rgba(76,175,80,0.2)' : 'rgba(244,67,54,0.2)',
                  color: customer.marketingConsent ? '#4caf50' : '#f44336',
                }}
              />
            </Box>
          </Paper>

          {/* Loyalty Card */}
          <LoyaltyStatusCard customer={customer} />
        </Grid>

        {/* Right Column - Metrics & History */}
        <Grid size={{ xs: 12, md: 8 }}>
          {/* Alert for at-risk customers */}
          {lastOrderDays && lastOrderDays > 60 && (
            <Alert
              severity="warning"
              icon={<Warning />}
              sx={{ mb: 3, bgcolor: 'rgba(255,152,0,0.1)' }}
            >
              Last order was {lastOrderDays} days ago. Consider reaching out to re-engage this customer.
            </Alert>
          )}

          {/* Metrics Grid */}
          <Grid container spacing={2} sx={{ mb: 3 }}>
            <Grid size={{ xs: 6, sm: 3 }}>
              <MetricCard
                icon={<AttachMoney />}
                label="Lifetime Value"
                value={formatCurrency(customer.lifetimeValue)}
                color="#4caf50"
              />
            </Grid>
            <Grid size={{ xs: 6, sm: 3 }}>
              <MetricCard
                icon={<ShoppingCart />}
                label="Total Orders"
                value={customer.totalOrders}
                subValue={`Avg: ${formatCurrency(customer.averageOrderValue)}`}
                color="#2196f3"
              />
            </Grid>
            <Grid size={{ xs: 6, sm: 3 }}>
              <MetricCard
                icon={<TrendingUp />}
                label="Total Profit"
                value={formatCurrency(customer.totalProfit)}
                subValue={`${customer.profitMargin}% margin`}
                color="#ff9800"
              />
            </Grid>
            <Grid size={{ xs: 6, sm: 3 }}>
              <MetricCard
                icon={<CardGiftcard />}
                label="Referrals"
                value={customer.referralCount}
                color="#9c27b0"
              />
            </Grid>
          </Grid>

          {/* Tabs for History */}
          <Paper sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
            <Tabs
              value={tabValue}
              onChange={(_, v) => setTabValue(v)}
              sx={{
                borderBottom: dk ? '1px solid rgba(255,255,255,0.1)' : '1px solid rgba(0,0,0,0.1)',
                '& .MuiTab-root': { color: dk ? 'rgba(255,255,255,0.7)' : 'rgba(0,0,0,0.7)' },
                '& .Mui-selected': { color: '#fdd835' },
                '& .MuiTabs-indicator': { bgcolor: '#fdd835' },
              }}
            >
              <Tab icon={<ShoppingCart sx={{ fontSize: 18 }} />} iconPosition="start" label="Orders" />
              <Tab icon={<Event sx={{ fontSize: 18 }} />} iconPosition="start" label="Events" />
              <Tab icon={<Loyalty sx={{ fontSize: 18 }} />} iconPosition="start" label="Loyalty" />
            </Tabs>

            <Box sx={{ p: 2 }}>
              <TabPanel value={tabValue} index={0}>
                <OrdersTab orders={orders} />
              </TabPanel>
              <TabPanel value={tabValue} index={1}>
                <EventsTab events={events} />
              </TabPanel>
              <TabPanel value={tabValue} index={2}>
                <LoyaltyTab transactions={loyaltyTransactions} />
              </TabPanel>
            </Box>
          </Paper>
        </Grid>
      </Grid>

      {/* Notes Dialog */}
      <NotesDialog
        open={notesDialogOpen}
        onClose={() => setNotesDialogOpen(false)}
        notes={customer.notes || ''}
        onSave={handleSaveNotes}
      />
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Exports
// -----------------------------------------------------------------------------

export { LoyaltyStatusCard, MetricCard };
