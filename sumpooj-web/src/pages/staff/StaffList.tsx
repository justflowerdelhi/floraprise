/**
 * StaffList.tsx — Staff List Page
 *
 * Features:
 * - Table with all staff members
 * - Search by name, email, phone
 * - Filter by role, active status
 * - Quick view performance action
 * - Team summary stats
 * - Responsive layout
 */
import React, { useState, useMemo } from 'react';
import {
  Box, Typography, TextField, InputAdornment, Button, Chip,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  IconButton, MenuItem, Select, FormControl, InputLabel, Card,
  Grid, useTheme, alpha, Tooltip, TablePagination, Avatar,
} from '@mui/material';
import {
  Search as SearchIcon,
  Add as AddIcon,
  Edit as EditIcon,
  FilterList as FilterIcon,
  Clear as ClearIcon,
  People as PeopleIcon,
  TrendingUp as TrendingUpIcon,
  AttachMoney as MoneyIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import type { Staff, StaffRole } from './StaffTypes';
import { STAFF_ROLES, STAFF_ROLE_CONFIG } from './StaffTypes';
import { getAllStaff, getTeamSummary, getStaffPerformance } from './StaffMockData';

// ─── Currency Formatter ─────────────────────────────────────

const fmtCurrency = (value: number) =>
  new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(value);

// ─── Stats Card Component ───────────────────────────────────

interface StatCardProps {
  label: string;
  value: string | number;
  color: string;
  icon?: React.ReactNode;
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
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        {icon && <Box sx={{ color }}>{icon}</Box>}
        <Box>
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary' }}>
            {label}
          </Typography>
          <Typography variant="h5" sx={{ fontWeight: 700, color, mt: 0.25 }}>
            {value}
          </Typography>
        </Box>
      </Box>
    </Card>
  );
};

// ─── Role Chip Component ────────────────────────────────────

const RoleChip: React.FC<{ role: StaffRole }> = ({ role }) => {
  const config = STAFF_ROLE_CONFIG[role];
  return (
    <Chip
      label={`${config.icon} ${config.label}`}
      size="small"
      sx={{
        bgcolor: alpha(config.color, 0.15),
        color: config.color,
        fontWeight: 600,
        fontSize: '0.75rem',
        border: `1px solid ${alpha(config.color, 0.3)}`,
      }}
    />
  );
};

// ─── Status Badge ───────────────────────────────────────────

const StatusBadge: React.FC<{ isActive: boolean }> = ({ isActive }) => (
  <Chip
    label={isActive ? '● Active' : '○ Inactive'}
    size="small"
    sx={{
      bgcolor: isActive ? alpha('#4caf50', 0.15) : alpha('#9e9e9e', 0.15),
      color: isActive ? '#4caf50' : '#9e9e9e',
      fontWeight: 600,
      fontSize: '0.7rem',
    }}
  />
);

// ─── Staff Filter Interface ─────────────────────────────────

interface StaffFilters {
  search: string;
  role: StaffRole | '';
  activeOnly: boolean;
}

// ─── Main Component ─────────────────────────────────────────

