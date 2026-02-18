// =============================================================================
// ACTIVITY FEED - Reusable Timeline Component for Audit History
// =============================================================================

import React, { useState } from 'react';
import {
  Box,
  Typography,
  Avatar,
  Chip,
  IconButton,
  Collapse,
  Tooltip,
  alpha,
  Divider,
  Button,
  Card,
  CardContent,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  SwapHoriz,
  CheckCircle,
  Cancel,
  Undo,
  Block,
  Lock,
  LockOpen,
  Info,
  Receipt,
  Event,
  LocalFlorist,
  Payment,
  Inventory2,
  Description,
  Person,
  Badge,
  Settings,
  ExpandMore,
  ExpandLess,
  FilterList,
} from '@mui/icons-material';
import type {
  AuditLog,
  AuditAction,
  AuditEntityType,
} from './AuditTypes';
import {
  getActionColor,
  formatAuditTimestamp,
} from './AuditTypes';

// -----------------------------------------------------------------------------
// Icon Maps
// -----------------------------------------------------------------------------

const ACTION_ICONS: Record<AuditAction, React.ReactNode> = {
  CREATE: <Add fontSize="small" />,
  UPDATE: <Edit fontSize="small" />,
  DELETE: <Delete fontSize="small" />,
  STATUS_CHANGE: <SwapHoriz fontSize="small" />,
  APPROVE: <CheckCircle fontSize="small" />,
  REJECT: <Cancel fontSize="small" />,
  REFUND: <Undo fontSize="small" />,
  VOID: <Block fontSize="small" />,
  LOCK: <Lock fontSize="small" />,
  UNLOCK: <LockOpen fontSize="small" />,
};

const ENTITY_ICONS: Record<AuditEntityType, React.ReactNode> = {
  ORDER: <Receipt fontSize="small" />,
  EVENT: <Event fontSize="small" />,
  PRODUCT: <LocalFlorist fontSize="small" />,
  PAYMENT: <Payment fontSize="small" />,
  INVENTORY: <Inventory2 fontSize="small" />,
  PROPOSAL: <Description fontSize="small" />,
  CUSTOMER: <Person fontSize="small" />,
  STAFF: <Badge fontSize="small" />,
  SETTINGS: <Settings fontSize="small" />,
};

// -----------------------------------------------------------------------------
// Activity Item Component
// -----------------------------------------------------------------------------

interface ActivityItemProps {
  log: AuditLog;
  showEntityType?: boolean;
  isLast?: boolean;
}

