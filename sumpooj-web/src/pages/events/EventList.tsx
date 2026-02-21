/**
 * EventList.tsx — Events List Page
 *
 * Features:
 * - Table with all event columns
 * - Search by name/client/venue
 * - Filter by status
 * - Filter by date range
 * - Create New Event button
 * - Responsive layout
 */
import React, { useState, useMemo, useEffect, useCallback } from 'react';
import {
  Box, Typography, TextField, InputAdornment, Button, Chip,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  IconButton, MenuItem, Select, FormControl, InputLabel, Card,
  Grid, useTheme, alpha, Tooltip, TablePagination, Paper,
  CircularProgress,
} from '@mui/material';
import {
  Search as SearchIcon,
  Add as AddIcon,
  Edit as EditIcon,
  Visibility as ViewIcon,
  FilterList as FilterIcon,
  CalendarToday as CalendarIcon,
  Clear as ClearIcon,
  Celebration as EventIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import type { Event, EventStatus, EventType, EventFilters } from './EventTypes';
import {
  EVENT_STATUSES,
  EVENT_TYPES,
  STATUS_CONFIG,
  EVENT_TYPE_CONFIG,
} from './EventTypes';
import { formatCurrency } from '../../core/i18n';
import { searchEvents } from '../../api/event.api';
import { useApiCall } from '../../hooks/useApiCall';

// ─── Currency Formatter ───────────────────────────────────────

const fmtCurrency = (value: number) => formatCurrency(value);

const fmtDate = (dateStr: string) =>
  new Date(dateStr).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });

// ─── Stats Card Component ───────────────────────────────────

interface StatCardProps {
  label: string;
  value: string | number;
  color: string;
  icon?: string;
}

const StatCard: React.FC<StatCardProps> = ({ label, value, color, icon }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Card
      sx={{
        p: 2,
        bgcolor: dk ? alpha(color, 0.1) : alpha(color, 0.08),
        border: `1px solid ${alpha(color, 0.2)}`,
        borderRadius: 2,
      }}
    >
      <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary' }}>
        {label}
      </Typography>
      <Typography variant="h5" sx={{ fontWeight: 700, color, mt: 0.5 }}>
        {icon && <span style={{ marginRight: 8 }}>{icon}</span>}
        {value}
      </Typography>
    </Card>
  );
};

// ─── Status Chip Component ──────────────────────────────────

const StatusChip: React.FC<{ status: EventStatus }> = ({ status }) => {
  const config = STATUS_CONFIG[status];
  return (
    <Chip
      label={`${config.icon} ${config.label}`}
      size="small"
      sx={{
        bgcolor: config.bgColor,
        color: config.color,
        fontWeight: 600,
        fontSize: '0.75rem',
      }}
    />
  );
};

// ─── Event Type Chip Component ──────────────────────────────

const EventTypeChip: React.FC<{ eventType: EventType }> = ({ eventType }) => {
  const config = EVENT_TYPE_CONFIG[eventType];
  return (
    <Chip
      label={`${config.icon} ${config.label}`}
      size="small"
      variant="outlined"
      sx={{
        borderColor: config.color,
        color: config.color,
        fontSize: '0.7rem',
      }}
    />
  );
};

// ─── Main Component ─────────────────────────────────────────

