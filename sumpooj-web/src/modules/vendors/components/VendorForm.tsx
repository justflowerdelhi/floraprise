import React, { useState } from "react"
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField
} from "@mui/material"

interface Props {
  open: boolean
  onClose: () => void
  onSave: (data: any) => void
  vendor?: any
}

const VendorForm: React.FC<Props> = ({ open, onClose, onSave, vendor }) => {

  const [form, setForm] = useState({
    name: vendor?.name || "",
    city: vendor?.city || "",
    state: vendor?.state || "",
    phone: vendor?.phone || "",
    email: vendor?.email || "",
    commission: vendor?.commission || 0
  })

  const handleChange = (field: string, value: any) => {
    setForm({ ...form, [field]: value })
  }

  const handleSave = () => {
    onSave(form)
    onClose()
  }

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>

      <DialogTitle>
        {vendor ? "Edit Vendor" : "Add Vendor"}
      </DialogTitle>

      <DialogContent>

        <TextField
          label="Vendor Name"
          fullWidth
          margin="dense"
          value={form.name}
          onChange={e => handleChange("name", e.target.value)}
        />

        <TextField
          label="City"
          fullWidth
          margin="dense"
          value={form.city}
          onChange={e => handleChange("city", e.target.value)}
        />

        <TextField
          label="State"
          fullWidth
          margin="dense"
          value={form.state}
          onChange={e => handleChange("state", e.target.value)}
        />

        <TextField
          label="Address"
          fullWidth
          margin="dense"
          value={form.address || ""}
          onChange={e => handleChange("address", e.target.value)}
        />

        <TextField
          label="Zip Code"
          fullWidth
          margin="dense"
          value={form.zipCode || ""}
          onChange={e => handleChange("zipCode", e.target.value)}
        />

        <TextField
          label="Phone"
          fullWidth
          margin="dense"
          value={form.phone}
          onChange={e => handleChange("phone", e.target.value)}
        />

        <TextField
          label="Email"
          fullWidth
          margin="dense"
          value={form.email}
          onChange={e => handleChange("email", e.target.value)}
        />

        <TextField
          label="Commission %"
          type="number"
          fullWidth
          margin="dense"
          value={form.commission}
          onChange={e => handleChange("commission", Number(e.target.value))}
        />

      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button variant="contained" onClick={handleSave}>
          Save
        </Button>
      </DialogActions>

    </Dialog>
  )
}

export default VendorForm
