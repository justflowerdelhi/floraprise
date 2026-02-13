import { useEffect, useState } from "react";
import api from "../../api/axios";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Paper,
  Button,
  Stack,
  TextField
} from "@mui/material";
import CreateCustomerDialog from "./CreateCustomerDialog";
import { searchCustomers } from "../../api/customer.api";
import { TablePagination } from "@mui/material";


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

const load = async () => {
  const res = await searchCustomers(query, page + 1, pageSize);
  setCustomers(res.items);
  setTotal(res.totalCount);
};

  useEffect(() => {
  load();
}, [page, query]);

  return (
    <Paper sx={{ p: 2 }}>
      <Stack direction="row" justifyContent="space-between" mb={2}>
        <h2>Customers</h2>
        <Stack direction="row" justifyContent="space-between" mb={2}>
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
              <TableCell>{c.email}</TableCell>
              <TableCell>{c.phone}</TableCell>
            </TableRow>
          ))}
        </TableBody>
        <TablePagination
  component="div"
  count={total}
  page={page}
  onPageChange={(_, newPage) => setPage(newPage)}
  rowsPerPage={pageSize}
  rowsPerPageOptions={[10]}
/>
      </Table>
      <CreateCustomerDialog
  open={openCreate}
  onClose={() => setOpenCreate(false)}
  onCreated={load}
/>

    </Paper>
  );
}
