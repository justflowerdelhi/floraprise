<<<<<<< HEAD
import React from "react";
=======
import React, { useState, useEffect } from "react";
>>>>>>> 6132b76c6fe162bd9d1045805a855f1ebaf7223c
import {
  Box,
  Typography,
  Card,
<<<<<<< HEAD
=======
  Avatar,
>>>>>>> 6132b76c6fe162bd9d1045805a855f1ebaf7223c
  Chip,
  Button,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody,
  CircularProgress,
} from "@mui/material";
import { STAFF_ATTENDANCE_MOCK } from "./StaffMockData";
import LoginIcon from "@mui/icons-material/Login";
import LogoutIcon from "@mui/icons-material/Logout";
import api from "../../api/axios";

interface StaffAttendance {
<<<<<<< HEAD
  staffId: string;
  date: string;
  status: string;
  checkIn: string | null;
  checkOut: string | null;
}

const initialData: StaffAttendance[] = STAFF_ATTENDANCE_MOCK;

const StaffAttendancePage: React.FC = () => {
  const [staff, setStaff] = React.useState<StaffAttendance[]>(initialData);

  const handleCheckIn = (staffId: string) => {
    const now = new Date().toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    });
    setStaff((prev) =>
      prev.map((s) =>
        s.staffId === staffId ? { ...s, checkIn: now, status: "Working" } : s
      )
    );
  };

  const handleCheckOut = (staffId: string) => {
    const now = new Date().toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    });
    setStaff((prev) =>
      prev.map((s) =>
        s.staffId === staffId ? { ...s, checkOut: now, status: "Completed" } : s
      )
    );
=======
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
>>>>>>> 6132b76c6fe162bd9d1045805a855f1ebaf7223c
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
              <TableCell>Staff ID</TableCell>
              <TableCell>Date</TableCell>
              <TableCell>Check In</TableCell>
              <TableCell>Check Out</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {staff.map((s) => (
              <TableRow key={s.staffId}>
<<<<<<< HEAD
                <TableCell>{s.staffId}</TableCell>
                <TableCell>{s.date}</TableCell>
=======
                <TableCell>
                  <Box display="flex" alignItems="center" gap={1}>
                    <Avatar>{s.staffName.charAt(0)}</Avatar>
                    {s.staffName}
                  </Box>
                </TableCell>

                <TableCell>{s.staffRole}</TableCell>

>>>>>>> 6132b76c6fe162bd9d1045805a855f1ebaf7223c
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
                      onClick={() => handleCheckOut(s.staffId)}
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