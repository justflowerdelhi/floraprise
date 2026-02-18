/**
 * EventPaymentPage.tsx — Event Payment Schedule Management
 *
 * Features:
 * - Financial summary with progress tracking
 * - Payment schedule table
 * - Record payments linked to schedule items
 * - Role-based access (Designer: view only)
 * - Warnings for overdue/upcoming payments
 */
import React, { useState, useMemo, useCallback } from 'react';
import {
  Box, Typography, Card, Breadcrumbs, Link,
  useTheme, alpha, Button, Chip, Skeleton, Stack, Tabs, Tab,
} from '@mui/material';
import {
  ArrowBack as BackIcon,
  Celebration as EventIcon,
  NavigateNext as NavIcon,
  AccountBalance as FinanceIcon,
  Schedule as ScheduleIcon,
  Receipt as ReceiptIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import { useNavigate, useParams, Link as RouterLink } from 'react-router-dom';
import { useRBAC } from '../../core/rbac/RBACContext';
import EventFinancialSummary from './EventFinancialSummary';
import PaymentSchedulePanel from './PaymentSchedulePanel';
import type { EventPaymentSchedule, EventFinancialSummaryData, PaymentWarning } from './PaymentScheduleTypes';
import { generatePaymentWarnings, calculateFinancialSummary } from './PaymentScheduleTypes';
import { getSchedulesForEvent } from './PaymentScheduleMockData';
import type { Event } from './EventTypes';
import { MOCK_EVENTS } from './EventMockData';
import { MOCK_PROPOSALS } from './ProposalMockData';

// ─── Tab Panel Component ────────────────────────────────────

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

const TabPanel: React.FC<TabPanelProps> = ({ children, value, index }) => (
  <div role="tabpanel" hidden={value !== index}>
    {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
  </div>
);

// ─── Loading Skeleton ───────────────────────────────────────

const LoadingSkeleton: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Box sx={{ p: { xs: 2, md: 3 } }}>
      <Skeleton variant="text" width={200} height={24} />
      <Skeleton variant="text" width={300} height={40} sx={{ mt: 2 }} />
      <Card
        sx={{
          mt: 3,
          p: 3,
          bgcolor: dk ? '#1a1a2e' : '#fff',
        }}
      >
        <Stack direction="row" spacing={3}>
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} variant="rounded" width={200} height={100} />
          ))}
        </Stack>
      </Card>
      <Card
        sx={{
          mt: 2,
          p: 3,
          bgcolor: dk ? '#1a1a2e' : '#fff',
        }}
      >
        <Skeleton variant="text" width={150} height={32} />
        <Skeleton variant="rounded" width="100%" height={300} sx={{ mt: 2 }} />
      </Card>
    </Box>
  );
};

// ─── Event Header Component ─────────────────────────────────

interface EventHeaderProps {
  event: Event;
  proposalStatus?: string;
}

