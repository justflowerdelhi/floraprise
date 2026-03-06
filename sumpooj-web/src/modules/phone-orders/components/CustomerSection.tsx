import { Grid, TextField, Autocomplete } from "@mui/material";
import { useState } from "react";

interface Customer {
  id: number;
  name: string;
  phone: string;
}

interface Props {
  customerName: string;
  setCustomerName: (v: string) => void;
  phoneNumber: string;
  setPhoneNumber: (v: string) => void;
}

export default function CustomerSection({
  customerName,
  setCustomerName,
  phoneNumber,
  setPhoneNumber,
}: Props) {

  const [options, setOptions] = useState<Customer[]>([]);

  return (
    <Grid container spacing={2} sx={{ mt: 2 }}>

      {/* Phone Number */}
      <Grid xs={12} md={6}>
        <TextField
          label="Phone Number"
          value={phoneNumber}
          onChange={(e) => setPhoneNumber(e.target.value)}
          fullWidth
          size="small"
        />
      </Grid>

      {/* Customer Name */}
      <Grid xs={12} md={6}>
        <Autocomplete
          freeSolo
          options={options}
          sx={{ width: "100%" }}
          getOptionLabel={(option) =>
            typeof option === "string" ? option : option.name
          }
          value={customerName}
          onInputChange={(event, value) => {
            setCustomerName(value);
          }}
          renderInput={(params) => (
            <TextField
              {...params}
              label="Customer Name"
              size="small"
              fullWidth
            />
          )}
        />
      </Grid>

    </Grid>
  );
}