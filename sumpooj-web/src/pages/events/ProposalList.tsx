/**
 * ProposalList.tsx — List All Proposals
 * 
 * Features:
 * - Table view with status filters
 * - Margin indicators with color coding
 * - Quick actions (view, edit, duplicate, send)
 * - Stats overview
 */
import React, { useState, useMemo } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  IconButton,
  TextField,
  InputAdornment,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Chip,
  Tooltip,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  ToggleButton,
  ToggleButtonGroup,
  Stack,
} from '@mui/material';
import Grid from '@mui/material/Grid';
import {
  Search as SearchIcon,
  Add as AddIcon,
  Edit as EditIcon,
  Visibility as ViewIcon,
  MoreVert as MoreIcon,
  Send as SendIcon,
  ContentCopy as DuplicateIcon,
  Delete as DeleteIcon,
  FilterList as FilterIcon,
  TrendingUp as ProfitIcon,
  Receipt as RevenueIcon,
  Warning as WarningIcon,
  CheckCircle as ApprovedIcon,
  Description as DraftIcon,
  Outbox as SentIcon,
  Cancel as RejectedIcon,
} from '@mui/icons-material';

// Status icon mapping
const STATUS_ICONS: Record<string, React.ElementType> = {
  DRAFT: DraftIcon,
  SENT: SentIcon,
  APPROVED: ApprovedIcon,
  REJECTED: RejectedIcon,
};
import { useNavigate } from 'react-router-dom';
import type { Proposal, ProposalStatus } from './ProposalTypes';
import { PROPOSAL_STATUS_CONFIG, getMarginColor } from './ProposalTypes';
import { MOCK_PROPOSALS, getProposalStats } from './ProposalMockData';

// ─── Styling Constants ──────────────────────────────────────

const cardBg = '#1a1a2e';
const borderColor = '#2d2d44';
const yellowAccent = '#fdd835';
const pageBg = '#0f0f0f';

// ─── Format Functions ───────────────────────────────────────

const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(amount);
};

const formatDate = (dateString: string): string => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
};

// ─── Stats Card Component ───────────────────────────────────

interface StatsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  color?: string;
}

const StatsCard: React.FC<StatsCardProps> = ({ title, value, subtitle, icon, color = yellowAccent }) => (
  <Paper
    sx={{
      backgroundColor: cardBg,
      border: `1px solid ${borderColor}`,
      borderRadius: 2,
      p: 2,
      height: '100%',
    }}
  >
    <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
      <Box>
        <Typography variant="caption" sx={{ color: '#888', textTransform: 'uppercase' }}>
          {title}
        </Typography>
        <Typography variant="h5" sx={{ color: '#fff', fontWeight: 700, my: 0.5 }}>
          {value}
        </Typography>
        {subtitle && (
          <Typography variant="caption" sx={{ color: '#666' }}>
            {subtitle}
          </Typography>
        )}
      </Box>
      <Box sx={{ color, opacity: 0.8 }}>{icon}</Box>
    </Box>
  </Paper>
);

// ─── Proposal Row Component ─────────────────────────────────

interface ProposalRowProps {
  proposal: Proposal;
  onView: () => void;
  onEdit: () => void;
  onDuplicate: () => void;
  onSend: () => void;
  onDelete: () => void;
}

