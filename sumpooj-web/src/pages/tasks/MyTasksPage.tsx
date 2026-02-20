/**
 * MyTasksPage.tsx — Staff Task Dashboard
 *
 * Features:
 * - Staff sees own tasks
 * - Manager/Admin sees all tasks
 * - Driver sees delivery-related tasks
 * - Filter by status
 * - Large clear status toggles
 * - Related entity links
 * - Clean simple UI
 */
import React, { useState, useMemo, useCallback } from 'react';
import {
  Box, Typography, Card, Chip, Button, IconButton,
  ToggleButtonGroup, ToggleButton, Tooltip, Avatar,
  useTheme, alpha, Grid,
} from '@mui/material';
import {
  AddTask as AddTaskIcon,
  CheckCircle as DoneIcon,
  PlayArrow as StartIcon,
  Undo as UndoIcon,
  Assignment as TaskIcon,
  LocalShipping as DeliveryIcon,
  Celebration as EventIcon,
  Receipt as OrderIcon,
  Schedule as ClockIcon,
  Flag as PriorityIcon,
} from '@mui/icons-material';
import { useRBAC } from '../../core/rbac/RBACContext';
import { MOCK_LOCATIONS } from '../../core/location/LocationTypes';
import { getAllStaff } from '../staff/StaffMockData';
import type { Task, TaskStatus, TaskFilterStatus, RelatedEntityType } from './TaskTypes';
import {
  TASK_STATUSES, TASK_STATUS_CONFIG,
  TASK_PRIORITY_CONFIG, ENTITY_TYPE_CONFIG,
} from './TaskTypes';
import {
  getAllTasks, getTasksForStaff, getDeliveryTasks,
  updateTaskStatus, getTaskSummary,
} from './TaskMockData';
import CreateTaskDialog from './CreateTaskDialog';

// ─── Entity Icon Mapping ────────────────────────────────────

const ENTITY_ICONS: Record<RelatedEntityType, React.ReactNode> = {
  ORDER: <OrderIcon sx={{ fontSize: 16 }} />,
  EVENT: <EventIcon sx={{ fontSize: 16 }} />,
  DELIVERY: <DeliveryIcon sx={{ fontSize: 16 }} />,
};

// ─── Status Action Config ───────────────────────────────────

const getNextStatus = (current: TaskStatus): TaskStatus | null => {
  switch (current) {
    case 'PENDING': return 'IN_PROGRESS';
    case 'IN_PROGRESS': return 'COMPLETED';
    case 'COMPLETED': return null;
  }
};

const getStatusAction = (current: TaskStatus): { label: string; icon: React.ReactNode; color: string } | null => {
  switch (current) {
    case 'PENDING':
      return { label: 'Start', icon: <StartIcon />, color: '#2196f3' };
    case 'IN_PROGRESS':
      return { label: 'Complete', icon: <DoneIcon />, color: '#4caf50' };
    case 'COMPLETED':
      return null;
  }
};

// ─── Stat Card ──────────────────────────────────────────────

interface StatCardProps {
  label: string;
  value: number;
  color: string;
  active?: boolean;
  onClick?: () => void;
}

