/**
 * EventForm.tsx — Create/Edit Event Form
 *
 * Features:
 * - Required fields at top
 * - Collapsible "Advanced Details" section
 * - Form validation
 * - API-ready structure
 */
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, TextField, Button, Card, Grid, MenuItem,
  Select, FormControl, InputLabel, Collapse, IconButton,
  useTheme, alpha, Divider, InputAdornment, Snackbar, Alert,
} from '@mui/material';
import {
  Save as SaveIcon,
  Cancel as CancelIcon,
  ExpandMore as ExpandIcon,
  ExpandLess as CollapseIcon,
  Celebration as EventIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  LocationOn as LocationIcon,
  CalendarToday as CalendarIcon,
  Palette as PaletteIcon,
  Notes as NotesIcon,
  Link as LinkIcon,
  People as GuestsIcon,
  AttachMoney as BudgetIcon,
} from '@mui/icons-material';
import { useNavigate, useParams } from 'react-router-dom';
import type { Event, EventFormData, EventType, EventStatus } from './EventTypes';
import {
  EVENT_TYPES,
  EVENT_STATUSES,
  EVENT_TYPE_CONFIG,
  STATUS_CONFIG,
  DESIGNERS,
  getInitialFormData,
  formDataToRequest,
} from './EventTypes';
import { MOCK_EVENTS } from './EventMockData';
import { getCurrencySymbol } from '../../core/i18n';

// ─── Form Section Component ─────────────────────────────────

interface FormSectionProps {
  title: string;
  icon?: React.ReactNode;
  children: React.ReactNode;
}

const FormSection: React.FC<FormSectionProps> = ({ title, icon, children }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Box sx={{ mb: 3 }}>
      <Typography
        variant="subtitle2"
        sx={{
          fontWeight: 700,
          mb: 2,
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary',
        }}
      >
        {icon}
        {title}
      </Typography>
      {children}
    </Box>
  );
};

// ─── Main Component ─────────────────────────────────────────

