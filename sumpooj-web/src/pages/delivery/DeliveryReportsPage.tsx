/**
 * DeliveryReportsPage.tsx — Driver performance and delivery analytics
 * 
 * Features:
 * - Driver Performance: Average delivery time, Completed, Cancelled, Late deliveries, Distance travelled, Customer rating
 * - Date range filtering
 * - Summary statistics
 */
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Paper, Card, CardContent, Stack,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  TextField, Button, Chip, useTheme, alpha, CircularProgress, Alert
} from '@mui/material';
import {
  Person, LocalShipping, CheckCircle, Cancel, Warning,
  TrendingUp, Speed, Star, AccessTime
} from '@mui/icons-material';

interface DriverPerformance {
  driverId: string;
  driverName: string;
  totalDeliveries: number;
  completedDeliveries: number;
  cancelledDeliveries: number;
  lateDeliveries: number;
  averageDeliveryTime: number; // in minutes
  totalDistance: number; // in km
  customerRating: number; // 1-5
  onTimePercentage: number;
}

interface SummaryStats {
  totalDrivers: number;
  totalDeliveries: number;
  totalCompleted: number;
  totalCancelled: number;
  totalLate: number;
  averageDeliveryTime: number;
  totalDistance: number;
  averageRating: number;
}

export default function DeliveryReportsPage() {
  const theme = useTheme();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState(new Date().toISOString().split('T')[0]);
  const [summary, setSummary] = useState<SummaryStats | null>(null);
  const [driverData, setDriverData] = useState<DriverPerformance[]>([]);

  const fetchReports = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`/api/delivery/reports?startDate=${startDate}&endDate=${endDate}`);
      if (!response.ok) throw new Error('Failed to fetch reports');
      const data = await response.json();
      setSummary(data.summary);
      setDriverData(data.driverPerformance || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      // Use mock data for demo
      setSummary({
        totalDrivers: 5,
        totalDeliveries: 150,
        totalCompleted: 138,
        totalCancelled: 8,
        totalLate: 12,
        averageDeliveryTime: 25,
        totalDistance: 450,
        averageRating: 4.5
      });
      setDriverData([
        {
          driverId: '1',
          driverName: 'Mike Johnson',
          totalDeliveries: 35,
          completedDeliveries: 33,
          cancelledDeliveries: 2,
          lateDeliveries: 3,
          averageDeliveryTime: 22,
          totalDistance: 95,
          customerRating: 4.8,
          onTimePercentage: 91
        },
        {
          driverId: '2',
          driverName: 'Sarah Williams',
          totalDeliveries: 32,
          completedDeliveries: 30,
          cancelledDeliveries: 2,
          lateDeliveries: 2,
          averageDeliveryTime: 24,
          totalDistance: 88,
          customerRating: 4.6,
          onTimePercentage: 94
        },
        {
          driverId: '3',
          driverName: 'John Davis',
          totalDeliveries: 28,
          completedDeliveries: 25,
          cancelledDeliveries: 3,
          lateDeliveries: 4,
          averageDeliveryTime: 28,
          totalDistance: 92,
          customerRating: 4.3,
          onTimePercentage: 86
        },
        {
          driverId: '4',
          driverName: 'Emily Brown',
          totalDeliveries: 30,
          completedDeliveries: 28,
          cancelledDeliveries: 1,
          lateDeliveries: 2,
          averageDeliveryTime: 23,
          totalDistance: 85,
          customerRating: 4.7,
          onTimePercentage: 93
        },
        {
          driverId: '5',
          driverName: 'David Wilson',
          totalDeliveries: 25,
          completedDeliveries: 22,
          cancelledDeliveries: 0,
          lateDeliveries: 1,
          averageDeliveryTime: 26,
          totalDistance: 90,
          customerRating: 4.5,
          onTimePercentage: 96
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, [startDate, endDate]);

  const StatCard = ({ title, value, icon, color, subtitle }: any) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Stack spacing={2}>
          <Stack direction="row" alignItems="center" spacing={2}>
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: 2,
                bgcolor: alpha(color, 0.15),
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: color
              }}
            >
              {icon}
            </Box>
            <Box>
              <Typography variant="caption" color="text.secondary">
                {title}
              </Typography>
              <Typography variant="h5" sx={{ fontWeight: 700, color }}>
                {value}
              </Typography>
            </Box>
          </Stack>
          {subtitle && (
            <Typography variant="caption" color="text.secondary">
              {subtitle}
            </Typography>
          )}
        </Stack>
      </CardContent>
    </Card>
  );

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '60vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700 }}>
            Delivery Reports
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Driver performance and delivery analytics
          </Typography>
        </Box>
        <Stack direction="row" spacing={2} alignItems="center">
          <TextField
            label="Start Date"
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            InputLabelProps={{ shrink: true }}
            size="small"
          />
          <TextField
            label="End Date"
            type="date"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
            InputLabelProps={{ shrink: true }}
            size="small"
          />
          <Button variant="contained" onClick={fetchReports}>
            Refresh
          </Button>
        </Stack>
      </Stack>

      {error && (
        <Alert severity="warning" sx={{ mb: 3 }}>
          {error} - Showing demo data
        </Alert>
      )}

      {/* Summary Stats */}
      {summary && (
        <Stack direction="row" spacing={2} sx={{ mb: 3 }} flexWrap="wrap">
          <StatCard
            title="Total Deliveries"
            value={summary.totalDeliveries}
            icon={<LocalShipping />}
            color="#2196f3"
            subtitle={`${summary.totalCompleted} completed`}
          />
          <StatCard
            title="Completion Rate"
            value={`${((summary.totalCompleted / summary.totalDeliveries) * 100).toFixed(1)}%`}
            icon={<CheckCircle />}
            color="#4caf50"
          />
          <StatCard
            title="Avg Delivery Time"
            value={`${summary.averageDeliveryTime} min`}
            icon={<AccessTime />}
            color="#ff9800"
          />
          <StatCard
            title="Total Distance"
            value={`${summary.totalDistance} km`}
            icon={<Speed />}
            color="#9c27b0"
          />
          <StatCard
            title="Avg Rating"
            value={summary.averageRating.toFixed(1)}
            icon={<Star />}
            color="#ffc107"
          />
        </Stack>
      )}

      {/* Driver Performance Table */}
      <Paper>
        <CardContent>
          <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
            Driver Performance
          </Typography>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Driver</TableCell>
                  <TableCell align="right">Total</TableCell>
                  <TableCell align="right">Completed</TableCell>
                  <TableCell align="right">Cancelled</TableCell>
                  <TableCell align="right">Late</TableCell>
                  <TableCell align="right">On-Time %</TableCell>
                  <TableCell align="right">Avg Time</TableCell>
                  <TableCell align="right">Distance</TableCell>
                  <TableCell align="right">Rating</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {driverData.map((driver) => (
                  <TableRow key={driver.driverId} hover>
                    <TableCell>
                      <Stack direction="row" spacing={1} alignItems="center">
                        <Person color="action" fontSize="small" />
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {driver.driverName}
                        </Typography>
                      </Stack>
                    </TableCell>
                    <TableCell align="right">{driver.totalDeliveries}</TableCell>
                    <TableCell align="right">
                      <Chip
                        label={driver.completedDeliveries}
                        size="small"
                        color="success"
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Chip
                        label={driver.cancelledDeliveries}
                        size="small"
                        color={driver.cancelledDeliveries > 0 ? 'error' : 'default'}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Chip
                        label={driver.lateDeliveries}
                        size="small"
                        color={driver.lateDeliveries > 0 ? 'warning' : 'default'}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Typography
                        variant="body2"
                        sx={{
                          fontWeight: 600,
                          color: driver.onTimePercentage >= 90 ? 'success.main' :
                                  driver.onTimePercentage >= 80 ? 'warning.main' : 'error.main'
                        }}
                      >
                        {driver.onTimePercentage}%
                      </Typography>
                    </TableCell>
                    <TableCell align="right">{driver.averageDeliveryTime} min</TableCell>
                    <TableCell align="right">{driver.totalDistance} km</TableCell>
                    <TableCell align="right">
                      <Stack direction="row" spacing={0.5} alignItems="center" justifyContent="flex-end">
                        <Star sx={{ fontSize: 16, color: '#ffc107' }} />
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {driver.customerRating.toFixed(1)}
                        </Typography>
                      </Stack>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Paper>
    </Box>
  );
}