const ProposalRow: React.FC<ProposalRowProps> = ({
  proposal,
  onView,
  onEdit,
  onDuplicate,
  onSend,
  onDelete,
}) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);

  const statusConfig = PROPOSAL_STATUS_CONFIG[proposal.status];
  const StatusIcon = STATUS_ICONS[proposal.status] || DraftIcon;
  const marginColor = getMarginColor(proposal.marginPercentage);
  const isLowMargin = proposal.marginPercentage < 20;

  return (
    <TableRow
      sx={{
        '& td': { borderColor, py: 1.5 },
        '&:hover': { backgroundColor: 'rgba(253, 216, 53, 0.03)' },
        cursor: 'pointer',
      }}
      onClick={onView}
    >
      {/* Event & Version */}
      <TableCell>
        <Typography variant="body2" sx={{ color: '#fff', fontWeight: 600 }}>
          {proposal.eventName}
        </Typography>
        <Typography variant="caption" sx={{ color: '#888' }}>
          {proposal.versionName}
        </Typography>
      </TableCell>

      {/* Status */}
      <TableCell>
        <Chip
          icon={<StatusIcon fontSize="small" />}
          label={statusConfig.label}
          size="small"
          sx={{
            backgroundColor: `${statusConfig.color}20`,
            color: statusConfig.color,
            '& .MuiChip-icon': { color: statusConfig.color },
          }}
        />
      </TableCell>

      {/* Total */}
      <TableCell align="right">
        <Typography
          sx={{ color: '#fff', fontFamily: 'monospace', fontWeight: 600 }}
        >
          {formatCurrency(proposal.grandTotal)}
        </Typography>
        {proposal.discount > 0 && (
          <Typography variant="caption" sx={{ color: '#ef5350' }}>
            -{formatCurrency(proposal.discount)} disc
          </Typography>
        )}
      </TableCell>

      {/* Margin */}
      <TableCell align="right">
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 0.5 }}>
          {isLowMargin && (
            <Tooltip title="Low margin warning">
              <WarningIcon fontSize="small" sx={{ color: '#ef5350' }} />
            </Tooltip>
          )}
          <Typography
            sx={{
              color: marginColor,
              fontFamily: 'monospace',
              fontWeight: 600,
            }}
          >
            {proposal.marginPercentage.toFixed(1)}%
          </Typography>
        </Box>
        <Typography variant="caption" sx={{ color: '#888' }}>
          {formatCurrency(proposal.grossProfit)} profit
        </Typography>
      </TableCell>

      {/* Items */}
      <TableCell align="center">
        <Typography sx={{ color: '#fff' }}>{proposal.items.length}</Typography>
      </TableCell>

      {/* Date */}
      <TableCell>
        <Typography variant="body2" sx={{ color: '#888' }}>
          {formatDate(proposal.updatedAt)}
        </Typography>
        {proposal.validUntil && (
          <Typography variant="caption" sx={{ color: '#666' }}>
            Valid: {formatDate(proposal.validUntil)}
          </Typography>
        )}
      </TableCell>

      {/* Actions */}
      <TableCell align="right" onClick={(e) => e.stopPropagation()}>
        <Tooltip title="Edit">
          <IconButton size="small" onClick={onEdit} sx={{ color: '#888', '&:hover': { color: yellowAccent } }}>
            <EditIcon fontSize="small" />
          </IconButton>
        </Tooltip>
        <IconButton
          size="small"
          onClick={(e) => setAnchorEl(e.currentTarget)}
          sx={{ color: '#888' }}
        >
          <MoreIcon fontSize="small" />
        </IconButton>

        <Menu
          anchorEl={anchorEl}
          open={Boolean(anchorEl)}
          onClose={() => setAnchorEl(null)}
          PaperProps={{
            sx: { backgroundColor: cardBg, border: `1px solid ${borderColor}` },
          }}
        >
          <MenuItem onClick={() => { onView(); setAnchorEl(null); }}>
            <ListItemIcon><ViewIcon fontSize="small" sx={{ color: '#888' }} /></ListItemIcon>
            <ListItemText sx={{ '& .MuiTypography-root': { color: '#fff' } }}>View</ListItemText>
          </MenuItem>
          <MenuItem onClick={() => { onDuplicate(); setAnchorEl(null); }}>
            <ListItemIcon><DuplicateIcon fontSize="small" sx={{ color: '#888' }} /></ListItemIcon>
            <ListItemText sx={{ '& .MuiTypography-root': { color: '#fff' } }}>Duplicate</ListItemText>
          </MenuItem>
          {proposal.status === 'DRAFT' && (
            <MenuItem onClick={() => { onSend(); setAnchorEl(null); }}>
              <ListItemIcon><SendIcon fontSize="small" sx={{ color: '#4caf50' }} /></ListItemIcon>
              <ListItemText sx={{ '& .MuiTypography-root': { color: '#4caf50' } }}>Send to Client</ListItemText>
            </MenuItem>
          )}
          <MenuItem onClick={() => { onDelete(); setAnchorEl(null); }}>
            <ListItemIcon><DeleteIcon fontSize="small" sx={{ color: '#ef5350' }} /></ListItemIcon>
            <ListItemText sx={{ '& .MuiTypography-root': { color: '#ef5350' } }}>Delete</ListItemText>
          </MenuItem>
        </Menu>
      </TableCell>
    </TableRow>
  );
};

// ─── Main ProposalList Component ────────────────────────────

