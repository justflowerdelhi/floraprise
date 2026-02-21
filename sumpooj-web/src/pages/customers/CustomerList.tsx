import { useEffect, useState, useCallback } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Paper,
  Button,
  Stack,
  TextField,
  TablePagination,
  CircularProgress,
  Box,
  Typography,
} from "@mui/material";
import CreateCustomerDialog from "./CreateCustomerDialog";
import { searchCustomers } from "../../api/customer.api";
import { useApiCall } from "../../hooks/useApiCall";
import { useToast } from "../../hooks/useToast";

type Customer = {
  id: string;
  name: string;
  email?: string;
  phone?: string;
};

export default function CustomerList() {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [openCreate, setOpenCreate] = useState(false);
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(0);
  const [pageSize] = useState(10);
  const [total, setTotal] = useState(0);
  const { execute, loading } = useApiCall();
  const toast = useToast();

  const load = useCallback(async () => {
    const res = await execute(
      () => searchCustomers({ Query: query, Page: page + 1, PageSize: pageSize }),
      { errorMessage: 'Failed to load customers' }
    );
    if (res) {
      setCustomers(res.items ?? []);
      setTotal(res.totalCount ?? 0);
    }
  }, [execute, query, page, pageSize]);

  useEffect(() => {
    load();
  }, [load]);

  const handleCreated = () => {
    toast.success('Customer created successfully');
    load();
  };

  return (
    <Paper sx={{ p: 2 }}>
      <Stack direction="row" justifyContent="space-between" mb={2}>
        <Typography variant="h5" fontWeight={600}>Customers</Typography>
        <Stack direction="row" spacing={2} alignItems="center">
          <TextField
            placeholder="Search customers..."
            size="small"
            onChange={e => setQuery(e.target.value)}
          />
          <Button variant="contained" onClick={() => setOpenCreate(true)} sx={{ bgcolor: '#4caf50' }}>
            Add Customer
          </Button>
        </Stack>
      </Stack>

      {loading && (
        <Box display="flex" justifyContent="center" py={4}>
          <CircularProgress />
        </Box>
      )}

      {!loading && customers.length === 0 && (
        <Typography color="text.secondary" textAlign="center" py={4}>
          No customers found.
        </Typography>
      )}

      {!loading && customers.length > 0 && (
        <>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Name</TableCell>
                <TableCell>Email</TableCell>
                <TableCell>Phone</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {customers.map(c => (
                <TableRow key={c.id}>
                  <TableCell>{c.name}</TableCell>
                  <TableCell>{c.email ?? '—'}</TableCell>
                  <TableCell>{c.phone ?? '—'}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <TablePagination
            component="div"
            count={total}
            page={page}
            onPageChange={(_, newPage) => setPage(newPage)}
            rowsPerPage={pageSize}
            rowsPerPageOptions={[10]}
          />
        </>
      )}

      <CreateCustomerDialog
        open={openCreate}
        onClose={() => setOpenCreate(false)}
        onCreated={handleCreated}
      />
    </Paper>
  );
}