function ActivityItem({ log, showEntityType = false, isLast = false }: ActivityItemProps) {
  const [expanded, setExpanded] = useState(false);
  const actionColor = getActionColor(log.action);
  const hasDetails = log.previousValue || log.newValue || log.metadata;
  
  return (
    <Box sx={{ display: 'flex', gap: 2 }}>
      {/* Timeline Line & Dot */}
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          width: 40,
        }}
      >
        <Box
          sx={{
            width: 36,
            height: 36,
            borderRadius: '50%',
            bgcolor: alpha(actionColor, 0.15),
            color: actionColor,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
          }}
        >
          {ACTION_ICONS[log.action] || <Info fontSize="small" />}
        </Box>
        {!isLast && (
          <Box
            sx={{
              width: 2,
              flexGrow: 1,
              bgcolor: alpha('#fff', 0.1),
              mt: 1,
            }}
          />
        )}
      </Box>
      
      {/* Content */}
      <Box sx={{ flex: 1, pb: isLast ? 0 : 3, minWidth: 0 }}>
        {/* Header Row */}
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1, mb: 0.5 }}>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography variant="body2" fontWeight={600} sx={{ mb: 0.25 }}>
              {log.changeSummary}
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
              <Typography variant="caption" color="text.secondary">
                {log.changedByName}
              </Typography>
              <Typography variant="caption" color="text.disabled">
                •
              </Typography>
              <Tooltip title={new Date(log.createdAt).toLocaleString()}>
                <Typography variant="caption" color="text.secondary" sx={{ cursor: 'help' }}>
                  {formatAuditTimestamp(log.createdAt)}
                </Typography>
              </Tooltip>
              {showEntityType && (
                <>
                  <Typography variant="caption" color="text.disabled">
                    •
                  </Typography>
                  <Chip
                    size="small"
                    icon={ENTITY_ICONS[log.entityType]}
                    label={log.entityType}
                    sx={{
                      height: 20,
                      fontSize: '0.65rem',
                      bgcolor: alpha('#fff', 0.05),
                      '& .MuiChip-icon': { fontSize: 12 },
                    }}
                  />
                </>
              )}
            </Box>
          </Box>
          
          {hasDetails && (
            <IconButton
              size="small"
              onClick={() => setExpanded(!expanded)}
              sx={{ color: 'text.secondary' }}
            >
              {expanded ? <ExpandLess fontSize="small" /> : <ExpandMore fontSize="small" />}
            </IconButton>
          )}
        </Box>
        
        {/* Expandable Details */}
        {hasDetails && (
          <Collapse in={expanded}>
            <Box
              sx={{
                mt: 1.5,
                p: 1.5,
                bgcolor: '#0f0f0f',
                borderRadius: 1,
                fontSize: '0.75rem',
              }}
            >
              {log.previousValue && (
                <Box sx={{ mb: 1 }}>
                  <Typography variant="caption" color="text.secondary" display="block" mb={0.5}>
                    Previous Value:
                  </Typography>
                  <Typography
                    variant="caption"
                    component="pre"
                    sx={{
                      fontFamily: 'monospace',
                      whiteSpace: 'pre-wrap',
                      wordBreak: 'break-word',
                      color: '#f44336',
                      m: 0,
                    }}
                  >
                    {JSON.stringify(log.previousValue, null, 2)}
                  </Typography>
                </Box>
              )}
              {log.newValue && (
                <Box sx={{ mb: log.metadata ? 1 : 0 }}>
                  <Typography variant="caption" color="text.secondary" display="block" mb={0.5}>
                    New Value:
                  </Typography>
                  <Typography
                    variant="caption"
                    component="pre"
                    sx={{
                      fontFamily: 'monospace',
                      whiteSpace: 'pre-wrap',
                      wordBreak: 'break-word',
                      color: '#4caf50',
                      m: 0,
                    }}
                  >
                    {JSON.stringify(log.newValue, null, 2)}
                  </Typography>
                </Box>
              )}
              {log.metadata && (
                <Box>
                  <Typography variant="caption" color="text.secondary" display="block" mb={0.5}>
                    Metadata:
                  </Typography>
                  <Typography
                    variant="caption"
                    component="pre"
                    sx={{
                      fontFamily: 'monospace',
                      whiteSpace: 'pre-wrap',
                      wordBreak: 'break-word',
                      color: 'text.secondary',
                      m: 0,
                    }}
                  >
                    {JSON.stringify(log.metadata, null, 2)}
                  </Typography>
                </Box>
              )}
            </Box>
          </Collapse>
        )}
      </Box>
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Activity Feed Component
// -----------------------------------------------------------------------------

interface ActivityFeedProps {
  logs: AuditLog[];
  title?: string;
  showEntityType?: boolean;
  showFilters?: boolean;
  maxItems?: number;
  emptyMessage?: string;
  onLoadMore?: () => void;
  hasMore?: boolean;
  loading?: boolean;
}

