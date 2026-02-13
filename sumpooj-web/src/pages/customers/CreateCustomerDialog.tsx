import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Stack
} from "@mui/material";
import { useState } from "react";
import { createCustomer } from "../../api/customer.api";

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
  const [message, setMessage] = useState("");

  const save = async () => {
    await createCustomer({
      name,
      email,
      phone,
      defaultCardMessage: message
    });
    onCreated();
    onClose();
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth>
      <DialogTitle>Add Customer</DialogTitle>

      <DialogContent>
        <Stack spacing={2} mt={1}>
          <TextField label="Name" required onChange={e => setName(e.target.value)} />
          <TextField label="Email" onChange={e => setEmail(e.target.value)} />
          <TextField label="Phone" onChange={e => setPhone(e.target.value)} />
          <TextField
            label="Default Card Message"
            multiline
            rows={3}
            onChange={e => setMessage(e.target.value)}
          />
        </Stack>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button variant="contained" onClick={save}>
          Save
        </Button>
      </DialogActions>
    </Dialog>
  );
}
