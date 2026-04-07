import React, { useState } from "react";
import { Box, Button, TextField, Typography, InputAdornment } from "@mui/material";
import { closeShift } from "../../api/shift.api";
import { useCurrency } from "../../core/i18n";

const CloseShiftModal = ({ shift }: any) => {
  const { format, currencySymbol } = useCurrency();
  const [cash, setCash] = useState(0);

  const expectedCash =
    shift.openingCash + shift.cashSales;

  const difference = cash - expectedCash;

  const handleCloseShift = async () => {
    await closeShift(shift.id, {
      closingCashCount: cash
    });

    window.location.reload();
  };

  return (
    <Box>
      <Typography variant="h6">Close Shift</Typography>

      <Typography>Opening Cash: {format(shift.openingCash)}</Typography>
      <Typography>Cash Sales: {format(shift.cashSales)}</Typography>
      <Typography>Expected Cash: {format(expectedCash)}</Typography>

      <TextField
        label="Counted Cash"
        type="number"
        value={cash}
        onChange={(e) => setCash(Number(e.target.value))}
        InputProps={{
          startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment>,
        }}
      />

      <Typography>
        Difference: {format(difference)}
      </Typography>

      <Button
        variant="contained"
        onClick={handleCloseShift}
      >
        Close Shift
      </Button>
    </Box>
  );
};

export default CloseShiftModal;