const ProposalList: React.FC = () => {
  const navigate = useNavigate();

  // State
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<ProposalStatus | 'ALL'>('ALL');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  // Mock data
  const proposals = MOCK_PROPOSALS;
  const stats = useMemo(() => getProposalStats(proposals), [proposals]);

  // Filter proposals
  const filteredProposals = useMemo(() => {
    return proposals.filter((proposal) => {
      // Status filter
      if (statusFilter !== 'ALL' && proposal.status !== statusFilter) return false;

      // Search filter
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        return (
          proposal.eventName?.toLowerCase().includes(query) ||
          proposal.versionName.toLowerCase().includes(query) ||
          proposal.id.toLowerCase().includes(query)
        );
      }

      return true;
    });
  }, [proposals, statusFilter, searchQuery]);

  // Paginated proposals
  const paginatedProposals = filteredProposals.slice(
    page * rowsPerPage,
    page * rowsPerPage + rowsPerPage
  );

  // Handlers
  const handleView = (proposal: Proposal) => {
    navigate(`/proposals/${proposal.id}`);
  };

  const handleEdit = (proposal: Proposal) => {
    navigate(`/proposals/${proposal.id}/edit`);
  };

  const handleDuplicate = (proposal: Proposal) => {
    console.log('Duplicate proposal:', proposal.id);
    // TODO: Implement duplication
  };

  const handleSend = (proposal: Proposal) => {
    console.log('Send proposal:', proposal.id);
    // TODO: Implement send
  };

  const handleDelete = (proposal: Proposal) => {
    console.log('Delete proposal:', proposal.id);
    // TODO: Implement delete
  };

  const handleNewProposal = () => {
    navigate('/proposals/new');
  };

  return (
    <Box sx={{ p: 3, backgroundColor: pageBg, minHeight: '100vh' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ color: '#fff', fontWeight: 600 }}>
            Proposals
          </Typography>
          <Typography variant="body2" sx={{ color: '#888' }}>
            Manage quotes and proposals for events
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleNewProposal}
          sx={{
            backgroundColor: yellowAccent,
            color: '#000',
            fontWeight: 600,
            '&:hover': { backgroundColor: '#fbc02d' },
          }}
        >
          New Proposal
        </Button>
      </Box>

      {/* Stats Row */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Total Proposals"
            value={stats.total}
            subtitle={`${stats.drafts} drafts, ${stats.sent} sent`}
            icon={<RevenueIcon sx={{ fontSize: 32 }} />}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Approved Revenue"
            value={formatCurrency(stats.approvedTotal)}
            subtitle={`${stats.approved} approved`}
            icon={<ApprovedIcon sx={{ fontSize: 32 }} />}
            color="#4caf50"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Avg Margin"
            value={`${stats.avgMargin.toFixed(1)}%`}
            subtitle="Across all proposals"
            icon={<ProfitIcon sx={{ fontSize: 32 }} />}
            color={getMarginColor(stats.avgMargin)}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Awaiting Response"
            value={stats.sent}
            subtitle="Proposals sent to clients"
            icon={<SendIcon sx={{ fontSize: 32 }} />}
            color="#2196f3"
          />
        </Grid>
      </Grid>

      {/* Filters */}
      <Paper
        sx={{
          backgroundColor: cardBg,
          border: `1px solid ${borderColor}`,
          borderRadius: 2,
          p: 2,
          mb: 2,
        }}
      >
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ sm: 'center' }}>
          <TextField
            placeholder="Search proposals..."
            size="small"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            sx={{
              flex: 1,
              maxWidth: 400,
              '& .MuiOutlinedInput-root': {
                backgroundColor: '#0f0f0f',
                '& fieldset': { borderColor },
              },
              '& .MuiInputBase-input': { color: '#fff' },
            }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon sx={{ color: '#666' }} />
                </InputAdornment>
              ),
            }}
          />

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <FilterIcon sx={{ color: '#666' }} />
            <ToggleButtonGroup
              value={statusFilter}
              exclusive
              onChange={(_, value) => value && setStatusFilter(value)}
              size="small"
              sx={{
                '& .MuiToggleButton-root': {
                  color: '#888',
                  borderColor,
                  '&.Mui-selected': {
                    backgroundColor: `${yellowAccent}20`,
                    color: yellowAccent,
                  },
                },
              }}
            >
              <ToggleButton value="ALL">All</ToggleButton>
              <ToggleButton value="DRAFT">Draft</ToggleButton>
              <ToggleButton value="SENT">Sent</ToggleButton>
              <ToggleButton value="APPROVED">Approved</ToggleButton>
              <ToggleButton value="REJECTED">Rejected</ToggleButton>
            </ToggleButtonGroup>
          </Box>
        </Stack>
      </Paper>

      {/* Table */}
      <Paper
        sx={{
          backgroundColor: cardBg,
          border: `1px solid ${borderColor}`,
          borderRadius: 2,
          overflow: 'hidden',
        }}
      >
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={{ '& th': { backgroundColor: '#252540', color: '#888', borderColor } }}>
                <TableCell>Event / Version</TableCell>
                <TableCell>Status</TableCell>
                <TableCell align="right">Total</TableCell>
                <TableCell align="right">Margin</TableCell>
                <TableCell align="center">Items</TableCell>
                <TableCell>Last Updated</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {paginatedProposals.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} sx={{ textAlign: 'center', py: 6, color: '#666' }}>
                    {searchQuery || statusFilter !== 'ALL'
                      ? 'No proposals match your filters'
                      : 'No proposals yet. Create your first proposal!'}
                  </TableCell>
                </TableRow>
              ) : (
                paginatedProposals.map((proposal) => (
                  <ProposalRow
                    key={proposal.id}
                    proposal={proposal}
                    onView={() => handleView(proposal)}
                    onEdit={() => handleEdit(proposal)}
                    onDuplicate={() => handleDuplicate(proposal)}
                    onSend={() => handleSend(proposal)}
                    onDelete={() => handleDelete(proposal)}
                  />
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>

        <TablePagination
          component="div"
          count={filteredProposals.length}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(e) => {
            setRowsPerPage(parseInt(e.target.value, 10));
            setPage(0);
          }}
          sx={{
            borderTop: `1px solid ${borderColor}`,
            color: '#888',
            '& .MuiTablePagination-selectIcon': { color: '#888' },
          }}
        />
      </Paper>
    </Box>
  );
};

export default ProposalList;
