import React, { useState } from "react";
import { Box, Button, TextField, Typography, Paper } from "@mui/material";
import { openShift } from "../../api/shift.api";
import { useAuth } from "../../auth/AuthContext";

const OpenShiftModal = ({ onOpened }: any) => {
  const { user } = useAuth();
  console.log("POS User:", user);
  const [cash, setCash] = useState(0);

  const handleOpen = async () => {
    const shift = await openShift({
      staffId: user?.id,
      locationId: user?.primaryLocationId,
      openingCash: cash,
    });

    onOpened(shift);
  };

  return (
    <Paper sx={{ p: 3, width: 340 }}>
      <Typography variant="h6" fontWeight={700} mb={1}>
        Open Cash Drawer
      </Typography>

      {/* STAFF INFO */}
      <Box
        sx={{
          background: "#f5f5f5",
          borderRadius: 1,
          p: 1.5,
          mb: 2,
        }}
      >
        <Typography variant="body2">
          Staff: <b>{user?.name || "Unknown Staff"}</b>
        </Typography>

        <Typography variant="body2">
          Location: <b>{user?.primaryLocationId || "Unknown Location"}</b>
        </Typography>
      </Box>

      <TextField
        fullWidth
        label="Opening Cash"
        type="number"
        value={cash}
        onChange={(e) => setCash(Number(e.target.value))}
      />

      <Button
        fullWidth
        variant="contained"
        sx={{ mt: 2 }}
        onClick={handleOpen}
      >
        Open Shift
      </Button>
    </Paper>
  );
};

export default OpenShiftModal;
