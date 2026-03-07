import React from "react";
import {
  Box,
  Typography,
  Card,
  Chip,
  Button,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody,
} from "@mui/material";
import { STAFF_ATTENDANCE_MOCK } from "./StaffMockData";
import LoginIcon from "@mui/icons-material/Login";
import LogoutIcon from "@mui/icons-material/Logout";

interface StaffAttendance {
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
                <TableCell>{s.staffId}</TableCell>
                <TableCell>{s.date}</TableCell>
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