const EventList: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();

  // State
  const [events, setEvents] = useState<Event[]>([]);
  const [filters, setFilters] = useState<EventFilters>({
    search: '',
    status: '',
    eventType: '',
    dateFrom: '',
    dateTo: '',
  });
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [showFilters, setShowFilters] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const { execute, loading } = useApiCall();

  const loadEvents = useCallback(async () => {
    const res = await execute(
      () => searchEvents({
        Query: filters.search || undefined,
        Status: filters.status || undefined,
        EventType: filters.eventType || undefined,
        FromDate: filters.dateFrom || undefined,
        ToDate: filters.dateTo || undefined,
        Page: page + 1,
        PageSize: rowsPerPage,
      }),
      { errorMessage: 'Failed to load events' }
    );
    if (res) {
      setEvents(res.items ?? res ?? []);
      setTotalCount(res.totalCount ?? 0);
    }
  }, [execute, filters, page, rowsPerPage]);

  useEffect(() => {
    loadEvents();
  }, [loadEvents]);

  // Stats — computed locally from loaded events (no separate API endpoint)
  const stats = useMemo(() => {
    const now = new Date();
    const thisMonth = now.getMonth();
    const thisYear = now.getFullYear();
    return {
      total: events.length,
      thisMonth: events.filter((e) => {
        const d = new Date(e.eventDate);
        return d.getMonth() === thisMonth && d.getFullYear() === thisYear;
      }).length,
      inquiries: events.filter((e) => e.status === 'INQUIRY').length,
      confirmed: events.filter((e) => e.status === 'CONFIRMED').length,
      inProduction: events.filter((e) => e.status === 'IN_PRODUCTION').length,
      totalBudget: events
        .filter((e) => e.status !== 'CANCELLED')
        .reduce((sum, e) => sum + (e.budget ?? 0), 0),
    };
  }, [events]);

  // Filtered events
  const filteredEvents = useMemo(() => {
    let list = [...events];

    // Search
    if (filters.search) {
      const q = filters.search.toLowerCase();
      list = list.filter(
        (e) =>
          e.eventName.toLowerCase().includes(q) ||
          e.clientName.toLowerCase().includes(q) ||
          e.venueName.toLowerCase().includes(q)
      );
    }

    // Status filter
    if (filters.status) {
      list = list.filter((e) => e.status === filters.status);
    }

    // Event type filter
    if (filters.eventType) {
      list = list.filter((e) => e.eventType === filters.eventType);
    }

    // Date range filter
    if (filters.dateFrom) {
      list = list.filter((e) => e.eventDate >= filters.dateFrom);
    }
    if (filters.dateTo) {
      list = list.filter((e) => e.eventDate <= filters.dateTo);
    }

    // Sort by event date (upcoming first)
    list.sort((a, b) => new Date(a.eventDate).getTime() - new Date(b.eventDate).getTime());

    return list;
  }, [events, filters]);

  // Paginated events
  const paginatedEvents = useMemo(() => {
    const start = page * rowsPerPage;
    return filteredEvents.slice(start, start + rowsPerPage);
  }, [filteredEvents, page, rowsPerPage]);

  // Handlers
  const clearFilters = () => {
    setFilters({ search: '', status: '', eventType: '', dateFrom: '', dateTo: '' });
  };

  const hasActiveFilters = filters.status || filters.eventType || filters.dateFrom || filters.dateTo;

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1600, mx: 'auto' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3, flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: 1 }}>
            <EventIcon sx={{ color: '#e91e63' }} />
            Events & Weddings
          </Typography>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mt: 0.5 }}>
            Manage all your events, weddings, and bookings
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => navigate('/events/new')}
          sx={{
            bgcolor: '#e91e63',
            '&:hover': { bgcolor: '#c2185b' },
            fontWeight: 700,
            px: 3,
          }}
        >
          New Event
        </Button>
      </Box>

      {/* Stats Row */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard label="Total Events" value={stats.total} color="#9c27b0" />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard label="This Month" value={stats.thisMonth} color="#2196f3" />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard label="Inquiries" value={stats.inquiries} color="#ff9800" icon="📩" />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard label="Confirmed" value={stats.confirmed} color="#4caf50" icon="✅" />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard label="In Production" value={stats.inProduction} color="#9c27b0" icon="🌸" />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard label="Total Value" value={fmtCurrency(stats.totalBudget)} color="#fdd835" />
        </Grid>
      </Grid>

      {/* Search & Filters */}
      <Card
        sx={{
          mb: 3,
          p: 2,
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          borderRadius: 2,
        }}
      >
        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          {/* Search */}
          <TextField
            placeholder="Search events, clients, venues..."
            value={filters.search}
            onChange={(e) => setFilters({ ...filters, search: e.target.value })}
            size="small"
            sx={{ minWidth: 280, flexGrow: 1 }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon sx={{ color: 'text.secondary' }} />
                </InputAdornment>
              ),
            }}
          />

          {/* Toggle Filters */}
          <Button
            variant={showFilters ? 'contained' : 'outlined'}
            startIcon={<FilterIcon />}
            onClick={() => setShowFilters(!showFilters)}
            color={hasActiveFilters ? 'primary' : 'inherit'}
          >
            Filters {hasActiveFilters && `(${[filters.status, filters.eventType, filters.dateFrom, filters.dateTo].filter(Boolean).length})`}
          </Button>

          {hasActiveFilters && (
            <Button variant="text" startIcon={<ClearIcon />} onClick={clearFilters} color="error">
              Clear
            </Button>
          )}
        </Box>

        {/* Expanded Filters */}
        {showFilters && (
          <Box sx={{ display: 'flex', gap: 2, mt: 2, flexWrap: 'wrap' }}>
            <FormControl size="small" sx={{ minWidth: 140 }}>
              <InputLabel>Status</InputLabel>
              <Select
                value={filters.status}
                label="Status"
                onChange={(e) => setFilters({ ...filters, status: e.target.value as EventStatus | '' })}
              >
                <MenuItem value="">All</MenuItem>
                {EVENT_STATUSES.map((s) => (
                  <MenuItem key={s} value={s}>
                    {STATUS_CONFIG[s].icon} {STATUS_CONFIG[s].label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <FormControl size="small" sx={{ minWidth: 140 }}>
              <InputLabel>Event Type</InputLabel>
              <Select
                value={filters.eventType}
                label="Event Type"
                onChange={(e) => setFilters({ ...filters, eventType: e.target.value as EventType | '' })}
              >
                <MenuItem value="">All</MenuItem>
                {EVENT_TYPES.map((t) => (
                  <MenuItem key={t} value={t}>
                    {EVENT_TYPE_CONFIG[t].icon} {EVENT_TYPE_CONFIG[t].label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <TextField
              type="date"
              label="From Date"
              value={filters.dateFrom}
              onChange={(e) => setFilters({ ...filters, dateFrom: e.target.value })}
              size="small"
              InputLabelProps={{ shrink: true }}
              sx={{ minWidth: 150 }}
            />

            <TextField
              type="date"
              label="To Date"
              value={filters.dateTo}
              onChange={(e) => setFilters({ ...filters, dateTo: e.target.value })}
              size="small"
              InputLabelProps={{ shrink: true }}
              sx={{ minWidth: 150 }}
            />
          </Box>
        )}
      </Card>

      {/* Events Table */}
      <Card
        sx={{
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          borderRadius: 2,
          overflow: 'hidden',
        }}
      >
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={{ bgcolor: dk ? 'rgba(255,255,255,0.03)' : '#f5f5f5' }}>
                <TableCell sx={{ fontWeight: 700 }}>Event Name</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Client</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Date</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Type</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Venue</TableCell>
                <TableCell sx={{ fontWeight: 700 }} align="right">Budget</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Designer</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Status</TableCell>
                <TableCell sx={{ fontWeight: 700 }} align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {paginatedEvents.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={9} align="center" sx={{ py: 6 }}>
                    <Typography variant="body1" sx={{ color: 'text.secondary' }}>
                      No events found
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                paginatedEvents.map((event) => (
                  <TableRow
                    key={event.id}
                    hover
                    sx={{
                      cursor: 'pointer',
                      '&:hover': { bgcolor: dk ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)' },
                    }}
                    onClick={() => navigate(`/events/${event.id}`)}
                  >
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {event.eventName}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">{event.clientName}</Typography>
                      <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                        {event.clientPhone}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                        <CalendarIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                        <Typography variant="body2">{fmtDate(event.eventDate)}</Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <EventTypeChip eventType={event.eventType} />
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ maxWidth: 150 }} noWrap>
                        {event.venueName}
                      </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2" sx={{ fontWeight: 600, color: '#fdd835' }}>
                        {event.budget ? fmtCurrency(event.budget) : '—'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {event.assignedDesigner || <span style={{ color: '#999' }}>Unassigned</span>}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <StatusChip status={event.status} />
                    </TableCell>
                    <TableCell align="center">
                      <Box sx={{ display: 'flex', justifyContent: 'center', gap: 0.5 }}>
                        <Tooltip title="View Details">
                          <IconButton
                            size="small"
                            onClick={(e) => {
                              e.stopPropagation();
                              navigate(`/events/${event.id}`);
                            }}
                          >
                            <ViewIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Edit Event">
                          <IconButton
                            size="small"
                            onClick={(e) => {
                              e.stopPropagation();
                              navigate(`/events/${event.id}/edit`);
                            }}
                          >
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>

        {/* Pagination */}
        <TablePagination
          component="div"
          count={filteredEvents.length}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(e) => {
            setRowsPerPage(parseInt(e.target.value, 10));
            setPage(0);
          }}
          rowsPerPageOptions={[5, 10, 25, 50]}
          sx={{ borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}` }}
        />
      </Card>
    </Box>
  );
};

export default EventList;
