/**
 * ProductionChecklist.tsx — Production Checklist Component
 *
 * Features:
 * - Large clickable checkboxes
 * - Completion timestamp display
 * - Progress indicator
 * - Role-based editing
 */
import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  LinearProgress,
  Collapse,
  useTheme,
  alpha,
  Tooltip,
} from '@mui/material';
import {
  CheckCircle as CheckedIcon,
  RadioButtonUnchecked as UncheckedIcon,
  ExpandMore as ExpandIcon,
  ExpandLess as CollapseIcon,
  Person as PersonIcon,
  Schedule as TimeIcon,
} from '@mui/icons-material';
import type { ChecklistItem } from './ProductionTypes';
import { calculateChecklistProgress } from './ProductionTypes';

// ─── Formatting Utilities ───────────────────────────────────

const formatDate = (date: string): string => {
  return new Date(date).toLocaleDateString('en-IN', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
};

// ─── Props ──────────────────────────────────────────────────

interface ProductionChecklistProps {
  checklist: ChecklistItem[];
  onToggle: (itemId: string) => void;
  readonly?: boolean;
  collapsed?: boolean;
  onCollapseToggle?: () => void;
  currentUser?: string;
}

// ─── Checklist Item Row ─────────────────────────────────────

interface ChecklistItemRowProps {
  item: ChecklistItem;
  onToggle: () => void;
  readonly?: boolean;
}

const ChecklistItemRow: React.FC<ChecklistItemRowProps> = ({
  item,
  onToggle,
  readonly = false,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Box
      onClick={readonly ? undefined : onToggle}
      sx={{
        display: 'flex',
        alignItems: 'flex-start',
        gap: 2,
        p: 2,
        borderRadius: 2,
        cursor: readonly ? 'default' : 'pointer',
        backgroundColor: item.completed
          ? alpha('#4caf50', 0.08)
          : dk
            ? 'rgba(255,255,255,0.03)'
            : 'rgba(0,0,0,0.02)',
        border: 1,
        borderColor: item.completed
          ? alpha('#4caf50', 0.3)
          : dk
            ? 'rgba(255,255,255,0.08)'
            : 'rgba(0,0,0,0.08)',
        transition: 'all 0.2s',
        '&:hover': readonly
          ? {}
          : {
              backgroundColor: item.completed
                ? alpha('#4caf50', 0.12)
                : dk
                  ? 'rgba(255,255,255,0.06)'
                  : 'rgba(0,0,0,0.04)',
              transform: 'translateY(-1px)',
            },
        mb: 1.5,
      }}
    >
      {/* Large Checkbox */}
      <Box
        sx={{
          width: 48,
          height: 48,
          borderRadius: '50%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexShrink: 0,
          backgroundColor: item.completed
            ? alpha('#4caf50', 0.15)
            : dk
              ? 'rgba(255,255,255,0.05)'
              : 'rgba(0,0,0,0.05)',
          transition: 'all 0.2s',
        }}
      >
        {item.completed ? (
          <CheckedIcon sx={{ fontSize: 32, color: '#4caf50' }} />
        ) : (
          <UncheckedIcon sx={{ fontSize: 32, color: dk ? 'rgba(255,255,255,0.3)' : 'rgba(0,0,0,0.3)' }} />
        )}
      </Box>

      {/* Label and Details */}
      <Box sx={{ flex: 1, minWidth: 0 }}>
        <Typography
          variant="subtitle1"
          sx={{
            fontWeight: 600,
            color: item.completed
              ? '#4caf50'
              : dk
                ? '#fff'
                : 'text.primary',
            textDecoration: item.completed ? 'line-through' : 'none',
            opacity: item.completed ? 0.8 : 1,
          }}
        >
          {item.label}
        </Typography>

        {/* Completion Info */}
        {item.completed && item.completedAt && (
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 2,
              mt: 0.5,
              flexWrap: 'wrap',
            }}
          >
            {item.completedBy && (
              <Tooltip title="Completed by">
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                  <PersonIcon sx={{ fontSize: 14, color: '#4caf50', opacity: 0.7 }} />
                  <Typography
                    variant="caption"
                    sx={{ color: '#4caf50', opacity: 0.8 }}
                  >
                    {item.completedBy}
                  </Typography>
                </Box>
              </Tooltip>
            )}
            <Tooltip title="Completed at">
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <TimeIcon sx={{ fontSize: 14, color: '#4caf50', opacity: 0.7 }} />
                <Typography
                  variant="caption"
                  sx={{ color: '#4caf50', opacity: 0.8 }}
                >
                  {formatDate(item.completedAt)}
                </Typography>
              </Box>
            </Tooltip>
          </Box>
        )}
      </Box>

      {/* Step Number */}
      <Box
        sx={{
          width: 28,
          height: 28,
          borderRadius: '50%',
          backgroundColor: item.completed
            ? alpha('#4caf50', 0.2)
            : dk
              ? 'rgba(255,255,255,0.1)'
              : 'rgba(0,0,0,0.08)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexShrink: 0,
        }}
      >
        <Typography
          variant="caption"
          sx={{
            fontWeight: 700,
            color: item.completed
              ? '#4caf50'
              : dk
                ? 'rgba(255,255,255,0.5)'
                : 'rgba(0,0,0,0.5)',
          }}
        >
          {item.order}
        </Typography>
      </Box>
    </Box>
  );
};