const StatCard: React.FC<StatCardProps> = ({ label, value, color, active, onClick }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Card
      onClick={onClick}
      sx={{
        p: 2,
        cursor: onClick ? 'pointer' : 'default',
        bgcolor: active
          ? alpha(color, dk ? 0.2 : 0.12)
          : dk ? '#1a1a2e' : '#fff',
        border: `1px solid ${active ? alpha(color, 0.4) : dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        borderRadius: 2,
        transition: 'all 0.2s',
        '&:hover': onClick ? {
          borderColor: alpha(color, 0.5),
          transform: 'translateY(-1px)',
          boxShadow: `0 4px 12px ${alpha(color, 0.15)}`,
        } : {},
      }}
    >
      <Typography
        variant="caption"
        sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', fontWeight: 600 }}
      >
        {label}
      </Typography>
      <Typography variant="h4" sx={{ fontWeight: 800, color, mt: 0.25 }}>
        {value}
      </Typography>
    </Card>
  );
};

// ─── Task Card Component ────────────────────────────────────

interface TaskCardProps {
  task: Task;
  showAssignee: boolean;
  onStatusChange: (taskId: string, newStatus: TaskStatus) => void;
}

const TaskCard: React.FC<TaskCardProps> = ({ task, showAssignee, onStatusChange }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const statusConfig = TASK_STATUS_CONFIG[task.status];
  const priorityConfig = task.priority ? TASK_PRIORITY_CONFIG[task.priority] : null;
  const entityConfig = task.relatedEntityType ? ENTITY_TYPE_CONFIG[task.relatedEntityType] : null;
  const action = getStatusAction(task.status);
  const nextStatus = getNextStatus(task.status);

  const assignee = useMemo(() => {
    return getAllStaff().find((s) => s.id === task.assignedTo);
  }, [task.assignedTo]);

  const location = useMemo(() => {
    return MOCK_LOCATIONS.find((l) => l.id === task.locationId);
  }, [task.locationId]);

  const isOverdue = task.dueDate && task.status !== 'COMPLETED' &&
    new Date(task.dueDate) < new Date(new Date().toISOString().split('T')[0]);

  return (
    <Card
      sx={{
        p: 2.5,
        bgcolor: dk ? '#1a1a2e' : '#fff',
        border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        borderLeft: `4px solid ${statusConfig.color}`,
        borderRadius: 2,
        opacity: task.status === 'COMPLETED' ? 0.7 : 1,
        transition: 'all 0.2s',
        '&:hover': {
          borderColor: alpha(statusConfig.color, 0.4),
          boxShadow: `0 2px 8px ${alpha(statusConfig.color, 0.1)}`,
        },
      }}
    >
      {/* Top row: Title + Priority + Status */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 1, mb: 1.5 }}>
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Typography
            variant="subtitle1"
            sx={{
              fontWeight: 700,
              textDecoration: task.status === 'COMPLETED' ? 'line-through' : 'none',
              color: task.status === 'COMPLETED'
                ? (dk ? 'rgba(255,255,255,0.4)' : 'text.disabled')
                : (dk ? '#fff' : 'text.primary'),
            }}
          >
            {task.title}
          </Typography>
          {task.description && (
            <Typography
              variant="body2"
              sx={{
                color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
                mt: 0.5,
                overflow: 'hidden',
                textOverflow: 'ellipsis',
                display: '-webkit-box',
                WebkitLineClamp: 2,
                WebkitBoxOrient: 'vertical',
              }}
            >
              {task.description}
            </Typography>
          )}
        </Box>

        {/* Status toggle button — LARGE & CLEAR */}
        {action && nextStatus && (
          <Tooltip title={`Mark as ${TASK_STATUS_CONFIG[nextStatus].label}`}>
            <Button
              variant="contained"
              size="small"
              startIcon={action.icon}
              onClick={() => onStatusChange(task.id, nextStatus)}
              sx={{
                bgcolor: action.color,
                '&:hover': { bgcolor: alpha(action.color, 0.85) },
                fontWeight: 700,
                minWidth: 110,
                height: 40,
                fontSize: '0.85rem',
                textTransform: 'none',
                borderRadius: 2,
                boxShadow: `0 2px 8px ${alpha(action.color, 0.3)}`,
                flexShrink: 0,
              }}
            >
              {action.label}
            </Button>
          </Tooltip>
        )}

        {task.status === 'COMPLETED' && (
          <Tooltip title="Reopen as In Progress">
            <IconButton
              size="small"
              onClick={() => onStatusChange(task.id, 'IN_PROGRESS')}
              sx={{ color: '#ff9800' }}
            >
              <UndoIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        )}
      </Box>

      {/* Metadata row */}
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, alignItems: 'center' }}>
        {/* Status chip */}
        <Chip
          label={`${statusConfig.icon} ${statusConfig.label}`}
          size="small"
          sx={{
            bgcolor: alpha(statusConfig.color, 0.15),
            color: statusConfig.color,
            fontWeight: 600,
            fontSize: '0.72rem',
          }}
        />

        {/* Priority */}
        {priorityConfig && (
          <Chip
            icon={<PriorityIcon sx={{ fontSize: 14, color: `${priorityConfig.color} !important` }} />}
            label={priorityConfig.label}
            size="small"
            sx={{
              bgcolor: alpha(priorityConfig.color, 0.12),
              color: priorityConfig.color,
              fontWeight: 600,
              fontSize: '0.72rem',
            }}
          />
        )}

        {/* Related entity */}
        {entityConfig && (
          <Chip
            icon={<Box sx={{ display: 'flex', ml: 0.5 }}>{ENTITY_ICONS[task.relatedEntityType!]}</Box>}
            label={`${entityConfig.label}${task.relatedEntityId ? `: ${task.relatedEntityId}` : ''}`}
            size="small"
            sx={{
              bgcolor: alpha(entityConfig.color, 0.12),
              color: entityConfig.color,
              fontWeight: 600,
              fontSize: '0.72rem',
            }}
          />
        )}

        {/* Due date */}
        {task.dueDate && (
          <Chip
            icon={<ClockIcon sx={{ fontSize: 14, color: isOverdue ? '#f44336 !important' : undefined }} />}
            label={new Date(task.dueDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}
            size="small"
            sx={{
              bgcolor: isOverdue ? alpha('#f44336', 0.12) : alpha('#9e9e9e', 0.1),
              color: isOverdue ? '#f44336' : dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
              fontWeight: 600,
              fontSize: '0.72rem',
            }}
          />
        )}

        {/* Assignee (shown for admin/manager) */}
        {showAssignee && assignee && (
          <Chip
            avatar={
              <Avatar sx={{ width: 20, height: 20, fontSize: '0.65rem', bgcolor: alpha('#7c4dff', 0.2), color: '#7c4dff' }}>
                {assignee.name.charAt(0)}
              </Avatar>
            }
            label={assignee.name}
            size="small"
            variant="outlined"
            sx={{
              fontWeight: 500,
              fontSize: '0.72rem',
              borderColor: dk ? 'rgba(255,255,255,0.12)' : '#e0e0e0',
            }}
          />
        )}

        {/* Location (shown for admin/manager) */}
        {showAssignee && location && (
          <Chip
            label={location.name.split(' - ')[1] || location.name}
            size="small"
            variant="outlined"
            sx={{
              fontWeight: 500,
              fontSize: '0.68rem',
              borderColor: dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0',
              color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
            }}
          />
        )}
      </Box>
    </Card>
  );
};

// ─── Main Page Component ────────────────────────────────────

const MyTasksPage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const { user, role, can } = useRBAC();

  const [filterStatus, setFilterStatus] = useState<TaskFilterStatus>('ALL');
  const [createOpen, setCreateOpen] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

  // Role-based task visibility
  const isManagerOrAdmin = role === 'ADMIN' || role === 'MANAGER';
  const isDriver = role === 'DRIVER';

  const rawTasks = useMemo(() => {
    if (isManagerOrAdmin) return getAllTasks();
    if (isDriver) return getDeliveryTasks().filter((t) => t.assignedTo === user?.id?.replace('user-', 'staff-'));
    // Staff sees own tasks
    const staffId = user?.id?.replace('user-', 'staff-') ?? '';
    return getTasksForStaff(staffId);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isManagerOrAdmin, isDriver, user?.id, refreshKey]);

  const filteredTasks = useMemo(() => {
    if (filterStatus === 'ALL') return rawTasks;
    return rawTasks.filter((t) => t.status === filterStatus);
  }, [rawTasks, filterStatus]);

  // Sort: overdue first, then by priority (HIGH > MEDIUM > LOW), then by due date
  const sortedTasks = useMemo(() => {
    const priorityOrder: Record<string, number> = { HIGH: 0, MEDIUM: 1, LOW: 2 };
    const today = new Date().toISOString().split('T')[0];

    return [...filteredTasks].sort((a, b) => {
      // Completed always last
      if (a.status === 'COMPLETED' && b.status !== 'COMPLETED') return 1;
      if (b.status === 'COMPLETED' && a.status !== 'COMPLETED') return -1;

      // Overdue first
      const aOverdue = a.dueDate && a.dueDate < today ? 1 : 0;
      const bOverdue = b.dueDate && b.dueDate < today ? 1 : 0;
      if (aOverdue !== bOverdue) return bOverdue - aOverdue;

      // Priority
      const aPri = priorityOrder[a.priority ?? 'MEDIUM'] ?? 1;
      const bPri = priorityOrder[b.priority ?? 'MEDIUM'] ?? 1;
      if (aPri !== bPri) return aPri - bPri;

      // Due date (earliest first)
      if (a.dueDate && b.dueDate) return a.dueDate.localeCompare(b.dueDate);
      if (a.dueDate) return -1;
      if (b.dueDate) return 1;

      return 0;
    });
  }, [filteredTasks]);

  const summary = useMemo(() => getTaskSummary(), [refreshKey]);

  const handleStatusChange = useCallback((taskId: string, newStatus: TaskStatus) => {
    updateTaskStatus(taskId, newStatus);
    setRefreshKey((k) => k + 1);
  }, []);

  const handleTaskCreated = useCallback(() => {
    setRefreshKey((k) => k + 1);
  }, []);

  const pageTitle = isManagerOrAdmin ? 'All Tasks' : 'My Tasks';
  const pageSubtitle = isManagerOrAdmin
    ? 'Manage and assign work across all staff'
    : isDriver
      ? 'Your delivery assignments'
      : 'Your assigned work items';

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1200, mx: 'auto' }}>
      {/* Header */}
      <Box
        sx={{
          display: 'flex', justifyContent: 'space-between',
          alignItems: 'flex-start', mb: 3, flexWrap: 'wrap', gap: 2,
        }}
      >
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: 1 }}>
            <TaskIcon sx={{ color: '#7c4dff' }} />
            {pageTitle}
          </Typography>
          <Typography
            variant="body2"
            sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mt: 0.5 }}
          >
            {pageSubtitle}
          </Typography>
        </Box>

        {can('staff:manage') && (
          <Button
            variant="contained"
            startIcon={<AddTaskIcon />}
            onClick={() => setCreateOpen(true)}
            sx={{
              bgcolor: '#7c4dff',
              '&:hover': { bgcolor: '#651fff' },
              fontWeight: 700,
              px: 3,
            }}
          >
            Create Task
          </Button>
        )}
      </Box>

      {/* Stats Row */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="Total"
            value={summary.total}
            color="#7c4dff"
            active={filterStatus === 'ALL'}
            onClick={() => setFilterStatus('ALL')}
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="Pending"
            value={summary.pending}
            color="#ff9800"
            active={filterStatus === 'PENDING'}
            onClick={() => setFilterStatus('PENDING')}
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="In Progress"
            value={summary.inProgress}
            color="#2196f3"
            active={filterStatus === 'IN_PROGRESS'}
            onClick={() => setFilterStatus('IN_PROGRESS')}
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="Completed"
            value={summary.completed}
            color="#4caf50"
            active={filterStatus === 'COMPLETED'}
            onClick={() => setFilterStatus('COMPLETED')}
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="High Priority"
            value={summary.highPriority}
            color="#f44336"
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="Due Today"
            value={summary.dueToday}
            color="#e91e63"
          />
        </Grid>
      </Grid>

      {/* Filter Toggle */}
      <Box sx={{ mb: 3 }}>
        <ToggleButtonGroup
          value={filterStatus}
          exclusive
          onChange={(_, val) => { if (val !== null) setFilterStatus(val); }}
          size="small"
          sx={{
            '& .MuiToggleButton-root': {
              textTransform: 'none',
              fontWeight: 600,
              px: 2.5,
              '&.Mui-selected': {
                bgcolor: alpha('#7c4dff', dk ? 0.2 : 0.1),
                color: '#7c4dff',
                '&:hover': { bgcolor: alpha('#7c4dff', dk ? 0.25 : 0.15) },
              },
            },
          }}
        >
          <ToggleButton value="ALL">All</ToggleButton>
          {TASK_STATUSES.map((s) => (
            <ToggleButton key={s} value={s}>
              {TASK_STATUS_CONFIG[s].icon} {TASK_STATUS_CONFIG[s].label}
            </ToggleButton>
          ))}
        </ToggleButtonGroup>
      </Box>

      {/* Task List */}
      {sortedTasks.length === 0 ? (
        <Card
          sx={{
            p: 6,
            textAlign: 'center',
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
            borderRadius: 2,
          }}
        >
          <TaskIcon sx={{ fontSize: 48, color: dk ? 'rgba(255,255,255,0.2)' : '#ccc', mb: 1 }} />
          <Typography variant="h6" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            No tasks found
          </Typography>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.3)' : 'text.disabled', mt: 0.5 }}>
            {filterStatus !== 'ALL'
              ? `No ${TASK_STATUS_CONFIG[filterStatus as TaskStatus].label.toLowerCase()} tasks`
              : 'Create a task to get started'}
          </Typography>
        </Card>
      ) : (
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
          {sortedTasks.map((task) => (
            <TaskCard
              key={task.id}
              task={task}
              showAssignee={isManagerOrAdmin}
              onStatusChange={handleStatusChange}
            />
          ))}
        </Box>
      )}

      {/* Create Task Dialog */}
      <CreateTaskDialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        onCreated={handleTaskCreated}
      />
    </Box>
  );
};

export default MyTasksPage;
