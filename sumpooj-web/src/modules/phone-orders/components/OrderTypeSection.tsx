import React from "react";
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  Radio,
  RadioGroup,
} from "@mui/material";

type OrderType = "Pickup" | "LocalDelivery" | "OutstationDelivery";

interface Props {
  orderType: OrderType;
  setOrderType: (v: OrderType) => void;
  isLocked: boolean;
}

function OrderTypeSection({ orderType, setOrderType, isLocked }: Props) {
  return (
    <FormControl component="fieldset" disabled={isLocked}>
      <FormLabel sx={{ mb: 1 }}>Select order type</FormLabel>

      <RadioGroup
        row
        value={orderType}
        onChange={(e) => setOrderType(e.target.value as OrderType)}
      >
        <FormControlLabel value="Pickup" control={<Radio />} label="Pickup" />
        <FormControlLabel value="LocalDelivery" control={<Radio />} label="Local Delivery" />
        <FormControlLabel value="OutstationDelivery" control={<Radio />} label="Outstation Delivery" />
      </RadioGroup>
    </FormControl>
  );
}

export default OrderTypeSection;