export function ActivityFeed({
  logs,
  title = 'Activity History',
  showEntityType = false,
  showFilters = false,
  maxItems,
  emptyMessage = 'No activity recorded',
  onLoadMore,
  hasMore = false,
  loading = false,
}: ActivityFeedProps) {
  const [filter, setFilter] = useState<AuditAction | 'ALL'>('ALL');
  
  const filteredLogs = filter === 'ALL'
    ? logs
    : logs.filter((log) => log.action === filter);
  
  const displayLogs = maxItems ? filteredLogs.slice(0, maxItems) : filteredLogs;
  
  const actionCounts = logs.reduce((acc, log) => {
    acc[log.action] = (acc[log.action] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);
  
  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="subtitle1" fontWeight={600}>
          {title}
        </Typography>
        
        {showFilters && logs.length > 0 && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <FilterList sx={{ fontSize: 16, color: 'text.secondary', mr: 0.5 }} />
            <Chip
              label="All"
              size="small"
              onClick={() => setFilter('ALL')}
              sx={{
                height: 24,
                bgcolor: filter === 'ALL' ? alpha('#fdd835', 0.2) : alpha('#fff', 0.05),
                color: filter === 'ALL' ? '#fdd835' : 'text.secondary',
              }}
            />
            {Object.entries(actionCounts).slice(0, 4).map(([action, count]) => (
              <Chip
                key={action}
                label={`${action} (${count})`}
                size="small"
                onClick={() => setFilter(action as AuditAction)}
                sx={{
                  height: 24,
                  bgcolor: filter === action ? alpha(getActionColor(action as AuditAction), 0.2) : alpha('#fff', 0.05),
                  color: filter === action ? getActionColor(action as AuditAction) : 'text.secondary',
                  textTransform: 'capitalize',
                  fontSize: '0.7rem',
                }}
              />
            ))}
          </Box>
        )}
      </Box>
      
      {/* Activity List */}
      {displayLogs.length === 0 ? (
        <Box
          sx={{
            p: 4,
            textAlign: 'center',
            bgcolor: '#0f0f0f',
            borderRadius: 2,
          }}
        >
          <Info sx={{ fontSize: 40, color: 'text.disabled', mb: 1 }} />
          <Typography variant="body2" color="text.secondary">
            {emptyMessage}
          </Typography>
        </Box>
      ) : (
        <Box>
          {displayLogs.map((log, index) => (
            <ActivityItem
              key={log.id}
              log={log}
              showEntityType={showEntityType}
              isLast={index === displayLogs.length - 1 && !hasMore}
            />
          ))}
          
          {(hasMore || (maxItems && filteredLogs.length > maxItems)) && (
            <Box sx={{ textAlign: 'center', pt: 2 }}>
              <Button
                size="small"
                onClick={onLoadMore}
                disabled={loading}
                sx={{ color: '#fdd835' }}
              >
                {loading ? 'Loading...' : `Load More (${filteredLogs.length - displayLogs.length} remaining)`}
              </Button>
            </Box>
          )}
        </Box>
      )}
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Compact Activity Card (for use in detail pages)
// -----------------------------------------------------------------------------

interface ActivityCardProps {
  logs: AuditLog[];
  entityType: AuditEntityType;
  entityId: string;
  maxItems?: number;
}

export function ActivityCard({ logs, entityType, entityId, maxItems = 5 }: ActivityCardProps) {
  const filteredLogs = logs.filter(
    (log) => log.entityType === entityType && log.entityId === entityId
  );
  
  return (
    <Card sx={{ bgcolor: '#1a1a2e' }}>
      <CardContent>
        <ActivityFeed
          logs={filteredLogs}
          title="Recent Activity"
          maxItems={maxItems}
          emptyMessage="No activity for this item"
        />
      </CardContent>
    </Card>
  );
}

// -----------------------------------------------------------------------------
// Activity Summary Badge
// -----------------------------------------------------------------------------

interface ActivitySummaryProps {
  logs: AuditLog[];
  compact?: boolean;
}

export function ActivitySummary({ logs, compact = false }: ActivitySummaryProps) {
  if (logs.length === 0) return null;
  
  const latestLog = logs[0];
  const actionColor = getActionColor(latestLog.action);
  
  if (compact) {
    return (
      <Tooltip title={`Last activity: ${latestLog.changeSummary}`}>
        <Chip
          size="small"
          icon={ACTION_ICONS[latestLog.action] as React.ReactElement}
          label={formatAuditTimestamp(latestLog.createdAt)}
          sx={{
            height: 22,
            fontSize: '0.7rem',
            bgcolor: alpha(actionColor, 0.15),
            color: actionColor,
            '& .MuiChip-icon': { color: actionColor },
          }}
        />
      </Tooltip>
    );
  }
  
  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
      <Box
        sx={{
          width: 24,
          height: 24,
          borderRadius: '50%',
          bgcolor: alpha(actionColor, 0.15),
          color: actionColor,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {ACTION_ICONS[latestLog.action]}
      </Box>
      <Box>
        <Typography variant="caption" display="block" color="text.secondary">
          Last activity {formatAuditTimestamp(latestLog.createdAt)}
        </Typography>
        <Typography variant="caption" color="text.primary">
          {latestLog.changeSummary}
        </Typography>
      </Box>
    </Box>
  );
}
