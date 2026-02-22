/**
 * AuditLogsPage.tsx — Audit Logs Viewer UI
 *
 * Features:
 * - View all audit logs with filters
 * - Filter by user, action, entity type, date range
 * - View detailed log entries
 * - Summary statistics
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
  useTheme,
  alpha,
  InputAdornment,
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  TableContainer,
  TablePagination,
  Collapse,
} from '@mui/material';
import {
  Search,
  History,
  Person,
  CheckCircle,
  Error,
  Refresh,
  FilterList,
  ExpandMore,
  ExpandLess,
  Visibility,
  Schedule,
  Computer,
  Description,
} from '@mui/icons-material';
import {
  type AuditLogSearchParams,
  searchAuditLogs,
  getAuditLogById,
  getAuditLogSummary,
} from '../../api/audit-log.api';
import { useToast } from '../../hooks/useToast';

// ─── Types ──────────────────────────────────────────────────

interface AuditLogDto {
  id: string;
  userId: string | null;
  userName: string | null;
  userRole: string | null;
  action: string;
  entityType: string;
  entityId: string | null;
  entityName: string | null;
  description: string | null;
  oldValues: string | null;
  newValues: string | null;
  ipAddress: string | null;
  userAgent: string | null;
  requestPath: string | null;
  httpMethod: string | null;
  isSuccess: boolean;
  errorMessage: string | null;
  durationMs: number | null;
  timestamp: string;
}

interface AuditLogSummary {
  totalLogs: number;
  successCount: number;
  failureCount: number;
  uniqueUsers: number;
  topActions: { action: string; count: number }[];
  topEntities: { entityType: string; count: number }[];
}

// ─── Action Colors ──────────────────────────────────────────

const ACTION_COLORS: Record<string, string> = {
  Create: '#4caf50',
  Update: '#2196f3',
  Delete: '#f44336',
  Login: '#9c27b0',
  Logout: '#ff9800',
  View: '#00bcd4',
};

const getActionColor = (action: string) => {
  const key = Object.keys(ACTION_COLORS).find((k) => action.toLowerCase().includes(k.toLowerCase()));
  return key ? ACTION_COLORS[key] : '#757575';
};

// ─── Log Detail Dialog ──────────────────────────────────────

interface LogDetailDialogProps {
  open: boolean;
  onClose: () => void;
  log: AuditLogDto | null;
}

const LogDetailDialog: React.FC<LogDetailDialogProps> = ({ open, onClose, log }) => {
  const theme = useTheme();

  if (!log) return null;

  const renderJsonValue = (value: string | null, label: string) => {
    if (!value) return null;
    try {
      const parsed = JSON.parse(value);
      return (
        <Box mb={2}>
          <Typography variant="subtitle2" gutterBottom>{label}</Typography>
          <Paper variant="outlined" sx={{ p: 2, bgcolor: alpha(theme.palette.background.default, 0.5) }}>
            <pre style={{ margin: 0, overflow: 'auto', fontSize: '0.75rem' }}>
              {JSON.stringify(parsed, null, 2)}
            </pre>
          </Paper>
        </Box>
      );
    } catch {
      return (
        <Box mb={2}>
          <Typography variant="subtitle2" gutterBottom>{label}</Typography>
          <Typography variant="body2">{value}</Typography>
        </Box>
      );
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Stack direction="row" spacing={1} alignItems="center">
          <History />
          <Typography variant="h6">Audit Log Details</Typography>
        </Stack>
      </DialogTitle>

      <DialogContent dividers>
        <Grid container spacing={3}>
          {/* Basic Info */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Typography variant="subtitle2" color="text.secondary">Action</Typography>
            <Chip
              label={log.action}
              size="small"
              sx={{ bgcolor: alpha(getActionColor(log.action), 0.1), color: getActionColor(log.action) }}
            />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <Typography variant="subtitle2" color="text.secondary">Status</Typography>
            {log.isSuccess ? (
              <Chip icon={<CheckCircle />} label="Success" size="small" color="success" />
            ) : (
              <Chip icon={<Error />} label="Failed" size="small" color="error" />
            )}
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <Typography variant="subtitle2" color="text.secondary">User</Typography>
            <Typography variant="body1">{log.userName || 'System'}</Typography>
            {log.userRole && (
              <Chip label={log.userRole} size="small" variant="outlined" sx={{ mt: 0.5 }} />
            )}
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <Typography variant="subtitle2" color="text.secondary">Timestamp</Typography>
            <Typography variant="body1">
              {new Date(log.timestamp).toLocaleString()}
            </Typography>
            {log.durationMs && (
              <Typography variant="caption" color="text.secondary">
                Duration: {log.durationMs}ms
              </Typography>
            )}
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <Typography variant="subtitle2" color="text.secondary">Entity Type</Typography>
            <Typography variant="body1">{log.entityType}</Typography>
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <Typography variant="subtitle2" color="text.secondary">Entity</Typography>
            <Typography variant="body1">{log.entityName || log.entityId || '-'}</Typography>
          </Grid>

          {log.description && (
            <Grid size={12}>
              <Typography variant="subtitle2" color="text.secondary">Description</Typography>
              <Typography variant="body1">{log.description}</Typography>
            </Grid>
          )}

          {log.errorMessage && (
            <Grid size={12}>
              <Alert severity="error">
                <Typography variant="body2">{log.errorMessage}</Typography>
              </Alert>
            </Grid>
          )}

          {/* Request Info */}
          {(log.requestPath || log.httpMethod) && (
            <Grid size={12}>
              <Divider sx={{ my: 1 }} />
              <Typography variant="subtitle2" color="text.secondary" gutterBottom>Request</Typography>
              <Stack direction="row" spacing={1}>
                {log.httpMethod && <Chip label={log.httpMethod} size="small" variant="outlined" />}
                {log.requestPath && <Typography variant="body2">{log.requestPath}</Typography>}
              </Stack>
            </Grid>
          )}

          {/* Client Info */}
          {(log.ipAddress || log.userAgent) && (
            <Grid size={12}>
              <Divider sx={{ my: 1 }} />
              <Typography variant="subtitle2" color="text.secondary" gutterBottom>Client Info</Typography>
              {log.ipAddress && (
                <Typography variant="body2">IP: {log.ipAddress}</Typography>
              )}
              {log.userAgent && (
                <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                  {log.userAgent}
                </Typography>
              )}
            </Grid>
          )}

          {/* Values */}
          <Grid size={12}>
            {renderJsonValue(log.oldValues, 'Old Values')}
            {renderJsonValue(log.newValues, 'New Values')}
          </Grid>
        </Grid>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>Close</Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Main Component ─────────────────────────────────────────

