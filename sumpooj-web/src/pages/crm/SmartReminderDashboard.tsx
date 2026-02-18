// =============================================================================
// SMART REMINDER DASHBOARD - Customer Retention Alerts
// Florist ERP SaaS — CRM Intelligence
// =============================================================================

import { useState, useMemo } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Chip,
  Card,
  CardContent,
  CardActions,
  Button,
  IconButton,
  Avatar,
  Tabs,
  Tab,
  Badge,
  TextField,
  InputAdornment,
  Menu,
  MenuItem,
  Stack,
  Tooltip,
  Divider,
  Alert,
} from '@mui/material';
import {
  Cake,
  Favorite,
  RemoveShoppingCart,
  Star,
  Warning,
  Replay,
  EventNote,
  Phone,
  Email,
  WhatsApp,
  Check,
  Close,
  FilterList,
  Search,
  MoreVert,
  NotificationsActive,
  TrendingDown,
  People,
} from '@mui/icons-material';
import type {
  SmartReminder,
  ReminderType,
  ReminderPriority,
} from './CRMTypes';
import {
  REMINDER_CONFIGS,
  MOCK_REMINDERS,
  daysUntil,
} from './CRMTypes';

// -----------------------------------------------------------------------------
// Icon Mapping
// -----------------------------------------------------------------------------

const REMINDER_ICONS: Record<ReminderType, React.ReactNode> = {
  BIRTHDAY: <Cake />,
  ANNIVERSARY: <Favorite />,
  NO_PURCHASE: <RemoveShoppingCart />,
  VIP_FOLLOWUP: <Star />,
  AT_RISK: <Warning />,
  RE_ENGAGEMENT: <Replay />,
  EVENT_FOLLOWUP: <EventNote />,
};

const PRIORITY_COLORS: Record<ReminderPriority, string> = {
  LOW: '#4caf50',
  MEDIUM: '#2196f3',
  HIGH: '#ff9800',
  URGENT: '#f44336',
};

// -----------------------------------------------------------------------------
// Reminder Card Component
// -----------------------------------------------------------------------------

interface ReminderCardProps {
  reminder: SmartReminder;
  onDismiss: (id: string) => void;
  onAction: (id: string, action: string) => void;
  onViewCustomer: (customerId: string) => void;
}

