/**
 * ChangePasswordDialog.tsx — Change own password + Admin reset other users' passwords
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, TextField, Alert, Typography, Box,
  Autocomplete, CircularProgress, Tabs, Tab,
} from '@mui/material';
import { changePassword, adminResetPassword, getManageableUsers } from '../api/auth.api';

interface ChangePasswordDialogProps {
  open: boolean;
  onClose: () => void;
  /** Current user's role (PLATFORMSUPERADMIN, ADMIN, MANAGER, etc.) */
  userRole: string;
}

interface ManagedUser {
  id: string;
  email: string;
  companyId: string | null;
}

const ChangePasswordDialog: React.FC<ChangePasswordDialogProps> = ({ open, onClose, userRole }) => {
  const canManageUsers = ['PLATFORMSUPERADMIN', 'ADMIN'].includes(userRole);

  const [tab, setTab] = useState(0);

  // Own password
  const [currentPwd, setCurrentPwd] = useState('');
  const [newPwd, setNewPwd] = useState('');
  const [confirmPwd, setConfirmPwd] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Admin reset
  const [users, setUsers] = useState<ManagedUser[]>([]);
  const [usersLoading, setUsersLoading] = useState(false);
  const [selectedUser, setSelectedUser] = useState<ManagedUser | null>(null);
  const [resetPwd, setResetPwd] = useState('');
  const [resetConfirmPwd, setResetConfirmPwd] = useState('');
  const [resetSaving, setResetSaving] = useState(false);
  const [resetError, setResetError] = useState('');
  const [resetSuccess, setResetSuccess] = useState('');

  // Reset state when dialog opens/closes
  useEffect(() => {
    if (open) {
      setTab(0);
      setCurrentPwd(''); setNewPwd(''); setConfirmPwd('');
      setError(''); setSuccess('');
      setSelectedUser(null); setResetPwd(''); setResetConfirmPwd('');
      setResetError(''); setResetSuccess('');
    }
  }, [open]);

  // Load manageable users when admin tab is selected
  const loadUsers = useCallback(async () => {
    if (!canManageUsers) return;
    setUsersLoading(true);
    try {
      const data = await getManageableUsers();
      setUsers(data);
    } catch {
      setUsers([]);
    } finally {
      setUsersLoading(false);
    }
  }, [canManageUsers]);

  useEffect(() => {
    if (open && tab === 1 && canManageUsers && users.length === 0) {
      loadUsers();
    }
  }, [open, tab, canManageUsers, loadUsers]);

  const handleChangeOwn = async () => {
    setError(''); setSuccess('');
    if (!currentPwd.trim()) { setError('Current password is required.'); return; }
    if (newPwd.length < 6) { setError('New password must be at least 6 characters.'); return; }
    if (newPwd !== confirmPwd) { setError('Passwords do not match.'); return; }

    setSaving(true);
    try {
      await changePassword(currentPwd, newPwd);
      setSuccess('Password changed successfully!');
      setCurrentPwd(''); setNewPwd(''); setConfirmPwd('');
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Failed to change password.');
    } finally {
      setSaving(false);
    }
  };

  const handleResetUser = async () => {
    setResetError(''); setResetSuccess('');
    if (!selectedUser) { setResetError('Please select a user.'); return; }
    if (resetPwd.length < 6) { setResetError('Password must be at least 6 characters.'); return; }
    if (resetPwd !== resetConfirmPwd) { setResetError('Passwords do not match.'); return; }

    setResetSaving(true);
    try {
      await adminResetPassword(selectedUser.id, resetPwd);
      setResetSuccess(`Password reset for ${selectedUser.email}`);
      setSelectedUser(null); setResetPwd(''); setResetConfirmPwd('');
    } catch (err: any) {
      setResetError(err?.response?.data?.message || 'Failed to reset password.');
    } finally {
      setResetSaving(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Password Management</DialogTitle>
      <DialogContent>
        {canManageUsers ? (
          <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 2 }}>
            <Tab label="Change My Password" />
            <Tab label="Reset User Password" />
          </Tabs>
        ) : (
          <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 2 }}>
            Change your password
          </Typography>
        )}

        {/* Tab 0: Change Own Password */}
        {tab === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {error && <Alert severity="error">{error}</Alert>}
            {success && <Alert severity="success">{success}</Alert>}
            <TextField
              label="Current Password"
              type="password"
              value={currentPwd}
              onChange={e => setCurrentPwd(e.target.value)}
              fullWidth
              autoFocus
            />
            <TextField
              label="New Password"
              type="password"
              value={newPwd}
              onChange={e => setNewPwd(e.target.value)}
              fullWidth
              helperText="Minimum 6 characters"
            />
            <TextField
              label="Confirm New Password"
              type="password"
              value={confirmPwd}
              onChange={e => setConfirmPwd(e.target.value)}
              fullWidth
              error={confirmPwd.length > 0 && newPwd !== confirmPwd}
              helperText={confirmPwd.length > 0 && newPwd !== confirmPwd ? 'Passwords do not match' : ''}
            />
          </Box>
        )}

        {/* Tab 1: Admin Reset (only for admin roles) */}
        {tab === 1 && canManageUsers && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {resetError && <Alert severity="error">{resetError}</Alert>}
            {resetSuccess && <Alert severity="success">{resetSuccess}</Alert>}
            <Autocomplete
              options={users}
              getOptionLabel={(u) => u.email ?? ''}
              value={selectedUser}
              onChange={(_, v) => setSelectedUser(v)}
              loading={usersLoading}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Select User"
                  placeholder="Search by email..."
                  InputProps={{
                    ...params.InputProps,
                    endAdornment: (
                      <>
                        {usersLoading ? <CircularProgress size={20} /> : null}
                        {params.InputProps.endAdornment}
                      </>
                    ),
                  }}
                />
              )}
              fullWidth
            />
            <TextField
              label="New Password"
              type="password"
              value={resetPwd}
              onChange={e => setResetPwd(e.target.value)}
              fullWidth
              helperText="Minimum 6 characters"
              disabled={!selectedUser}
            />
            <TextField
              label="Confirm Password"
              type="password"
              value={resetConfirmPwd}
              onChange={e => setResetConfirmPwd(e.target.value)}
              fullWidth
              error={resetConfirmPwd.length > 0 && resetPwd !== resetConfirmPwd}
              helperText={resetConfirmPwd.length > 0 && resetPwd !== resetConfirmPwd ? 'Passwords do not match' : ''}
              disabled={!selectedUser}
            />
          </Box>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        {tab === 0 && (
          <Button variant="contained" onClick={handleChangeOwn} disabled={saving}>
            {saving ? 'Changing…' : 'Change Password'}
          </Button>
        )}
        {tab === 1 && canManageUsers && (
          <Button variant="contained" onClick={handleResetUser} disabled={resetSaving || !selectedUser}>
            {resetSaving ? 'Resetting…' : 'Reset Password'}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default ChangePasswordDialog;