const AuditLogsPage: React.FC = () => {
  const theme = useTheme();
  const toast = useToast();
  const dk = theme.palette.mode === 'dark';

  const [logs, setLogs] = useState<AuditLogDto[]>([]);
  const [summary, setSummary] = useState<AuditLogSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [totalCount, setTotalCount] = useState(0);

  // Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [actionFilter, setActionFilter] = useState('');
  const [entityTypeFilter, setEntityTypeFilter] = useState('');
  const [successFilter, setSuccessFilter] = useState<boolean | undefined>(undefined);
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [showFilters, setShowFilters] = useState(false);

  // Pagination
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);

  // Detail dialog
  const [selectedLog, setSelectedLog] = useState<AuditLogDto | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);

  // ─── Data Loading ───────────────────────────────────────

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const params: AuditLogSearchParams = {
        UserName: searchQuery || undefined,
        Action: actionFilter || undefined,
        EntityType: entityTypeFilter || undefined,
        IsSuccess: successFilter,
        FromDate: fromDate || undefined,
        ToDate: toDate || undefined,
        Page: page + 1,
        PageSize: rowsPerPage,
      };
      const result = await searchAuditLogs(params);
      setLogs(result.items || result);
      setTotalCount(result.totalCount || result.length);

      // Load summary
      const summaryData = await getAuditLogSummary();
      setSummary(summaryData);
    } catch (err) {
      toast.error('Failed to load audit logs');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [toast, searchQuery, actionFilter, entityTypeFilter, successFilter, fromDate, toDate, page, rowsPerPage]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // ─── Handlers ───────────────────────────────────────────

  const handleViewDetail = async (log: AuditLogDto) => {
    try {
      const detail = await getAuditLogById(log.id);
      setSelectedLog(detail);
      setDetailOpen(true);
    } catch {
      setSelectedLog(log);
      setDetailOpen(true);
    }
  };

  const clearFilters = () => {
    setSearchQuery('');
    setActionFilter('');
    setEntityTypeFilter('');
    setSuccessFilter(undefined);
    setFromDate('');
    setToDate('');
    setPage(0);
  };

  // ─── Render ─────────────────────────────────────────────

  return (
    <Box p={3}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight={700}>
            Audit Logs
          </Typography>
          <Typography variant="body2" color="text.secondary">
            View system activity and changes
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button
            startIcon={<FilterList />}
            onClick={() => setShowFilters(!showFilters)}
            variant={showFilters ? 'contained' : 'outlined'}
          >
            Filters
          </Button>
          <Button startIcon={<Refresh />} onClick={loadData} variant="outlined">
            Refresh
          </Button>
        </Stack>
      </Stack>

      {/* Summary Cards */}
      {summary && (
        <Grid container spacing={2} mb={3}>
          <Grid size={{ xs: 6, md: 3 }}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h4" fontWeight={700}>{summary.totalLogs}</Typography>
              <Typography variant="body2" color="text.secondary">Total Logs</Typography>
            </Paper>
          </Grid>
          <Grid size={{ xs: 6, md: 3 }}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h4" fontWeight={700} color="success.main">{summary.successCount}</Typography>
              <Typography variant="body2" color="text.secondary">Successful</Typography>
            </Paper>
          </Grid>
          <Grid size={{ xs: 6, md: 3 }}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h4" fontWeight={700} color="error.main">{summary.failureCount}</Typography>
              <Typography variant="body2" color="text.secondary">Failed</Typography>
            </Paper>
          </Grid>
          <Grid size={{ xs: 6, md: 3 }}>
            <Paper sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="h4" fontWeight={700}>{summary.uniqueUsers}</Typography>
              <Typography variant="body2" color="text.secondary">Unique Users</Typography>
            </Paper>
          </Grid>
        </Grid>
      )}

      {/* Filters */}
      <Collapse in={showFilters}>
        <Paper sx={{ p: 2, mb: 3 }}>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 3 }}>
              <TextField
                fullWidth
                size="small"
                label="Search User"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Search />
                    </InputAdornment>
                  ),
                }}
              />
            </Grid>
            <Grid size={{ xs: 12, md: 2 }}>
              <FormControl fullWidth size="small">
                <InputLabel>Action</InputLabel>
                <Select
                  value={actionFilter}
                  onChange={(e) => setActionFilter(e.target.value)}
                  label="Action"
                >
                  <MenuItem value="">All</MenuItem>
                  <MenuItem value="Create">Create</MenuItem>
                  <MenuItem value="Update">Update</MenuItem>
                  <MenuItem value="Delete">Delete</MenuItem>
                  <MenuItem value="Login">Login</MenuItem>
                  <MenuItem value="Logout">Logout</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid size={{ xs: 12, md: 2 }}>
              <FormControl fullWidth size="small">
                <InputLabel>Entity Type</InputLabel>
                <Select
                  value={entityTypeFilter}
                  onChange={(e) => setEntityTypeFilter(e.target.value)}
                  label="Entity Type"
                >
                  <MenuItem value="">All</MenuItem>
                  <MenuItem value="Order">Order</MenuItem>
                  <MenuItem value="Product">Product</MenuItem>
                  <MenuItem value="Customer">Customer</MenuItem>
                  <MenuItem value="User">User</MenuItem>
                  <MenuItem value="Payment">Payment</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid size={{ xs: 12, md: 2 }}>
              <FormControl fullWidth size="small">
                <InputLabel>Status</InputLabel>
                <Select
                  value={successFilter === undefined ? '' : successFilter.toString()}
                  onChange={(e) => setSuccessFilter(e.target.value === '' ? undefined : e.target.value === 'true')}
                  label="Status"
                >
                  <MenuItem value="">All</MenuItem>
                  <MenuItem value="true">Success</MenuItem>
                  <MenuItem value="false">Failed</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid size={{ xs: 12, md: 3 }}>
              <Stack direction="row" spacing={1}>
                <TextField
                  fullWidth
                  size="small"
                  type="date"
                  label="From"
                  value={fromDate}
                  onChange={(e) => setFromDate(e.target.value)}
                  InputLabelProps={{ shrink: true }}
                />
                <TextField
                  fullWidth
                  size="small"
                  type="date"
                  label="To"
                  value={toDate}
                  onChange={(e) => setToDate(e.target.value)}
                  InputLabelProps={{ shrink: true }}
                />
              </Stack>
            </Grid>
            <Grid size={12}>
              <Button size="small" onClick={clearFilters}>Clear Filters</Button>
            </Grid>
          </Grid>
        </Paper>
      </Collapse>

      {/* Table */}
      <Paper>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Timestamp</TableCell>
                <TableCell>User</TableCell>
                <TableCell>Action</TableCell>
                <TableCell>Entity</TableCell>
                <TableCell align="center">Status</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                    <CircularProgress />
                  </TableCell>
                </TableRow>
              ) : logs.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                    <Typography color="text.secondary">No audit logs found</Typography>
                  </TableCell>
                </TableRow>
              ) : (
                logs.map((log) => (
                  <TableRow key={log.id} hover>
                    <TableCell>
                      <Stack direction="row" spacing={0.5} alignItems="center">
                        <Schedule sx={{ fontSize: 16, color: 'text.secondary' }} />
                        <Typography variant="body2">
                          {new Date(log.timestamp).toLocaleString()}
                        </Typography>
                      </Stack>
                    </TableCell>
                    <TableCell>
                      <Stack direction="row" spacing={0.5} alignItems="center">
                        <Person sx={{ fontSize: 16, color: 'text.secondary' }} />
                        <Typography variant="body2">{log.userName || 'System'}</Typography>
                      </Stack>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={log.action}
                        size="small"
                        sx={{
                          bgcolor: alpha(getActionColor(log.action), 0.1),
                          color: getActionColor(log.action),
                          fontWeight: 500,
                        }}
                      />
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">{log.entityType}</Typography>
                      {log.entityName && (
                        <Typography variant="caption" color="text.secondary">
                          {log.entityName}
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell align="center">
                      {log.isSuccess ? (
                        <CheckCircle sx={{ color: 'success.main' }} />
                      ) : (
                        <Tooltip title={log.errorMessage || 'Failed'}>
                          <Error sx={{ color: 'error.main' }} />
                        </Tooltip>
                      )}
                    </TableCell>
                    <TableCell align="right">
                      <Tooltip title="View Details">
                        <IconButton size="small" onClick={() => handleViewDetail(log)}>
                          <Visibility />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
        <TablePagination
          component="div"
          count={totalCount}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(e) => {
            setRowsPerPage(parseInt(e.target.value, 10));
            setPage(0);
          }}
          rowsPerPageOptions={[10, 25, 50, 100]}
        />
      </Paper>

      {/* Detail Dialog */}
      <LogDetailDialog
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
        log={selectedLog}
      />
    </Box>
  );
};

export default AuditLogsPage;
