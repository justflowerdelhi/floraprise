import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Grid,
  MenuItem,
  Skeleton,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TablePagination,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import {
  exportMobileAdminSupportActivityUrl,
  getMobileAdminSupportActivity,
  type MobileAdminSupportActivityItem,
} from '../../api/mobile-admin.api';
import { getCompanies } from '../../api/company.api';
import MobileAdminGlobalSearchBar from './components/MobileAdminGlobalSearchBar';

interface CompanyOption {
  id: string;
  name: string;
}

const formatDateTime = (value: string) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString('en-IN');
};

const MobileAdminSupportActivityPage: React.FC = () => {
  const navigate = useNavigate();
  const [companies, setCompanies] = useState<CompanyOption[]>([]);
  const [companyId, setCompanyId] = useState('');
  const [search, setSearch] = useState('');
  const [action, setAction] = useState('');
  const [fromUtc, setFromUtc] = useState('');
  const [toUtc, setToUtc] = useState('');
  const [rows, setRows] = useState<MobileAdminSupportActivityItem[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(20);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const actionOptions = useMemo(() => [
    'LICENSE_ACTIVATED',
    'LICENSE_SUSPENDED',
    'LICENSE_RESUMED',
    'LICENSE_EXTENDED',
    'TRIAL_CONVERTED_TO_PAID',
    'SUBSCRIPTION_RENEWED',
    'PLAN_UPGRADED',
    'DEVICE_RESET',
    'DEVICE_FORCE_LOGOUT',
    'DEVICE_DISABLED',
    'FORCE_LOGOUT',
    'ACCOUNT_SUSPENDED',
  ], []);

  const fetchCompanies = useCallback(async () => {
    const rowsData = await getCompanies();
    setCompanies((rowsData ?? []).map((x: any) => ({ id: String(x.id), name: String(x.name ?? x.id) })));
  }, []);

  const fetchActivity = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const result = await getMobileAdminSupportActivity({
        companyId: companyId || undefined,
        search: search || undefined,
        action: action || undefined,
        fromUtc: fromUtc || undefined,
        toUtc: toUtc || undefined,
        page: page + 1,
        pageSize,
      });
      setRows(result.items ?? []);
      setTotalCount(result.totalCount ?? 0);
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Unable to load support activity.');
    } finally {
      setLoading(false);
    }
  }, [companyId, search, action, fromUtc, toUtc, page, pageSize]);

  useEffect(() => {
    fetchCompanies().catch(() => setError('Unable to load companies.'));
  }, [fetchCompanies]);

  useEffect(() => {
    fetchActivity().catch(() => setError('Unable to load support activity.'));
  }, [fetchActivity]);

  const exportCsv = () => {
    const url = exportMobileAdminSupportActivityUrl({
      companyId: companyId || undefined,
      search: search || undefined,
      action: action || undefined,
      fromUtc: fromUtc || undefined,
      toUtc: toUtc || undefined,
    });
    window.open(url, '_blank');
  };

  return (
    <Box sx={{ p: 3 }}>
      <Stack direction={{ xs: 'column', md: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', md: 'center' }} spacing={2} sx={{ mb: 2 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Support Activity Log</Typography>
          <Typography variant="body2" color="text.secondary">Full audit timeline of support operations.</Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button variant="outlined" onClick={() => navigate('/admin/mobile/dashboard')}>Dashboard</Button>
          <Button variant="contained" onClick={exportCsv}>Export CSV</Button>
        </Stack>
      </Stack>

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <MobileAdminGlobalSearchBar companyId={companyId || undefined} />
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 3 }}>
              <TextField fullWidth size="small" label="Search" placeholder="customer, note, support user" value={search} onChange={(e) => { setSearch(e.target.value); setPage(0); }} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField select fullWidth size="small" label="Company" value={companyId} onChange={(e) => { setCompanyId(e.target.value); setPage(0); }}>
                <MenuItem value="">All</MenuItem>
                {companies.map((company) => <MenuItem key={company.id} value={company.id}>{company.name}</MenuItem>)}
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <TextField select fullWidth size="small" label="Action" value={action} onChange={(e) => { setAction(e.target.value); setPage(0); }}>
                <MenuItem value="">All</MenuItem>
                {actionOptions.map((option) => <MenuItem key={option} value={option}>{option}</MenuItem>)}
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField fullWidth size="small" type="datetime-local" label="From" InputLabelProps={{ shrink: true }} value={fromUtc} onChange={(e) => { setFromUtc(e.target.value); setPage(0); }} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField fullWidth size="small" type="datetime-local" label="To" InputLabelProps={{ shrink: true }} value={toUtc} onChange={(e) => { setToUtc(e.target.value); setPage(0); }} />
            </Grid>
          </Grid>
          <Stack direction="row" spacing={1} sx={{ mt: 2 }}>
            <Button variant="contained" onClick={() => fetchActivity()}>Apply</Button>
            <Button variant="outlined" onClick={() => { setSearch(''); setCompanyId(''); setAction(''); setFromUtc(''); setToUtc(''); setPage(0); }}>Reset</Button>
          </Stack>
        </CardContent>
      </Card>

      <Card>
        <CardContent sx={{ p: 0 }}>
          {loading ? (
            <Box sx={{ p: 2 }}>
              <Skeleton height={42} />
              <Skeleton height={42} />
              <Skeleton height={42} />
              <Skeleton height={42} />
            </Box>
          ) : rows.length === 0 ? (
            <Box sx={{ p: 3 }}><Alert severity="info">No support activity records found.</Alert></Box>
          ) : (
            <>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell><strong>Date/Time</strong></TableCell>
                      <TableCell><strong>Support User</strong></TableCell>
                      <TableCell><strong>Customer</strong></TableCell>
                      <TableCell><strong>Action</strong></TableCell>
                      <TableCell><strong>Previous Value</strong></TableCell>
                      <TableCell><strong>New Value</strong></TableCell>
                      <TableCell><strong>Notes</strong></TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {rows.map((row, index) => (
                      <TableRow key={`${row.dateTimeUtc}-${row.action}-${index}`} hover>
                        <TableCell>{formatDateTime(row.dateTimeUtc)}</TableCell>
                        <TableCell>{row.supportUser}</TableCell>
                        <TableCell>{row.customer}</TableCell>
                        <TableCell>{row.action}</TableCell>
                        <TableCell>
                          <Typography variant="caption" color="text.secondary" sx={{ whiteSpace: 'pre-wrap' }}>
                            {row.previousValue || '—'}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="caption" color="text.secondary" sx={{ whiteSpace: 'pre-wrap' }}>
                            {row.newValue || '—'}
                          </Typography>
                        </TableCell>
                        <TableCell>{row.notes || '—'}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
              <TablePagination
                component="div"
                count={totalCount}
                page={page}
                onPageChange={(_, nextPage) => setPage(nextPage)}
                rowsPerPage={pageSize}
                onRowsPerPageChange={(e) => { setPageSize(Number(e.target.value)); setPage(0); }}
                rowsPerPageOptions={[10, 20, 50, 100]}
              />
            </>
          )}
        </CardContent>
      </Card>
    </Box>
  );
};

export default MobileAdminSupportActivityPage;