function ReminderCard({ reminder, onDismiss, onAction, onViewCustomer }: ReminderCardProps) {
  const [actionMenuAnchor, setActionMenuAnchor] = useState<null | HTMLElement>(null);
  const config = REMINDER_CONFIGS[reminder.type];
  const daysAway = daysUntil(reminder.dueDate);

  return (
    <Card
      sx={{
        bgcolor: '#1a1a2e',
        border: `1px solid ${PRIORITY_COLORS[reminder.priority]}20`,
        borderLeft: `4px solid ${PRIORITY_COLORS[reminder.priority]}`,
        opacity: reminder.dismissed ? 0.5 : 1,
      }}
    >
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
          <Avatar
            sx={{
              bgcolor: `${config.color}20`,
              color: config.color,
              width: 44,
              height: 44,
            }}
          >
            {REMINDER_ICONS[reminder.type]}
          </Avatar>

          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
              <Typography variant="subtitle1" fontWeight={600} noWrap>
                {reminder.title}
              </Typography>
              <Chip
                label={reminder.priority}
                size="small"
                sx={{
                  bgcolor: `${PRIORITY_COLORS[reminder.priority]}20`,
                  color: PRIORITY_COLORS[reminder.priority],
                  fontSize: 10,
                  height: 20,
                }}
              />
              {daysAway !== null && daysAway <= 7 && daysAway >= 0 && (
                <Chip
                  label={daysAway === 0 ? 'Today' : `${daysAway}d`}
                  size="small"
                  sx={{
                    bgcolor: daysAway <= 2 ? 'rgba(244,67,54,0.2)' : 'rgba(255,152,0,0.2)',
                    color: daysAway <= 2 ? '#f44336' : '#ff9800',
                    fontSize: 10,
                    height: 20,
                  }}
                />
              )}
            </Box>

            <Typography
              variant="body2"
              fontWeight={500}
              sx={{ color: '#90caf9', cursor: 'pointer', mb: 0.5 }}
              onClick={() => onViewCustomer(reminder.customerId)}
            >
              {reminder.customerName}
            </Typography>

            <Typography variant="body2" sx={{ opacity: 0.7, mb: 1 }}>
              {reminder.description}
            </Typography>

            <Typography variant="caption" sx={{ opacity: 0.5 }}>
              Due: {new Date(reminder.dueDate).toLocaleDateString()}
            </Typography>
          </Box>

          <IconButton
            size="small"
            onClick={(e) => setActionMenuAnchor(e.currentTarget)}
          >
            <MoreVert sx={{ fontSize: 18 }} />
          </IconButton>
        </Box>
      </CardContent>

      <CardActions sx={{ px: 2, pb: 2, pt: 0, gap: 1 }}>
        <Button
          size="small"
          startIcon={<Phone sx={{ fontSize: 16 }} />}
          onClick={() => onAction(reminder.id, 'call')}
          sx={{ color: '#4caf50' }}
        >
          Call
        </Button>
        <Button
          size="small"
          startIcon={<WhatsApp sx={{ fontSize: 16 }} />}
          onClick={() => onAction(reminder.id, 'whatsapp')}
          sx={{ color: '#25D366' }}
        >
          WhatsApp
        </Button>
        <Box sx={{ flex: 1 }} />
        <IconButton
          size="small"
          onClick={() => onDismiss(reminder.id)}
          sx={{ color: 'rgba(255,255,255,0.5)' }}
        >
          <Close sx={{ fontSize: 18 }} />
        </IconButton>
        <IconButton
          size="small"
          onClick={() => onAction(reminder.id, 'done')}
          sx={{ color: '#4caf50' }}
        >
          <Check sx={{ fontSize: 18 }} />
        </IconButton>
      </CardActions>

      {/* Action Menu */}
      <Menu
        anchorEl={actionMenuAnchor}
        open={Boolean(actionMenuAnchor)}
        onClose={() => setActionMenuAnchor(null)}
      >
        <MenuItem onClick={() => {
          onViewCustomer(reminder.customerId);
          setActionMenuAnchor(null);
        }}>
          View Customer
        </MenuItem>
        <MenuItem onClick={() => {
          onAction(reminder.id, 'snooze');
          setActionMenuAnchor(null);
        }}>
          Snooze 7 days
        </MenuItem>
        <MenuItem onClick={() => {
          onDismiss(reminder.id);
          setActionMenuAnchor(null);
        }}>
          Dismiss
        </MenuItem>
      </Menu>
    </Card>
  );
}

// -----------------------------------------------------------------------------
// Stats Card
// -----------------------------------------------------------------------------

interface StatsCardProps {
  icon: React.ReactNode;
  label: string;
  value: number;
  color: string;
  onClick?: () => void;
}

function StatsCard({ icon, label, value, color, onClick }: StatsCardProps) {
  return (
    <Paper
      sx={{
        p: 2,
        bgcolor: '#1a1a2e',
        cursor: onClick ? 'pointer' : 'default',
        transition: 'transform 0.2s',
        '&:hover': onClick ? { transform: 'translateY(-2px)' } : {},
      }}
      onClick={onClick}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <Avatar sx={{ bgcolor: `${color}20`, color }}>
          {icon}
        </Avatar>
        <Box>
          <Typography variant="h4" fontWeight={600}>
            {value}
          </Typography>
          <Typography variant="caption" sx={{ opacity: 0.7 }}>
            {label}
          </Typography>
        </Box>
      </Box>
    </Paper>
  );
}

// -----------------------------------------------------------------------------
// Main Smart Reminder Dashboard
// -----------------------------------------------------------------------------

interface SmartReminderDashboardProps {
  onViewCustomer?: (customerId: string) => void;
}

