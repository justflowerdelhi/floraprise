import React, { useState } from "react";
import { Box, Button, TextField, Typography } from "@mui/material";
import { closeShift } from "../../api/shift.api";

const CloseShiftModal = ({ shift }: any) => {
  const [cash, setCash] = useState(0);

  const expectedCash =
    shift.openingCash + shift.cashSales;

  const difference = cash - expectedCash;

  const handleCloseShift = async () => {
    await closeShift({
      shiftId: shift.id,
      closingCash: cash
    });

    window.location.reload();
  };

  return (
    <Box>
      <Typography variant="h6">Close Shift</Typography>

      <Typography>Opening Cash: ${shift.openingCash}</Typography>
      <Typography>Cash Sales: ${shift.cashSales}</Typography>
      <Typography>Expected Cash: ${expectedCash}</Typography>

      <TextField
        label="Counted Cash"
        type="number"
        value={cash}
        onChange={(e) => setCash(Number(e.target.value))}
      />

      <Typography>
        Difference: ${difference}
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
