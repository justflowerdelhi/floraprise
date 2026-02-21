import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Stack,
  CircularProgress,
} from "@mui/material";
import { useState } from "react";
import { createCustomer } from "../../api/customer.api";
import { useApiCall } from "../../hooks/useApiCall";

export default function CreateCustomerDialog({
  open,
  onClose,
  onCreated
}: {
  open: boolean;
  onClose: () => void;
  onCreated: () => void;
}) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const { execute, loading } = useApiCall();

  const save = async () => {
    if (!name.trim()) return;
    const result = await execute(
      () => createCustomer({ name, email: email || null, phone: phone || null }),
      { successMessage: 'Customer created successfully', errorMessage: 'Failed to create customer' }
    );
    if (result !== undefined) {
      setName('');
      setEmail('');
      setPhone('');
      onCreated();
      onClose();
    }
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth>
      <DialogTitle>Add Customer</DialogTitle>

      <DialogContent>
        <Stack spacing={2} mt={1}>
          <TextField label="Name" required value={name} onChange={e => setName(e.target.value)} />
          <TextField label="Email" value={email} onChange={e => setEmail(e.target.value)} />
          <TextField label="Phone" value={phone} onChange={e => setPhone(e.target.value)} />
        </Stack>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose} disabled={loading}>Cancel</Button>
        <Button variant="contained" onClick={save} disabled={loading || !name.trim()}>
          {loading ? <CircularProgress size={20} /> : 'Save'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