const EventHeader: React.FC<EventHeaderProps> = ({ event, proposalStatus }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Card
      sx={{
        p: { xs: 2, md: 3 },
        bgcolor: dk ? '#1a1a2e' : '#fff',
        borderRadius: 3,
        display: 'flex',
        alignItems: 'center',
        gap: 2,
        mb: 3,
      }}
    >
      <Box
        sx={{
          width: 56,
          height: 56,
          borderRadius: 2,
          bgcolor: alpha('#e91e63', 0.15),
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <EventIcon sx={{ color: '#e91e63', fontSize: 28 }} />
      </Box>
      <Box sx={{ flex: 1 }}>
        <Typography variant="h5" sx={{ fontWeight: 800 }}>
          {event.eventName}
        </Typography>
        <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
          {event.clientName} • {new Date(event.eventDate).toLocaleDateString()} • {event.venueName}
        </Typography>
      </Box>
      {proposalStatus && (
        <Chip
          label={proposalStatus === 'APPROVED' ? 'Proposal Approved' : 'Proposal Pending'}
          size="small"
          sx={{
            bgcolor: proposalStatus === 'APPROVED' ? alpha('#4caf50', 0.15) : alpha('#ff9800', 0.15),
            color: proposalStatus === 'APPROVED' ? '#4caf50' : '#ff9800',
            fontWeight: 600,
          }}
        />
      )}
    </Card>
  );
};

// ─── Main Component ─────────────────────────────────────────

const EventPaymentPage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const { eventId } = useParams<{ eventId: string }>();
  const { canAny } = useRBAC();

  // Role-based access
  const canManagePayments = canAny(['payments:schedule:manage']);
  const readonly = !canManagePayments;

  // State
  const [activeTab, setActiveTab] = useState(0);
  const [loading] = useState(false);

  // Get event data
  const event = useMemo(() => {
    return MOCK_EVENTS.find((e) => e.id === eventId);
  }, [eventId]);

  // Get approved proposal for this event
  const proposal = useMemo(() => {
    if (!eventId) return null;
    return MOCK_PROPOSALS.find((p) => p.eventId === eventId && p.status === 'APPROVED');
  }, [eventId]);

  // Get payment schedules for this event
  const [schedules, setSchedules] = useState<EventPaymentSchedule[]>(() =>
    eventId ? getSchedulesForEvent(eventId) : []
  );

  // Calculate financial summary
  const financialSummary = useMemo((): EventFinancialSummaryData | null => {
    if (!proposal || !eventId) return null;
    return calculateFinancialSummary(eventId, proposal.id, proposal.grandTotal, schedules);
  }, [eventId, proposal, schedules]);

  // Generate warnings
  const warnings = useMemo((): PaymentWarning[] => {
    if (!financialSummary || !event) return [];
    return generatePaymentWarnings(financialSummary, event.eventDate, event.status);
  }, [financialSummary, event]);

  // Handlers
  const handleSchedulesChange = useCallback((newSchedules: EventPaymentSchedule[]) => {
    setSchedules(newSchedules);
  }, []);

  const handleRecordPayment = useCallback(() => {
    setActiveTab(1); // Switch to schedule tab
  }, []);

  const handleWarningAction = useCallback((warning: PaymentWarning) => {
    // Navigate to appropriate action based on warning type
    if (warning.type === 'NO_DEPOSIT' || warning.type === 'OVERDUE_PAYMENT') {
      setActiveTab(1); // Switch to schedule tab
    }
  }, []);

  // Loading state
  if (loading) {
    return <LoadingSkeleton />;
  }

  // Not found
  if (!event) {
    return (
      <Box sx={{ p: { xs: 2, md: 3 }, textAlign: 'center' }}>
        <WarningIcon sx={{ fontSize: 64, color: '#f44336', opacity: 0.5, mb: 2 }} />
        <Typography variant="h5" sx={{ fontWeight: 700, mb: 1 }}>
          Event Not Found
        </Typography>
        <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 3 }}>
          The event you're looking for doesn't exist or has been removed.
        </Typography>
        <Button
          variant="contained"
          startIcon={<BackIcon />}
          onClick={() => navigate('/events')}
          sx={{
            bgcolor: '#fdd835',
            color: '#000',
            fontWeight: 600,
            '&:hover': { bgcolor: '#ffeb3b' },
          }}
        >
          Back to Events
        </Button>
      </Box>
    );
  }

  // No proposal yet
  if (!proposal) {
    return (
      <Box sx={{ p: { xs: 2, md: 3 } }}>
        {/* Breadcrumbs */}
        <Breadcrumbs separator={<NavIcon sx={{ fontSize: 16 }} />} sx={{ mb: 2 }}>
          <Link
            component={RouterLink}
            to="/events"
            sx={{ color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary', textDecoration: 'none' }}
          >
            Events
          </Link>
          <Link
            component={RouterLink}
            to={`/events/${eventId}`}
            sx={{ color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary', textDecoration: 'none' }}
          >
            {event.eventName}
          </Link>
          <Typography sx={{ color: dk ? '#fff' : 'text.primary' }}>Payments</Typography>
        </Breadcrumbs>

        <EventHeader event={event} />

        <Card
          sx={{
            p: 4,
            bgcolor: dk ? '#1a1a2e' : '#fff',
            borderRadius: 3,
            textAlign: 'center',
          }}
        >
          <Box
            sx={{
              width: 80,
              height: 80,
              borderRadius: '50%',
              bgcolor: alpha('#ff9800', 0.15),
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              mx: 'auto',
              mb: 3,
            }}
          >
            <ReceiptIcon sx={{ fontSize: 40, color: '#ff9800' }} />
          </Box>
          <Typography variant="h6" sx={{ fontWeight: 700, mb: 1 }}>
            No Approved Proposal Yet
          </Typography>
          <Typography
            variant="body2"
            sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 3, maxWidth: 400, mx: 'auto' }}
          >
            Payment schedules can only be created after a proposal is approved.
            Create and approve a proposal first to enable payment tracking.
          </Typography>
          <Button
            variant="contained"
            startIcon={<ReceiptIcon />}
            component={RouterLink}
            to={`/events/${eventId}/proposals/new`}
            sx={{
              bgcolor: '#fdd835',
              color: '#000',
              fontWeight: 600,
              '&:hover': { bgcolor: '#ffeb3b' },
            }}
          >
            Create Proposal
          </Button>
        </Card>
      </Box>
    );
  }

  return (
    <Box sx={{ p: { xs: 2, md: 3 } }}>
      {/* Breadcrumbs */}
      <Breadcrumbs separator={<NavIcon sx={{ fontSize: 16 }} />} sx={{ mb: 2 }}>
        <Link
          component={RouterLink}
          to="/events"
          sx={{ color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary', textDecoration: 'none' }}
        >
          Events
        </Link>
        <Link
          component={RouterLink}
          to={`/events/${eventId}`}
          sx={{ color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary', textDecoration: 'none' }}
        >
          {event.eventName}
        </Link>
        <Typography sx={{ color: dk ? '#fff' : 'text.primary' }}>Payments</Typography>
      </Breadcrumbs>

      {/* Event Header */}
      <EventHeader event={event} proposalStatus={proposal.status} />

      {/* Tabs */}
      <Box sx={{ borderBottom: 1, borderColor: dk ? 'rgba(255,255,255,0.1)' : 'divider', mb: 2 }}>
        <Tabs
          value={activeTab}
          onChange={(_, v) => setActiveTab(v)}
          sx={{
            '& .MuiTab-root': {
              textTransform: 'none',
              fontWeight: 600,
              minHeight: 48,
              color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
              '&.Mui-selected': {
                color: '#fdd835',
              },
            },
            '& .MuiTabs-indicator': {
              bgcolor: '#fdd835',
            },
          }}
        >
          <Tab
            icon={<FinanceIcon sx={{ fontSize: 20 }} />}
            iconPosition="start"
            label="Overview"
          />
          <Tab
            icon={<ScheduleIcon sx={{ fontSize: 20 }} />}
            iconPosition="start"
            label={`Schedule (${schedules.length})`}
          />
        </Tabs>
      </Box>

      {/* Tab Panels */}
      <TabPanel value={activeTab} index={0}>
        {financialSummary ? (
          <EventFinancialSummary
            summary={financialSummary}
            warnings={warnings}
            onRecordPayment={handleRecordPayment}
            onWarningAction={handleWarningAction}
            readonly={readonly}
          />
        ) : (
          <Card
            sx={{
              p: 4,
              bgcolor: dk ? '#1a1a2e' : '#fff',
              borderRadius: 3,
              textAlign: 'center',
            }}
          >
            <Typography sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
              Create a payment schedule to see the financial summary.
            </Typography>
            <Button
              variant="outlined"
              onClick={() => setActiveTab(1)}
              sx={{ mt: 2 }}
            >
              Set Up Payment Schedule
            </Button>
          </Card>
        )}
      </TabPanel>

      <TabPanel value={activeTab} index={1}>
        <PaymentSchedulePanel
          eventId={eventId!}
          proposalId={proposal.id}
          proposalGrandTotal={proposal.grandTotal}
          eventDate={event.eventDate}
          schedules={schedules}
          onSchedulesChange={handleSchedulesChange}
          readonly={readonly}
        />
      </TabPanel>

      {/* Readonly Notice */}
      {readonly && (
        <Box
          sx={{
            position: 'fixed',
            bottom: 24,
            right: 24,
            bgcolor: dk ? 'rgba(26,26,46,0.95)' : 'rgba(255,255,255,0.95)',
            border: 1,
            borderColor: dk ? 'rgba(255,255,255,0.1)' : 'divider',
            borderRadius: 2,
            px: 2,
            py: 1,
            display: 'flex',
            alignItems: 'center',
            gap: 1,
            boxShadow: 4,
          }}
        >
          <Chip
            label="View Only"
            size="small"
            sx={{
              bgcolor: alpha('#9c27b0', 0.15),
              color: '#9c27b0',
              fontWeight: 600,
            }}
          />
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            Contact a Manager or Admin to record payments
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default EventPaymentPage;
