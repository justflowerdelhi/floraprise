/**
 * CompanyManagementPage.tsx — Platform Admin Company Management
 */
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Paper, Chip, CircularProgress, Button,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import api from '../../api/axios';

interface CompanyRow {
  id: string;
  name: string;
  region: string;
  isActive: boolean;
}

const CompanyManagementPage: React.FC = () => {
  const navigate = useNavigate();
  const [companies, setCompanies] = useState<CompanyRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await api.get('/platform/companies');
        setCompanies(res.data ?? []);
      } catch (err) {
        console.error('Failed to load companies:', err);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const handleToggleActive = async (company: CompanyRow) => {
    try {
      const endpoint = company.isActive ? 'deactivate' : 'activate';
      await api.patch(`/platform/companies/${company.id}/${endpoint}`);
      setCompanies(prev =>
        prev.map(c => c.id === company.id ? { ...c, isActive: !c.isActive } : c)
      );
    } catch (err) {
      console.error('Failed to toggle company status:', err);
    }
  };

  if (loading) {
    return (
      <Box sx={{ p: 4, display: 'flex', justifyContent: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Company Management</Typography>
        <Button variant="outlined" onClick={() => navigate('/admin/dashboard')}>Back</Button>
      </Box>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell><strong>Name</strong></TableCell>
              <TableCell><strong>Region</strong></TableCell>
              <TableCell><strong>Status</strong></TableCell>
              <TableCell><strong>Actions</strong></TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {companies.map(c => (
              <TableRow key={c.id}>
                <TableCell>{c.name}</TableCell>
                <TableCell>{c.region}</TableCell>
                <TableCell>
                  <Chip
                    label={c.isActive ? 'Active' : 'Inactive'}
                    color={c.isActive ? 'success' : 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <Button size="small" onClick={() => handleToggleActive(c)}>
                    {c.isActive ? 'Deactivate' : 'Activate'}
                  </Button>
                </TableCell>
              </TableRow>
            ))}
            {companies.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} align="center">No companies found</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default CompanyManagementPage;
