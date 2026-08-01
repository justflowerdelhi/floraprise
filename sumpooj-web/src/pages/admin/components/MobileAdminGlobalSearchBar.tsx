import React, { useMemo, useState } from 'react';
import {
  Autocomplete,
  Box,
  Chip,
  CircularProgress,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import {
  searchMobileAdminGlobal,
  type MobileAdminGlobalSearchResult,
} from '../../../api/mobile-admin.api';

interface MobileAdminGlobalSearchBarProps {
  companyId?: string;
  fullWidth?: boolean;
}

const relativeTime = (value?: string | null) => {
  if (!value) return 'No activity';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'No activity';
  const ms = Date.now() - date.getTime();
  if (ms < 60000) return 'just now';
  const mins = Math.floor(ms / 60000);
  if (mins < 60) return `${mins} min ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs} hr ago`;
  const days = Math.floor(hrs / 24);
  return `${days} day${days > 1 ? 's' : ''} ago`;
};

const MobileAdminGlobalSearchBar: React.FC<MobileAdminGlobalSearchBarProps> = ({
  companyId,
  fullWidth = true,
}) => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [options, setOptions] = useState<MobileAdminGlobalSearchResult[]>([]);
  const [input, setInput] = useState('');

  const placeholder = useMemo(
    () => 'Search: business, owner, mobile, email, device id, subscription id, license id, GST',
    [],
  );

  const onInputChange = async (value: string) => {
    setInput(value);
    if (value.trim().length < 2) {
      setOptions([]);
      return;
    }

    setLoading(true);
    try {
      const rows = await searchMobileAdminGlobal(value, companyId || undefined, 12);
      setOptions(rows ?? []);
    } catch {
      setOptions([]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Autocomplete
      fullWidth={fullWidth}
      options={options}
      loading={loading}
      filterOptions={(x) => x}
      getOptionLabel={(option) => option.businessName}
      inputValue={input}
      onInputChange={(_, value) => {
        onInputChange(value).catch(() => {
          setOptions([]);
          setLoading(false);
        });
      }}
      onChange={(_, value) => {
        if (!value) return;
        navigate(`/admin/mobile/customers/${value.companyId}/${value.mobileUserId}`);
      }}
      renderInput={(params) => (
        <TextField
          {...params}
          size="small"
          label="Global Customer Search"
          placeholder={placeholder}
          InputProps={{
            ...params.InputProps,
            endAdornment: (
              <>
                {loading ? <CircularProgress size={16} /> : null}
                {params.InputProps.endAdornment}
              </>
            ),
          }}
        />
      )}
      renderOption={(props, option) => (
        <Box component="li" {...props} key={`${option.companyId}-${option.mobileUserId}`}>
          <Stack direction="row" spacing={1.25} alignItems="center" sx={{ width: '100%' }}>
            <Box sx={{ minWidth: 0, flex: 1 }}>
              <Typography variant="body2" fontWeight={700} noWrap>{option.businessName}</Typography>
              <Typography variant="caption" color="text.secondary" noWrap>
                {option.currentPlan || 'No Plan'} • Last Seen {relativeTime(option.lastSeenAtUtc)}
              </Typography>
            </Box>
            <Chip size="small" label={option.status} />
            <Chip size="small" variant="outlined" label={`${option.deviceCount} devices`} />
          </Stack>
        </Box>
      )}
      noOptionsText={input.trim().length < 2 ? 'Type at least 2 characters' : 'No customer found'}
    />
  );
};

export default MobileAdminGlobalSearchBar;