export default function SmartReminderDashboard({ onViewCustomer }: SmartReminderDashboardProps) {
  const [tabValue, setTabValue] = useState(0);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<ReminderType | 'ALL'>('ALL');
  const [filterAnchor, setFilterAnchor] = useState<null | HTMLElement>(null);
  const [reminders, setReminders] = useState<SmartReminder[]>(MOCK_REMINDERS);

  // Filter and categorize reminders
  const categorizedReminders = useMemo(() => {
    const filtered = reminders.filter((r) => {
      if (r.dismissed) return false;
      if (searchQuery && !r.customerName.toLowerCase().includes(searchQuery.toLowerCase())) {
        return false;
      }
      if (filterType !== 'ALL' && r.type !== filterType) return false;
      return true;
    });

    return {
      all: filtered,
      urgent: filtered.filter((r) => r.priority === 'URGENT' || r.priority === 'HIGH'),
      birthdays: filtered.filter((r) => r.type === 'BIRTHDAY'),
      anniversaries: filtered.filter((r) => r.type === 'ANNIVERSARY'),
      atRisk: filtered.filter((r) => r.type === 'AT_RISK' || r.type === 'NO_PURCHASE'),
      vip: filtered.filter((r) => r.type === 'VIP_FOLLOWUP'),
    };
  }, [reminders, searchQuery, filterType]);

  // Stats
  const stats = useMemo(() => ({
    total: categorizedReminders.all.length,
    urgent: categorizedReminders.urgent.length,
    birthdays: categorizedReminders.birthdays.length,
    atRisk: categorizedReminders.atRisk.length,
  }), [categorizedReminders]);

  const handleDismiss = (id: string) => {
    setReminders((prev) =>
      prev.map((r) => (r.id === id ? { ...r, dismissed: true } : r))
    );
  };

  const handleAction = (id: string, action: string) => {
    console.log('Action:', action, 'on reminder:', id);
    if (action === 'done') {
      handleDismiss(id);
    }
    // TODO: Implement actual actions
  };

  const handleViewCustomer = (customerId: string) => {
    if (onViewCustomer) {
      onViewCustomer(customerId);
    } else {
      console.log('View customer:', customerId);
    }
  };

  const getTabReminders = () => {
    switch (tabValue) {
      case 0: return categorizedReminders.all;
      case 1: return categorizedReminders.birthdays;
      case 2: return categorizedReminders.anniversaries;
      case 3: return categorizedReminders.atRisk;
      case 4: return categorizedReminders.vip;
      default: return categorizedReminders.all;
    }
  };

  return (
    <Box sx={{ p: 3, bgcolor: '#0f0f0f', minHeight: '100vh' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={600} sx={{ color: '#fff' }}>
            Smart Reminders
          </Typography>
          <Typography variant="body2" sx={{ opacity: 0.7 }}>
            Customer retention alerts and follow-ups
          </Typography>
        </Box>
        <Badge badgeContent={stats.urgent} color="error">
          <NotificationsActive sx={{ fontSize: 28, color: '#fdd835' }} />
        </Badge>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid size={{ xs: 6, sm: 3 }}>
          <StatsCard
            icon={<NotificationsActive />}
            label="Total Reminders"
            value={stats.total}
            color="#fdd835"
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <StatsCard
            icon={<Warning />}
            label="Urgent / High"
            value={stats.urgent}
            color="#f44336"
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <StatsCard
            icon={<Cake />}
            label="Upcoming Birthdays"
            value={stats.birthdays}
            color="#e91e63"
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <StatsCard
            icon={<TrendingDown />}
            label="At Risk Customers"
            value={stats.atRisk}
            color="#ff9800"
          />
        </Grid>
      </Grid>

      {/* Filters */}
      <Paper sx={{ bgcolor: '#1a1a2e', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', p: 2, gap: 2 }}>
          <TextField
            size="small"
            placeholder="Search by customer name..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search sx={{ color: 'rgba(255,255,255,0.5)' }} />
                </InputAdornment>
              ),
            }}
            sx={{ width: 280 }}
          />

          <Button
            startIcon={<FilterList />}
            onClick={(e) => setFilterAnchor(e.currentTarget)}
            sx={{ color: filterType !== 'ALL' ? '#fdd835' : 'inherit' }}
          >
            {filterType === 'ALL' ? 'All Types' : REMINDER_CONFIGS[filterType].label}
          </Button>

          <Menu
            anchorEl={filterAnchor}
            open={Boolean(filterAnchor)}
            onClose={() => setFilterAnchor(null)}
          >
            <MenuItem
              selected={filterType === 'ALL'}
              onClick={() => { setFilterType('ALL'); setFilterAnchor(null); }}
            >
              All Types
            </MenuItem>
            <Divider />
            {Object.values(REMINDER_CONFIGS).map((config) => (
              <MenuItem
                key={config.type}
                selected={filterType === config.type}
                onClick={() => { setFilterType(config.type); setFilterAnchor(null); }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Box sx={{ color: config.color }}>{REMINDER_ICONS[config.type]}</Box>
                  {config.label}
                </Box>
              </MenuItem>
            ))}
          </Menu>
        </Box>

        {/* Tabs */}
        <Tabs
          value={tabValue}
          onChange={(_, v) => setTabValue(v)}
          sx={{
            borderTop: '1px solid rgba(255,255,255,0.1)',
            '& .MuiTab-root': { color: 'rgba(255,255,255,0.7)', minHeight: 48 },
            '& .Mui-selected': { color: '#fdd835' },
            '& .MuiTabs-indicator': { bgcolor: '#fdd835' },
          }}
        >
          <Tab label={`All (${categorizedReminders.all.length})`} />
          <Tab
            label={
              <Badge badgeContent={categorizedReminders.birthdays.length} color="error">
                Birthdays
              </Badge>
            }
          />
          <Tab label={`Anniversaries (${categorizedReminders.anniversaries.length})`} />
          <Tab
            label={
              <Badge badgeContent={categorizedReminders.atRisk.length} color="warning">
                At Risk
              </Badge>
            }
          />
          <Tab label={`VIP (${categorizedReminders.vip.length})`} />
        </Tabs>
      </Paper>

      {/* Reminders List */}
      {getTabReminders().length === 0 ? (
        <Alert severity="info" sx={{ bgcolor: 'rgba(33,150,243,0.1)' }}>
          No reminders to display. Great job staying on top of customer relationships!
        </Alert>
      ) : (
        <Grid container spacing={2}>
          {getTabReminders().map((reminder) => (
            <Grid size={{ xs: 12, md: 6, lg: 4 }} key={reminder.id}>
              <ReminderCard
                reminder={reminder}
                onDismiss={handleDismiss}
                onAction={handleAction}
                onViewCustomer={handleViewCustomer}
              />
            </Grid>
          ))}
        </Grid>
      )}
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Compact Reminder Widget (for dashboard embedding)
// -----------------------------------------------------------------------------

interface ReminderWidgetProps {
  maxItems?: number;
  onViewAll?: () => void;
  onViewCustomer?: (customerId: string) => void;
}

export function ReminderWidget({ maxItems = 5, onViewAll, onViewCustomer }: ReminderWidgetProps) {
  const urgentReminders = MOCK_REMINDERS
    .filter((r) => !r.dismissed && (r.priority === 'HIGH' || r.priority === 'URGENT'))
    .slice(0, maxItems);

  return (
    <Paper sx={{ p: 2, bgcolor: '#1a1a2e' }}>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <NotificationsActive sx={{ color: '#fdd835' }} />
          <Typography variant="subtitle1" fontWeight={600}>
            Reminders
          </Typography>
        </Box>
        {onViewAll && (
          <Button size="small" onClick={onViewAll} sx={{ color: '#fdd835' }}>
            View All
          </Button>
        )}
      </Box>

      <Stack spacing={1.5}>
        {urgentReminders.map((reminder) => {
          const config = REMINDER_CONFIGS[reminder.type];
          return (
            <Box
              key={reminder.id}
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 1.5,
                p: 1.5,
                bgcolor: 'rgba(0,0,0,0.2)',
                borderRadius: 1,
                cursor: 'pointer',
              }}
              onClick={() => onViewCustomer?.(reminder.customerId)}
            >
              <Avatar
                sx={{
                  bgcolor: `${config.color}20`,
                  color: config.color,
                  width: 32,
                  height: 32,
                }}
              >
                {REMINDER_ICONS[reminder.type]}
              </Avatar>
              <Box sx={{ flex: 1, minWidth: 0 }}>
                <Typography variant="body2" fontWeight={500} noWrap>
                  {reminder.customerName}
                </Typography>
                <Typography variant="caption" sx={{ opacity: 0.7 }}>
                  {reminder.title}
                </Typography>
              </Box>
              <Chip
                label={reminder.priority}
                size="small"
                sx={{
                  bgcolor: `${PRIORITY_COLORS[reminder.priority]}20`,
                  color: PRIORITY_COLORS[reminder.priority],
                  fontSize: 10,
                  height: 20,
                }}
              />
            </Box>
          );
        })}

        {urgentReminders.length === 0 && (
          <Typography variant="body2" sx={{ opacity: 0.6, textAlign: 'center', py: 2 }}>
            No urgent reminders
          </Typography>
        )}
      </Stack>
    </Paper>
  );
}
