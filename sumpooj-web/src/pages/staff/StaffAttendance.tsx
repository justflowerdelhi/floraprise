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

  useEffect(() => {
    const load = async () => {
      try {
        const res = await api.get("/staff/attendance/today");
        setStaff(res.data);
      } catch (err) {
        console.error("Failed to load attendance:", err);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const handleCheckIn = async (staffId: string) => {
    try {
      const res = await api.post(`/staff/attendance/${staffId}/check-in`);
      setStaff((prev) =>
        prev.map((s) => (s.staffId === staffId ? res.data : s))
      );
    } catch (err) {
      console.error("Check-in failed:", err);
    }
  };

  const handleCheckOut = async (recordId: string) => {
    try {
      const res = await api.post(`/staff/attendance/${recordId}/check-out`);
      setStaff((prev) =>
        prev.map((s) => (s.id === recordId ? res.data : s))
      );
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

      <Card sx={{ p: 2 }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Staff</TableCell>
              <TableCell>Role</TableCell>
              <TableCell>Check In</TableCell>
              <TableCell>Check Out</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Actions</TableCell>
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

                <TableCell>
                  {!s.checkIn && (
                    <Button
                      startIcon={<LoginIcon />}
                      size="small"
                      variant="contained"
                      onClick={() => handleCheckIn(s.staffId)}
                    >
                      Check In
                    </Button>
                  )}

                  {s.checkIn && !s.checkOut && (
                    <Button
                      startIcon={<LogoutIcon />}
                      size="small"
                      color="error"
                      variant="contained"
                      onClick={() => handleCheckOut(s.id)}
                    >
                      Check Out
                    </Button>
                  )}
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