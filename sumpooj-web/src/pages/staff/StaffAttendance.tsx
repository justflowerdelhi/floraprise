import React, { useState, useEffect } from "react";
import {
  Box,
  Typography,
  Card,
  Avatar,
  Chip,
  Button,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody,
  CircularProgress,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  Grid,
} from "@mui/material";
import LoginIcon from "@mui/icons-material/Login";
import LogoutIcon from "@mui/icons-material/Logout";
import api from "../../api/axios";

interface StaffAttendance {
id: string;
staffId: string;
staffName: string;
staffRole: string;
checkIn?: string;
checkOut?: string;
status: "Working" | "Absent" | "Completed";
}

const StaffAttendancePage: React.FC = () => {
  const [staff, setStaff] = useState<StaffAttendance[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedStaffId, setSelectedStaffId] = useState<string>("");
  const [checkInTime, setCheckInTime] = useState<string>("");
  const [checkOutTime, setCheckOutTime] = useState<string>("");

  useEffect(() => {
    const load = async () => {
      try {
        const res = await api.get("/staff/attendance/today");
        const list = Array.isArray(res.data) ? res.data : [];
        setStaff(list);

        if (list.length > 0) {
          const first = list[0] as StaffAttendance;
          setSelectedStaffId(first.staffId);
          setCheckInTime(first.checkIn || "");
          setCheckOutTime(first.checkOut || "");
        }
      } catch (err) {
        console.error("Failed to load attendance:", err);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const selectedStaff = staff.find((s) => s.staffId === selectedStaffId);

  const syncSelectedTimes = (record: StaffAttendance | undefined) => {
    setCheckInTime(record?.checkIn || "");
    setCheckOutTime(record?.checkOut || "");
  };

  const handleStaffSelect = (staffId: string) => {
    setSelectedStaffId(staffId);
    const record = staff.find((s) => s.staffId === staffId);
    syncSelectedTimes(record);
  };

  const handleCheckIn = async (staffId: string) => {
    try {
      const res = await api.post(`/staff/attendance/${staffId}/check-in`);
      const updated = res.data as StaffAttendance;
      setStaff((prev) => prev.map((s) => (s.staffId === staffId ? updated : s)));
      if (selectedStaffId === staffId) syncSelectedTimes(updated);
    } catch (err) {
      console.error("Check-in failed:", err);
    }
  };

  const handleCheckOut = async (recordId: string) => {
    try {
      const res = await api.post(`/staff/attendance/${recordId}/check-out`);
      const updated = res.data as StaffAttendance;
      setStaff((prev) => prev.map((s) => (s.id === recordId ? updated : s)));
      if (selectedStaffId === updated.staffId) syncSelectedTimes(updated);
    } catch (err) {
      console.error("Check-out failed:", err);
    }
  };

  if (loading) {
    return (
      <Box p={4} display="flex" justifyContent="center">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box p={3}>
      <Typography variant="h5" fontWeight={700} mb={3}>
        Staff Attendance
      </Typography>

      <Card sx={{ p: 2, mb: 2 }}>
        <Grid container spacing={2}>
          <Grid size={{ xs: 12, md: 4 }}>
            <FormControl fullWidth size="small">
              <InputLabel>Select Staff</InputLabel>
              <Select
                value={selectedStaffId}
                label="Select Staff"
                onChange={(e) => handleStaffSelect(e.target.value)}
              >
                {staff.map((s) => (
                  <MenuItem key={s.staffId} value={s.staffId}>
                    {s.staffName} ({s.staffRole})
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid size={{ xs: 12, md: 3 }}>
            <TextField
              fullWidth
              size="small"
              label="Check-In Time"
              type="time"
              value={checkInTime}
              InputLabelProps={{ shrink: true }}
              inputProps={{ readOnly: true }}
            />
          </Grid>

          <Grid size={{ xs: 12, md: 3 }}>
            <TextField
              fullWidth
              size="small"
              label="Check-Out Time"
              type="time"
              value={checkOutTime}
              InputLabelProps={{ shrink: true }}
              inputProps={{ readOnly: true }}
            />
          </Grid>

          <Grid size={{ xs: 12, md: 2 }}>
            <Box sx={{ display: "flex", gap: 1, height: "100%", alignItems: "center" }}>
              <Button
                startIcon={<LoginIcon />}
                size="small"
                variant="contained"
                disabled={!selectedStaff || !!selectedStaff.checkIn}
                onClick={() => selectedStaff && handleCheckIn(selectedStaff.staffId)}
              >
                Check In
              </Button>
              <Button
                startIcon={<LogoutIcon />}
                size="small"
                color="error"
                variant="contained"
                disabled={!selectedStaff || !selectedStaff.checkIn || !!selectedStaff.checkOut || !selectedStaff.id}
                onClick={() => selectedStaff && selectedStaff.id && handleCheckOut(selectedStaff.id)}
              >
                Check Out
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Card>

      <Card sx={{ p: 2 }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Staff</TableCell>
              <TableCell>Role</TableCell>
              <TableCell>Check In</TableCell>
              <TableCell>Check Out</TableCell>
              <TableCell>Status</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {staff.map((s) => (
              <TableRow key={s.staffId}>
                <TableCell>
                  <Box display="flex" alignItems="center" gap={1}>
                    <Avatar>{s.staffName.charAt(0)}</Avatar>
                    {s.staffName}
                  </Box>
                </TableCell>
                <TableCell>{s.staffRole}</TableCell>
                <TableCell>{s.checkIn || "-"}</TableCell>
                <TableCell>{s.checkOut || "-"}</TableCell>
                <TableCell>
                  <Chip
                    label={s.status}
                    color={
                      s.status === "Working"
                        ? "warning"
                        : s.status === "Completed"
                        ? "success"
                        : "default"
                    }
                    size="small"
                  />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Card>
    </Box>
  );
};

export default StaffAttendancePage;