const EventForm: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const isEdit = Boolean(id);

  // State
  const [formData, setFormData] = useState<EventFormData>(getInitialFormData());
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [errors, setErrors] = useState<Partial<Record<keyof EventFormData, string>>>({});
  const [loading, setLoading] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  // Load existing event for edit
  useEffect(() => {
    if (isEdit && id) {
      const event = MOCK_EVENTS.find((e) => e.id === id);
      if (event) {
        setFormData(getInitialFormData(event));
        // Auto-expand advanced if there are optional fields filled
        if (event.venueAddress || event.colorTheme || event.moodNotes || event.budget) {
          setShowAdvanced(true);
        }
      }
    }
  }, [isEdit, id]);

  // Handlers
  const handleChange = (field: keyof EventFormData) => (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement> | { target: { value: string } }
  ) => {
    setFormData({ ...formData, [field]: e.target.value });
    // Clear error on change
    if (errors[field]) {
      setErrors({ ...errors, [field]: undefined });
    }
  };

  const validate = (): boolean => {
    const newErrors: Partial<Record<keyof EventFormData, string>> = {};

    if (!formData.eventName.trim()) newErrors.eventName = 'Event name is required';
    if (!formData.eventDate) newErrors.eventDate = 'Event date is required';
    if (!formData.clientName.trim()) newErrors.clientName = 'Client name is required';
    if (!formData.clientPhone.trim()) newErrors.clientPhone = 'Client phone is required';
    if (!formData.venueName.trim()) newErrors.venueName = 'Venue name is required';

    // Phone validation
    if (formData.clientPhone && !/^[+\d\s-]{10,}$/.test(formData.clientPhone)) {
      newErrors.clientPhone = 'Enter a valid phone number';
    }

    // Budget validation
    if (formData.budget && isNaN(parseFloat(formData.budget))) {
      newErrors.budget = 'Enter a valid amount';
    }

    // Guest count validation
    if (formData.estimatedGuestCount && isNaN(parseInt(formData.estimatedGuestCount))) {
      newErrors.estimatedGuestCount = 'Enter a valid number';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;

    setLoading(true);
    try {
      const payload = formDataToRequest(formData);
      console.log('Submitting event:', payload);

      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 800));

      setSnackbar({
        open: true,
        message: isEdit ? 'Event updated successfully!' : 'Event created successfully!',
        severity: 'success',
      });

      // Navigate back after short delay
      setTimeout(() => navigate('/events'), 1000);
    } catch (err) {
      setSnackbar({
        open: true,
        message: 'Failed to save event. Please try again.',
        severity: 'error',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 900, mx: 'auto' }}>
      {/* Header */}
      <Box sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
        <EventIcon sx={{ fontSize: 32, color: '#e91e63' }} />
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800 }}>
            {isEdit ? 'Edit Event' : 'Create New Event'}
          </Typography>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            {isEdit ? 'Update event details' : 'Add a new wedding, corporate event, or celebration'}
          </Typography>
        </Box>
      </Box>

      {/* Form Card */}
      <Card
        sx={{
          p: { xs: 2, md: 3 },
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          borderRadius: 3,
        }}
      >
        {/* ─── Required Fields ─────────────────────────── */}
        <FormSection title="Event Information" icon={<EventIcon fontSize="small" />}>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 8 }}>
              <TextField
                label="Event Name"
                value={formData.eventName}
                onChange={handleChange('eventName')}
                fullWidth
                required
                error={Boolean(errors.eventName)}
                helperText={errors.eventName}
                placeholder="e.g., Sharma-Patel Wedding"
              />
            </Grid>
            <Grid size={{ xs: 12, md: 4 }}>
              <FormControl fullWidth required>
                <InputLabel>Event Type</InputLabel>
                <Select
                  value={formData.eventType}
                  label="Event Type"
                  onChange={(e) => setFormData({ ...formData, eventType: e.target.value as EventType })}
                >
                  {EVENT_TYPES.map((type) => (
                    <MenuItem key={type} value={type}>
                      {EVENT_TYPE_CONFIG[type].icon} {EVENT_TYPE_CONFIG[type].label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}>
              <TextField
                label="Event Date"
                type="date"
                value={formData.eventDate}
                onChange={handleChange('eventDate')}
                fullWidth
                required
                error={Boolean(errors.eventDate)}
                helperText={errors.eventDate}
                InputLabelProps={{ shrink: true }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <CalendarIcon sx={{ color: 'text.secondary' }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}>
              <FormControl fullWidth>
                <InputLabel>Status</InputLabel>
                <Select
                  value={formData.status}
                  label="Status"
                  onChange={(e) => setFormData({ ...formData, status: e.target.value as EventStatus })}
                >
                  {EVENT_STATUSES.map((status) => (
                    <MenuItem key={status} value={status}>
                      {STATUS_CONFIG[status].icon} {STATUS_CONFIG[status].label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </FormSection>

        <Divider sx={{ my: 3 }} />

        {/* ─── Client Information ──────────────────────── */}
        <FormSection title="Client Information" icon={<PersonIcon fontSize="small" />}>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 6 }}>
              <TextField
                label="Client Name"
                value={formData.clientName}
                onChange={handleChange('clientName')}
                fullWidth
                required
                error={Boolean(errors.clientName)}
                helperText={errors.clientName}
                placeholder="Full name of primary contact"
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <PersonIcon sx={{ color: 'text.secondary' }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}>
              <TextField
                label="Client Phone"
                value={formData.clientPhone}
                onChange={handleChange('clientPhone')}
                fullWidth
                required
                error={Boolean(errors.clientPhone)}
                helperText={errors.clientPhone}
                placeholder="+91 98765 43210"
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <PhoneIcon sx={{ color: 'text.secondary' }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Grid>
          </Grid>
        </FormSection>

        <Divider sx={{ my: 3 }} />

        {/* ─── Venue Information ───────────────────────── */}
        <FormSection title="Venue" icon={<LocationIcon fontSize="small" />}>
          <TextField
            label="Venue Name"
            value={formData.venueName}
            onChange={handleChange('venueName')}
            fullWidth
            required
            error={Boolean(errors.venueName)}
            helperText={errors.venueName}
            placeholder="e.g., The Grand Palace"
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <LocationIcon sx={{ color: 'text.secondary' }} />
                </InputAdornment>
              ),
            }}
          />
        </FormSection>

        <Divider sx={{ my: 3 }} />

        {/* ─── Advanced Details (Collapsible) ──────────── */}
        <Box>
          <Button
            onClick={() => setShowAdvanced(!showAdvanced)}
            endIcon={showAdvanced ? <CollapseIcon /> : <ExpandIcon />}
            sx={{
              mb: 2,
              color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary',
              textTransform: 'none',
              fontWeight: 600,
            }}
          >
            Advanced Details {showAdvanced ? '(Hide)' : '(Show)'}
          </Button>

          <Collapse in={showAdvanced}>
            <Card
              sx={{
                p: 2,
                bgcolor: dk ? 'rgba(255,255,255,0.02)' : 'rgba(0,0,0,0.02)',
                border: `1px dashed ${dk ? 'rgba(255,255,255,0.1)' : '#e0e0e0'}`,
                borderRadius: 2,
              }}
            >
              <Grid container spacing={2}>
                {/* Venue Address */}
                <Grid size={{ xs: 12 }}>
                  <TextField
                    label="Venue Address"
                    value={formData.venueAddress}
                    onChange={handleChange('venueAddress')}
                    fullWidth
                    placeholder="Full address for delivery"
                  />
                </Grid>

                {/* Guest Count & Budget */}
                <Grid size={{ xs: 12, md: 6 }}>
                  <TextField
                    label="Estimated Guest Count"
                    value={formData.estimatedGuestCount}
                    onChange={handleChange('estimatedGuestCount')}
                    fullWidth
                    error={Boolean(errors.estimatedGuestCount)}
                    helperText={errors.estimatedGuestCount}
                    placeholder="e.g., 250"
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <GuestsIcon sx={{ color: 'text.secondary' }} />
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>
                <Grid size={{ xs: 12, md: 6 }}>
                  <TextField
                    label={`Budget (${getCurrencySymbol()})`}
                    value={formData.budget}
                    onChange={handleChange('budget')}
                    fullWidth
                    error={Boolean(errors.budget)}
                    helperText={errors.budget}
                    placeholder="e.g., 150000"
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <BudgetIcon sx={{ color: 'text.secondary' }} />
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>

                {/* Design Details */}
                <Grid size={{ xs: 12, md: 6 }}>
                  <TextField
                    label="Color Theme"
                    value={formData.colorTheme}
                    onChange={handleChange('colorTheme')}
                    fullWidth
                    placeholder="e.g., Blush Pink & Gold"
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <PaletteIcon sx={{ color: 'text.secondary' }} />
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>
                <Grid size={{ xs: 12, md: 6 }}>
                  <FormControl fullWidth>
                    <InputLabel>Assigned Designer</InputLabel>
                    <Select
                      value={formData.assignedDesigner}
                      label="Assigned Designer"
                      onChange={(e) => setFormData({ ...formData, assignedDesigner: e.target.value })}
                    >
                      <MenuItem value="">Unassigned</MenuItem>
                      {DESIGNERS.map((d) => (
                        <MenuItem key={d.id} value={d.name}>
                          {d.name}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>

                {/* Mood Notes */}
                <Grid size={{ xs: 12 }}>
                  <TextField
                    label="Mood / Style Notes"
                    value={formData.moodNotes}
                    onChange={handleChange('moodNotes')}
                    fullWidth
                    multiline
                    rows={3}
                    placeholder="Describe the desired style, flower preferences, special requests..."
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start" sx={{ alignSelf: 'flex-start', mt: 1 }}>
                          <NotesIcon sx={{ color: 'text.secondary' }} />
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>

                {/* Mood Board Link */}
                <Grid size={{ xs: 12 }}>
                  <TextField
                    label="Mood Board Link"
                    value={formData.moodBoardLink}
                    onChange={handleChange('moodBoardLink')}
                    fullWidth
                    placeholder="Pinterest board or image gallery URL"
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <LinkIcon sx={{ color: 'text.secondary' }} />
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>

                {/* Internal Notes */}
                <Grid size={{ xs: 12 }}>
                  <TextField
                    label="Internal Notes"
                    value={formData.internalNotes}
                    onChange={handleChange('internalNotes')}
                    fullWidth
                    multiline
                    rows={2}
                    placeholder="Notes visible only to staff (VIP status, special handling, etc.)"
                    sx={{
                      '& .MuiOutlinedInput-root': {
                        bgcolor: dk ? 'rgba(255, 193, 7, 0.05)' : 'rgba(255, 193, 7, 0.08)',
                      },
                    }}
                  />
                </Grid>
              </Grid>
            </Card>
          </Collapse>
        </Box>

        {/* ─── Action Buttons ──────────────────────────── */}
        <Box sx={{ display: 'flex', gap: 2, mt: 4, justifyContent: 'flex-end' }}>
          <Button
            variant="outlined"
            startIcon={<CancelIcon />}
            onClick={() => navigate('/events')}
            disabled={loading}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            startIcon={<SaveIcon />}
            onClick={handleSubmit}
            disabled={loading}
            sx={{
              bgcolor: '#e91e63',
              '&:hover': { bgcolor: '#c2185b' },
              fontWeight: 700,
              px: 4,
            }}
          >
            {loading ? 'Saving...' : isEdit ? 'Update Event' : 'Create Event'}
          </Button>
        </Box>
      </Card>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity={snackbar.severity} onClose={() => setSnackbar({ ...snackbar, open: false })}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default EventForm;
