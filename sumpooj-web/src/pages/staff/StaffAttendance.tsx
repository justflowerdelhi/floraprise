import React, { useState } from "react";
import {
  Box,
  Typography,
  Card,
  Grid,
  Avatar,
  Chip,
  Button,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody,
} from "@mui/material";
import LoginIcon from "@mui/icons-material/Login";
import LogoutIcon from "@mui/icons-material/Logout";

interface StaffAttendance {
  id: number;
  name: string;
  role: string;
  checkIn?: string;
  checkOut?: string;
  status: "Working" | "Absent" | "Completed";
}

const initialData: StaffAttendance[] = [
  { id: 1, name: "Anita Cashier", role: "Cashier", status: "Absent" },
  { id: 2, name: "Vikram Designer", role: "Designer", status: "Absent" },
  { id: 3, name: "Ramesh Driver", role: "Driver", status: "Absent" },
];

const StaffAttendancePage: React.FC = () => {
  const [staff, setStaff] = useState<StaffAttendance[]>(initialData);

  const handleCheckIn = (id: number) => {
    const now = new Date().toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    });

    setStaff((prev) =>
      prev.map((s) =>
        s.id === id
          ? { ...s, checkIn: now, status: "Working" }
          : s
      )
    );
  };

  const handleCheckOut = (id: number) => {
    const now = new Date().toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    });

    setStaff((prev) =>
      prev.map((s) =>
        s.id === id
          ? { ...s, checkOut: now, status: "Completed" }
          : s
      )
    );
  };

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
              <TableRow key={s.id}>
                <TableCell>
                  <Box display="flex" alignItems="center" gap={1}>
                    <Avatar>{s.name.charAt(0)}</Avatar>
                    {s.name}
                  </Box>
                </TableCell>

                <TableCell>{s.role}</TableCell>

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
                      onClick={() => handleCheckIn(s.id)}
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