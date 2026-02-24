import React, { useEffect, useState } from 'react';
import { Grid, Card, CardContent, Typography, Button, Chip, Snackbar, CircularProgress, Box } from '@mui/material';
import axios from 'axios';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
dayjs.extend(relativeTime);

interface ProductionJob {
  JobId: string;
  OrderId: string;
  OrderNumber: string;
  Description: string;
  Status: 'Pending' | 'InProgress' | 'Completed';
  CreatedAtUtc: string;
  FulfillmentType?: string;
}

const statusGroups = [
  { key: 'Pending', label: 'Pending' },
  { key: 'InProgress', label: 'In Progress' },
  { key: 'Completed', label: 'Completed' },
];

export default function ProductionBoardPage() {
  const [jobs, setJobs] = useState<ProductionJob[]>([]);
  const [loading, setLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [toast, setToast] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  const fetchJobs = async () => {
    setLoading(true);
    try {
      const res = await axios.get('/api/production-jobs');
      setJobs(res.data);
    } catch {
      setToast({ open: true, message: 'Failed to load jobs', severity: 'error' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchJobs();
  }, []);

  const handleAction = async (job: ProductionJob, action: 'start' | 'complete') => {
    setActionLoading(job.JobId);
    try {
      await axios.post(`/api/production-jobs/${job.JobId}/${action}`);
      setToast({ open: true, message: `Job ${action === 'start' ? 'started' : 'completed'}`, severity: 'success' });
      await fetchJobs();
    } catch {
      setToast({ open: true, message: 'Action failed', severity: 'error' });
    } finally {
      setActionLoading(null);
    }
  };

  const grouped = statusGroups.map(group => ({
    ...group,
    jobs: jobs.filter(j => j.Status === group.key),
  }));

  return (
    <Box p={3}>
      <Typography variant="h4" gutterBottom>Production Board</Typography>
      {loading ? (
        <Box display="flex" justifyContent="center" alignItems="center" minHeight={200}>
          <CircularProgress />
        </Box>
      ) : (
        <Grid container spacing={2}>
          {grouped.map(group => (
            <Grid item xs={12} md={4} key={group.key}>
              <Typography variant="h6" mb={2}>{group.label}</Typography>
              {group.jobs.map(job => (
                <Card key={job.JobId} sx={{ mb: 2 }}>
                  <CardContent>
                    <Typography variant="subtitle2" color="text.secondary">Order #{job.OrderNumber}</Typography>
                    <Typography variant="body1" fontWeight={500} gutterBottom>{job.Description}</Typography>
                    <Box display="flex" alignItems="center" gap={1} mb={1}>
                      <Chip label={job.FulfillmentType || 'Standard'} size="small" color="info" />
                      <Typography variant="caption" color="text.secondary">{dayjs(job.CreatedAtUtc).fromNow()}</Typography>
                    </Box>
                    {job.Status === 'Pending' && (
                      <Button
                        variant="contained"
                        size="small"
                        disabled={!!actionLoading}
                        onClick={() => handleAction(job, 'start')}
                        sx={{ mt: 1 }}
                      >
                        {actionLoading === job.JobId ? <CircularProgress size={18} /> : 'Start'}
                      </Button>
                    )}
                    {job.Status === 'InProgress' && (
                      <Button
                        variant="contained"
                        size="small"
                        color="success"
                        disabled={!!actionLoading}
                        onClick={() => handleAction(job, 'complete')}
                        sx={{ mt: 1 }}
                      >
                        {actionLoading === job.JobId ? <CircularProgress size={18} /> : 'Complete'}
                      </Button>
                    )}
                  </CardContent>
                </Card>
              ))}
            </Grid>
          ))}
        </Grid>
      )}
      <Snackbar
        open={toast.open}
        autoHideDuration={2000}
        onClose={() => setToast(t => ({ ...t, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
        message={toast.message}
      />
    </Box>
  );
}
