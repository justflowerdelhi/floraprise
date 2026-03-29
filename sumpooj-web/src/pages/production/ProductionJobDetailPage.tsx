import React, { useEffect, useState } from 'react';
import { Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, Snackbar, CircularProgress } from '@mui/material';
import { apiClient } from '../../core/api/apiClient';

interface MaterialUsage {
  id: string;
  productName: string;
  unitsUsed: number;
  availableUnits: number;
}

interface ProductionJob {
  id: string;
  description: string;
  status: 'Pending' | 'InProgress' | 'Completed';
  materialUsages: MaterialUsage[];
}

interface ProductOption {
  id: string;
  name: string;
  availableUnits: number;
}

const ProductionJobDetailPage: React.FC<{ jobId: string }> = ({ jobId }) => {
  const [job, setJob] = useState<ProductionJob | null>(null);
  const [loading, setLoading] = useState(false);
  const [materialModalOpen, setMaterialModalOpen] = useState(false);
  const [products, setProducts] = useState<ProductOption[]>([]);
  const [selectedProduct, setSelectedProduct] = useState<ProductOption | null>(null);
  const [unitsUsed, setUnitsUsed] = useState('');
  const [apiLoading, setApiLoading] = useState(false);
  const [toast, setToast] = useState<{ open: boolean; message: string; success: boolean }>({ open: false, message: '', success: true });

  useEffect(() => {
    fetchJob();
  }, [jobId]);

  const fetchJob = async () => {
    setLoading(true);
    try {
      const res = await apiClient.get(`/production-jobs/${jobId}`);
      setJob(res.data);
    } catch (e) {
      setToast({ open: true, message: 'Failed to load job', success: false });
    } finally {
      setLoading(false);
    }
  };

  const handleStartJob = async () => {
    setApiLoading(true);
    try {
      await apiClient.post(`/production-jobs/${jobId}/start`);
      setToast({ open: true, message: 'Job started', success: true });
      fetchJob();
    } catch (e) {
      setToast({ open: true, message: 'Failed to start job', success: false });
    } finally {
      setApiLoading(false);
    }
  };

  const handleCompleteJob = async () => {
    setApiLoading(true);
    try {
      await apiClient.post(`/production-jobs/${jobId}/complete`);
      setToast({ open: true, message: 'Job completed', success: true });
      fetchJob();
    } catch (e) {
      setToast({ open: true, message: 'Failed to complete job', success: false });
    } finally {
      setApiLoading(false);
    }
  };

  const openMaterialModal = async () => {
    setMaterialModalOpen(true);
    setProducts([]);
    setSelectedProduct(null);
    setUnitsUsed('');
    try {
      const res = await apiClient.get('/products');
      setProducts(res.data);
    } catch {}
  };

  const handleAddMaterial = async () => {
    if (!selectedProduct || !unitsUsed) return;
    setApiLoading(true);
    try {
      await apiClient.post('/production-material-usage', {
        jobId,
        productId: selectedProduct.id,
        unitsUsed: Number(unitsUsed),
      });
      setToast({ open: true, message: 'Material added', success: true });
      setMaterialModalOpen(false);
      fetchJob();
    } catch (e) {
      setToast({ open: true, message: 'Failed to add material', success: false });
    } finally {
      setApiLoading(false);
    }
  };

  if (loading || !job) return <CircularProgress />;

  return (
    <div>
      <h2>Production Job Detail</h2>
      <div>Description: {job.description}</div>
      <div>Status: {job.status}</div>
      {job.status === 'Pending' && (
        <Button variant="contained" onClick={handleStartJob} disabled={apiLoading}>Start Job</Button>
      )}
      {job.status === 'InProgress' && (
        <>
          <Button variant="contained" onClick={openMaterialModal} disabled={apiLoading}>Add Material</Button>
          <Button variant="contained" color="success" onClick={handleCompleteJob} disabled={apiLoading}>Complete Job</Button>
        </>
      )}
      {job.status === 'Completed' && (
        <>
          <Button variant="contained" disabled>Start Job</Button>
          <Button variant="contained" disabled>Add Material</Button>
          <Button variant="contained" disabled>Complete Job</Button>
        </>
      )}
      <h3>Material Usages</h3>
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Units Used</th>
            <th>Available Units</th>
          </tr>
        </thead>
        <tbody>
          {job.materialUsages.map(mu => (
            <tr key={mu.id}>
              <td>{mu.productName}</td>
              <td>{mu.unitsUsed}</td>
              <td>{mu.availableUnits}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <Dialog open={materialModalOpen} onClose={() => setMaterialModalOpen(false)}>
        <DialogTitle>Add Material</DialogTitle>
        <DialogContent>
          <TextField
            select
            label="Product"
            value={selectedProduct?.id || ''}
            onChange={e => {
              const prod = products.find(p => p.id === e.target.value);
              setSelectedProduct(prod || null);
            }}
            SelectProps={{ native: true }}
            fullWidth
          >
            <option value="">Select product</option>
            {products.map(p => (
              <option key={p.id} value={p.id}>{p.name}</option>
            ))}
          </TextField>
          {selectedProduct && (
            <div>Available Units: {selectedProduct.availableUnits}</div>
          )}
          <TextField
            label="Units Used"
            type="number"
            value={unitsUsed}
            onChange={e => setUnitsUsed(e.target.value)}
            fullWidth
            disabled={!selectedProduct}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setMaterialModalOpen(false)} disabled={apiLoading}>Cancel</Button>
          <Button onClick={handleAddMaterial} disabled={apiLoading || !selectedProduct || !unitsUsed}>Submit</Button>
        </DialogActions>
      </Dialog>
      <Snackbar
        open={toast.open}
        autoHideDuration={3000}
        onClose={() => setToast({ ...toast, open: false })}
        message={toast.message}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
        color={toast.success ? 'success' : 'error'}
      />
    </div>
  );
};

export default ProductionJobDetailPage;