const StaffList: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();

  // State
  const [staff] = useState<Staff[]>(getAllStaff());
  const [filters, setFilters] = useState<StaffFilters>({
    search: '',
    role: '',
    activeOnly: false,
  });
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [showFilters, setShowFilters] = useState(false);

  // Team summary
  const teamSummary = useMemo(() => getTeamSummary(), []);

  // Filtered staff
  const filteredStaff = useMemo(() => {
    let list = [...staff];

    // Search
    if (filters.search) {
      const q = filters.search.toLowerCase();
      list = list.filter(
        (s) =>
          s.name.toLowerCase().includes(q) ||
          s.email?.toLowerCase().includes(q) ||
          s.phone?.includes(filters.search)
      );
    }

    // Role filter
    if (filters.role) {
      list = list.filter((s) => s.role === filters.role);
    }

    // Active filter
    if (filters.activeOnly) {
      list = list.filter((s) => s.isActive);
    }

    // Sort by name
    list.sort((a, b) => a.name.localeCompare(b.name));

    return list;
  }, [staff, filters]);

  // Paginated staff
  const paginatedStaff = useMemo(() => {
    const start = page * rowsPerPage;
    return filteredStaff.slice(start, start + rowsPerPage);
  }, [filteredStaff, page, rowsPerPage]);

  // Get staff performance preview
  const getStaffRevenue = (staffMember: Staff) => {
    const today = new Date();
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1).toISOString().split('T')[0];
    const endOfMonth = today.toISOString().split('T')[0];
    const perf = getStaffPerformance(staffMember.id, startOfMonth, endOfMonth);
    return perf ? (perf.sales.totalRevenue + perf.events.eventRevenue) : 0;
  };

  // Handlers
  const clearFilters = () => {
    setFilters({ search: '', role: '', activeOnly: false });
  };

  const hasActiveFilters = filters.role || filters.activeOnly;

  // Get initials for avatar
  const getInitials = (name: string) => {
    const parts = name.split(' ');
    return parts.map((p) => p[0]).join('').slice(0, 2).toUpperCase();
  };

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1600, mx: 'auto' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3, flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: 1 }}>
            <PeopleIcon sx={{ color: '#7c4dff' }} />
            Staff & Performance
          </Typography>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mt: 0.5 }}>
            Manage team members and track performance metrics
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => navigate('/staff/new')}
          sx={{
            bgcolor: '#7c4dff',
            '&:hover': { bgcolor: '#651fff' },
            fontWeight: 700,
            px: 3,
          }}
        >
          Add Staff
        </Button>
      </Box>

      {/* Stats Row */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="Total Staff"
            value={teamSummary.totalStaff}
            color="#7c4dff"
            icon={<PeopleIcon fontSize="small" />}
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="Active"
            value={teamSummary.activeStaff}
            color="#4caf50"
            icon={<PeopleIcon fontSize="small" />}
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="Total Revenue"
            value={fmtCurrency(teamSummary.totalRevenue)}
            color="#2196f3"
            icon={<TrendingUpIcon fontSize="small" />}
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="Total Orders"
            value={teamSummary.totalOrders}
            color="#ff9800"
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="Total Commission"
            value={fmtCurrency(teamSummary.totalCommission)}
            color="#fdd835"
            icon={<MoneyIcon fontSize="small" />}
          />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <StatCard
            label="Designers"
            value={teamSummary.byRole.DESIGNER}
            color="#e91e63"
          />
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
            placeholder="Search by name, email, phone..."
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
            Filters {hasActiveFilters && `(${[filters.role, filters.activeOnly].filter(Boolean).length})`}
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
              <InputLabel>Role</InputLabel>
              <Select
                value={filters.role}
                label="Role"
                onChange={(e) => setFilters({ ...filters, role: e.target.value as StaffRole | '' })}
              >
                <MenuItem value="">All Roles</MenuItem>
                {STAFF_ROLES.map((r) => (
                  <MenuItem key={r} value={r}>
                    {STAFF_ROLE_CONFIG[r].icon} {STAFF_ROLE_CONFIG[r].label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <FormControl size="small" sx={{ minWidth: 140 }}>
              <InputLabel>Status</InputLabel>
              <Select
                value={filters.activeOnly ? 'active' : 'all'}
                label="Status"
                onChange={(e) => setFilters({ ...filters, activeOnly: e.target.value === 'active' })}
              >
                <MenuItem value="all">All Staff</MenuItem>
                <MenuItem value="active">Active Only</MenuItem>
              </Select>
            </FormControl>
          </Box>
        )}
      </Card>

      {/* Staff Table */}
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
                <TableCell sx={{ fontWeight: 700 }}>Staff Member</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Role</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Contact</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Commission</TableCell>
                <TableCell sx={{ fontWeight: 700 }} align="right">Monthly Revenue</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Status</TableCell>
                <TableCell sx={{ fontWeight: 700 }} align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {paginatedStaff.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} align="center" sx={{ py: 6 }}>
                    <Typography variant="body1" sx={{ color: 'text.secondary' }}>
                      No staff found
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                paginatedStaff.map((staffMember) => {
                  const roleConfig = STAFF_ROLE_CONFIG[staffMember.role];
                  const revenue = getStaffRevenue(staffMember);

                  return (
                    <TableRow
                      key={staffMember.id}
                      hover
                      sx={{
                        cursor: 'pointer',
                        opacity: staffMember.isActive ? 1 : 0.6,
                        '&:hover': { bgcolor: dk ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)' },
                      }}
                      onClick={() => navigate(`/staff/${staffMember.id}`)}
                    >
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                          <Avatar
                            sx={{
                              bgcolor: alpha(roleConfig.color, 0.2),
                              color: roleConfig.color,
                              fontWeight: 700,
                              width: 36,
                              height: 36,
                              fontSize: '0.85rem',
                            }}
                          >
                            {getInitials(staffMember.name)}
                          </Avatar>
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 600 }}>
                              {staffMember.name}
                            </Typography>
                            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                              Since {new Date(staffMember.hireDate || staffMember.createdAt).toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })}
                            </Typography>
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <RoleChip role={staffMember.role} />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">{staffMember.email || '-'}</Typography>
                        <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                          {staffMember.phone || '-'}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        {staffMember.commissionType ? (
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 600 }}>
                              {staffMember.commissionRate}%
                            </Typography>
                            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                              of {staffMember.commissionType.toLowerCase()}
                            </Typography>
                          </Box>
                        ) : (
                          <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                            N/A
                          </Typography>
                        )}
                      </TableCell>
                      <TableCell align="right">
                        <Typography
                          variant="body2"
                          sx={{
                            fontWeight: 600,
                            color: revenue > 0 ? '#4caf50' : 'text.secondary',
                          }}
                        >
                          {revenue > 0 ? fmtCurrency(revenue) : '-'}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <StatusBadge isActive={staffMember.isActive} />
                      </TableCell>
                      <TableCell align="center">
                        <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                          <Tooltip title="View Performance">
                            <IconButton
                              size="small"
                              onClick={(e) => {
                                e.stopPropagation();
                                navigate(`/staff/${staffMember.id}`);
                              }}
                              sx={{
                                color: '#7c4dff',
                                '&:hover': { bgcolor: alpha('#7c4dff', 0.1) },
                              }}
                            >
                              <TrendingUpIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Edit Staff">
                            <IconButton
                              size="small"
                              onClick={(e) => {
                                e.stopPropagation();
                                navigate(`/staff/${staffMember.id}/edit`);
                              }}
                              sx={{
                                color: '#ff9800',
                                '&:hover': { bgcolor: alpha('#ff9800', 0.1) },
                              }}
                            >
                              <EditIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        </Box>
                      </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </TableContainer>

        {/* Pagination */}
        <TablePagination
          component="div"
          count={filteredStaff.length}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(e) => {
            setRowsPerPage(parseInt(e.target.value, 10));
            setPage(0);
          }}
          rowsPerPageOptions={[5, 10, 25]}
          sx={{
            borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
            '.MuiTablePagination-selectLabel, .MuiTablePagination-displayedRows': {
              color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
            },
          }}
        />
      </Card>
    </Box>
  );
};

export default StaffList;
