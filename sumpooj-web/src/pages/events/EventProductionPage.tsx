/**
 * EventProductionPage.tsx — Production Planning Page
 *
 * Phase 4: Production Planning & Inventory Reservation
 *
 * Features:
 * - Full production planning UI
 * - Role-based access control
 * - Integration with event and proposal data
 */
import React, { useState, useMemo, useCallback } from 'react';
import {
  Box,
  Typography,
  Breadcrumbs,
  Link,
  Button,
  Skeleton,
  useTheme,
  alpha,
  Chip,
  Card,
} from '@mui/material';
import {
  NavigateNext as NavIcon,
  Engineering as ProductionIcon,
  ArrowBack as BackIcon,
  Warning as WarningIcon,
  Celebration as EventIcon,
  AddTask as AddTaskIcon,
} from '@mui/icons-material';
import { useNavigate, useParams, Link as RouterLink } from 'react-router-dom';
import { useRBAC } from '../../core/rbac/RBACContext';
import EventProductionPanel from './EventProductionPanel';
import type { EventProductionData } from './ProductionTypes';
import { getProductionForEvent } from './ProductionMockData';
import { MOCK_EVENTS } from './EventMockData';
import { MOCK_PROPOSALS } from './ProposalMockData';
import { PermissionGate } from '../../core/rbac/RBACContext';
import CreateTaskDialog from '../tasks/CreateTaskDialog';

// ─── Loading Skeleton ───────────────────────────────────────

const LoadingSkeleton: React.FC = () => {
  return (
    <Box sx={{ p: { xs: 2, md: 3 } }}>
      <Skeleton variant="text" width={200} height={24} />
      <Skeleton variant="rounded" width="100%" height={150} sx={{ mt: 2, borderRadius: 3 }} />
      <Skeleton variant="rounded" width="100%" height={80} sx={{ mt: 2, borderRadius: 3 }} />
      <Skeleton variant="rounded" width="100%" height={400} sx={{ mt: 2, borderRadius: 3 }} />
    </Box>
  );
};

// ─── Main Component ─────────────────────────────────────────

const EventProductionPage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const { eventId } = useParams<{ eventId: string }>();
  const { canAny, user } = useRBAC();

  // Role-based permissions
  const canModifyReservation = canAny(['inventory:adjust']);
  const canAssignDesigner = canAny(['events:manage']);
  const canUpdateStatus = canAny(['events:view']); // Designers can update status
  const readonly = !canUpdateStatus;

  // State
  const [loading] = useState(false);
  const [taskDialogOpen, setTaskDialogOpen] = useState(false);

  // Get event data
  const event = useMemo(() => {
    return MOCK_EVENTS.find((e) => e.id === eventId);
  }, [eventId]);

  // Get approved proposal for this event
  const proposal = useMemo(() => {
    if (!eventId) return null;
    return MOCK_PROPOSALS.find(
      (p) => p.eventId === eventId && (p.status === 'APPROVED' || p.status === 'SENT')
    );
  }, [eventId]);

  // Get production data
  const [productionData, setProductionData] = useState<EventProductionData | null>(() =>
    eventId ? getProductionForEvent(eventId) : null
  );

  // Handlers
  const handleProductionChange = useCallback((data: EventProductionData) => {
    setProductionData(data);
    // In real app, would call API here
    console.log('Production data updated:', data);
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
        <Typography
          variant="body2"
          sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 3 }}
        >
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
          <Typography sx={{ color: dk ? '#fff' : 'text.primary' }}>Production</Typography>
        </Breadcrumbs>

        {/* Event Header */}
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
              bgcolor: alpha('#ff9800', 0.15),
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <EventIcon sx={{ color: '#ff9800', fontSize: 28 }} />
          </Box>
          <Box sx={{ flex: 1 }}>
            <Typography variant="h5" sx={{ fontWeight: 800 }}>
              {event.eventName}
            </Typography>
            <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
              {event.venueName} •{' '}
              {new Date(event.eventDate).toLocaleDateString('en-IN', {
                day: 'numeric',
                month: 'short',
                year: 'numeric',
              })}
            </Typography>
          </Box>
        </Card>

        {/* No Proposal Message */}
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
            <ProductionIcon sx={{ fontSize: 40, color: '#ff9800' }} />
          </Box>
          <Typography variant="h6" sx={{ fontWeight: 700, mb: 1 }}>
            No Approved Proposal Yet
          </Typography>
          <Typography
            variant="body2"
            sx={{
              color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
              mb: 3,
              maxWidth: 400,
              mx: 'auto',
            }}
          >
            Production planning requires an approved or sent proposal. Create and send a proposal
            first to enable production tracking.
          </Typography>
          <Button
            variant="contained"
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
        <Typography sx={{ color: dk ? '#fff' : 'text.primary' }}>Production</Typography>
      </Breadcrumbs>

      {/* Action bar */}
      <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
        <PermissionGate permission="tasks:manage">
          <Button
            variant="outlined"
            size="small"
            startIcon={<AddTaskIcon />}
            onClick={() => setTaskDialogOpen(true)}
            sx={{ fontWeight: 600, textTransform: 'none' }}
          >
            Create Task
          </Button>
        </PermissionGate>
      </Box>

      {/* Production Panel */}
      <EventProductionPanel
        eventId={eventId!}
        eventName={event.eventName}
        eventDate={event.eventDate}
        venueName={event.venueName}
        productionData={productionData}
        proposalItems={proposal.items}
        onProductionChange={handleProductionChange}
        readonly={readonly}
        canModifyReservation={canModifyReservation}
        canAssignDesigner={canAssignDesigner}
        currentUser={user?.name || 'Current User'}
      />

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
          <Typography
            variant="caption"
            sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}
          >
            Limited access
          </Typography>
        </Box>
      )}

      {/* Create Task Dialog */}
      <CreateTaskDialog
        open={taskDialogOpen}
        onClose={() => setTaskDialogOpen(false)}
        defaults={{
          relatedEntityType: 'EVENT',
          relatedEntityId: eventId ?? '',
        }}
      />
    </Box>
  );
};

export default EventProductionPage;