// ─── Main Component ─────────────────────────────────────────

const ProductionChecklist: React.FC<ProductionChecklistProps> = ({
  checklist,
  onToggle,
  readonly = false,
  collapsed: externalCollapsed,
  onCollapseToggle,
  currentUser: _currentUser = 'Current User',
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const [internalCollapsed, setInternalCollapsed] = useState(false);

  const collapsed = externalCollapsed ?? internalCollapsed;
  const handleCollapseToggle = onCollapseToggle ?? (() => setInternalCollapsed(!internalCollapsed));

  // Sort by order
  const sortedChecklist = [...checklist].sort((a, b) => a.order - b.order);
  const progress = calculateChecklistProgress(checklist);
  const completedCount = checklist.filter((c) => c.completed).length;

  return (
    <Paper
      sx={{
        bgcolor: dk ? '#1a1a2e' : '#fff',
        borderRadius: 3,
        overflow: 'hidden',
      }}
    >
      {/* Header */}
      <Box
        onClick={handleCollapseToggle}
        sx={{
          p: 2.5,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          cursor: 'pointer',
          borderBottom: collapsed ? 'none' : 1,
          borderColor: dk ? 'rgba(255,255,255,0.08)' : 'divider',
          '&:hover': {
            backgroundColor: dk ? 'rgba(255,255,255,0.02)' : 'rgba(0,0,0,0.02)',
          },
        }}
      >
        <Box sx={{ flex: 1 }}>
          <Typography variant="h6" sx={{ fontWeight: 700, mb: 0.5 }}>
            Production Checklist
          </Typography>
          <Typography
            variant="body2"
            sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}
          >
            {completedCount} of {checklist.length} tasks complete
          </Typography>
        </Box>

        {/* Progress Circle */}
        <Box
          sx={{
            width: 48,
            height: 48,
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor:
              progress === 100
                ? alpha('#4caf50', 0.15)
                : progress > 0
                  ? alpha('#ff9800', 0.15)
                  : dk
                    ? 'rgba(255,255,255,0.05)'
                    : 'rgba(0,0,0,0.05)',
            mr: 1,
          }}
        >
          <Typography
            variant="subtitle2"
            sx={{
              fontWeight: 700,
              color:
                progress === 100
                  ? '#4caf50'
                  : progress > 0
                    ? '#ff9800'
                    : dk
                      ? 'rgba(255,255,255,0.5)'
                      : 'text.secondary',
            }}
          >
            {progress}%
          </Typography>
        </Box>

        {collapsed ? (
          <ExpandIcon sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }} />
        ) : (
          <CollapseIcon sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }} />
        )}
      </Box>

      {/* Progress Bar */}
      <LinearProgress
        variant="determinate"
        value={progress}
        sx={{
          height: 4,
          backgroundColor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.08)',
          '& .MuiLinearProgress-bar': {
            backgroundColor: progress === 100 ? '#4caf50' : '#fdd835',
          },
        }}
      />

      {/* Checklist Items */}
      <Collapse in={!collapsed}>
        <Box sx={{ p: 2.5, pt: 2 }}>
          {sortedChecklist.map((item) => (
            <ChecklistItemRow
              key={item.id}
              item={item}
              onToggle={() => onToggle(item.id)}
              readonly={readonly}
            />
          ))}

          {/* Completion Message */}
          {progress === 100 && (
            <Box
              sx={{
                mt: 2,
                p: 2,
                borderRadius: 2,
                backgroundColor: alpha('#4caf50', 0.1),
                border: 1,
                borderColor: alpha('#4caf50', 0.3),
                textAlign: 'center',
              }}
            >
              <Typography
                variant="subtitle2"
                sx={{ color: '#4caf50', fontWeight: 600 }}
              >
                🎉 All tasks complete! Ready for delivery.
              </Typography>
            </Box>
          )}
        </Box>
      </Collapse>
    </Paper>
  );
};

export default ProductionChecklist;
