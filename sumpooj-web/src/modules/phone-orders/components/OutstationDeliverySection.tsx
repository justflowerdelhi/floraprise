import { Grid, TextField, MenuItem } from "@mui/material";

const TIME_SLOTS = [
  "Morning (9AM - 12PM)",
  "Afternoon (12PM - 4PM)",
  "Evening (4PM - 7PM)",
  "Anytime",
];

function OutstationDeliverySection() {
  return (
    <Grid container spacing={2} sx={{ mt: 2 }}>
      <Grid size={{ xs: 12, md: 6 }}>
        <TextField label="Recipient Name" fullWidth size="small" />
      </Grid>

      <Grid size={{ xs: 12, md: 6 }}>
        <TextField label="Recipient Phone" fullWidth size="small" />
      </Grid>

      <Grid size={12}>
        <TextField
          label="Delivery Address"
          fullWidth
          size="small"
          multiline
          rows={2}
        />
      </Grid>

      <Grid size={{ xs: 12, md: 4 }}>
        <TextField label="City" fullWidth size="small" />
      </Grid>

      <Grid size={{ xs: 12, md: 4 }}>
        <TextField label="State" fullWidth size="small" />
      </Grid>

      <Grid size={{ xs: 12, md: 4 }}>
        <TextField label="ZIP Code" fullWidth size="small" />
      </Grid>

      <Grid size={{ xs: 12, md: 6 }}>
        <TextField
          label="Delivery Date"
          type="date"
          InputLabelProps={{ shrink: true }}
          fullWidth
          size="small"
        />
      </Grid>

      <Grid size={{ xs: 12, md: 6 }}>
        <TextField select label="Time Slot" fullWidth size="small">
          {TIME_SLOTS.map((slot) => (
            <MenuItem key={slot} value={slot}>
              {slot}
            </MenuItem>
          ))}
        </TextField>
      </Grid>

      <Grid size={12}>
        <TextField
          label="Card Message"
          multiline
          rows={2}
          fullWidth
          size="small"
        />
      </Grid>

      <Grid size={{ xs: 12, md: 6 }}>
        <TextField label="Sender Name" fullWidth size="small" />
      </Grid>

      <Grid size={12}>
        <TextField
          label="Special Instructions"
          multiline
          rows={3}
          fullWidth
          size="small"
        />
      </Grid>
    </Grid>
  );
}

export default OutstationDeliverySection;