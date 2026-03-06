import React, { useState } from 'react';
import { Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, FormControl, InputLabel, MenuItem, Select, Switch, TextField, Typography } from '@mui/material';
import { AccountTypeIcons, accountTypes } from '../accounting.constants.tsx';

export interface AccountFormProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (data: any) => void;
  initialData?: any;
}

const AccountForm: React.FC<AccountFormProps> = ({ open, onClose, onSubmit, initialData }) => {
  const [code, setCode] = useState(initialData?.code || '');
  const [name, setName] = useState(initialData?.name || '');
  const [type, setType] = useState(initialData?.accountType || 'Asset');
  const [desc, setDesc] = useState(initialData?.description || '');
  const [active, setActive] = useState(initialData?.isActive ?? true);

  const handleSubmit = () => {
    onSubmit({ code, name, accountType: type, description: desc, isActive: active });
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>{initialData ? 'Edit Account' : 'Add Account'}</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
          <TextField label="Account Code" value={code} onChange={e => setCode(e.target.value)} fullWidth required />
          <TextField label="Account Name" value={name} onChange={e => setName(e.target.value)} fullWidth required />
          <FormControl fullWidth>
            <InputLabel>Account Type</InputLabel>
            <Select value={type} label="Account Type" onChange={e => setType(e.target.value)}>
              {accountTypes.map(t => (
                <MenuItem key={t} value={t}>
                  {AccountTypeIcons[t]} {t}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
          <TextField label="Description" value={desc} onChange={e => setDesc(e.target.value)} fullWidth multiline minRows={2} />
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Typography>Active</Typography>
            <Switch checked={active} onChange={e => setActive(e.target.checked)} />
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button variant="contained" onClick={handleSubmit}>{initialData ? 'Save' : 'Add'}</Button>
      </DialogActions>
    </Dialog>
  );
};

export default AccountForm;
