/**
 * CreateTaskDialog.tsx — Reusable Task Creation Dialog
 *
 * Can be opened from:
 * - My Tasks page (manual)
 * - Order List (pre-fills entity)
 * - Event Production (pre-fills entity)
 * - Delivery Scheduler (pre-fills entity)
 */
import React, { useState, useEffect } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  TextField, Button, FormControl, InputLabel, Select, MenuItem,
  Box, Typography, useTheme, IconButton, Chip,
} from '@mui/material';
import {
  Close as CloseIcon,
  AddTask as TaskIcon,
} from '@mui/icons-material';
import type { TaskFormData, TaskPriority, RelatedEntityType } from './TaskTypes';
import { TASK_PRIORITIES, TASK_PRIORITY_CONFIG, ENTITY_TYPE_CONFIG, getInitialTaskFormData } from './TaskTypes';
import { createTask } from './TaskMockData';
import { getAllStaff } from '../staff/StaffMockData';
import { MOCK_LOCATIONS } from '../../core/location/LocationTypes';

// ─── Props ──────────────────────────────────────────────────

interface CreateTaskDialogProps {
  open: boolean;
  onClose: () => void;
  onCreated?: () => void;
  /** Pre-fill defaults when creating from another screen */
  defaults?: Partial<TaskFormData>;
}

// ─── Component ──────────────────────────────────────────────

const CreateTaskDialog: React.FC<CreateTaskDialogProps> = ({
  open,
  onClose,
  onCreated,
  defaults,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const [form, setForm] = useState<TaskFormData>(() => getInitialTaskFormData(defaults));
  const [errors, setErrors] = useState<Partial<Record<keyof TaskFormData, string>>>({});

  const activeStaff = getAllStaff().filter((s) => s.isActive);
  const activeLocations = MOCK_LOCATIONS.filter((l) => l.isActive);

  // Reset form when dialog opens with new defaults
  useEffect(() => {
    if (open) {
      setForm(getInitialTaskFormData(defaults));
      setErrors({});
    }
  }, [open, defaults]);

  const updateField = <K extends keyof TaskFormData>(field: K, value: TaskFormData[K]) => {
    setForm((prev) => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors((prev) => ({ ...prev, [field]: undefined }));
    }
  };

  const validate = (): boolean => {
    const newErrors: Partial<Record<keyof TaskFormData, string>> = {};
    if (!form.title.trim()) newErrors.title = 'Title is required';
    if (!form.assignedTo) newErrors.assignedTo = 'Please assign to a staff member';
    if (!form.locationId) newErrors.locationId = 'Location is required';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = () => {
    if (!validate()) return;

    createTask({
      tenantId: 'tenant-001',
      locationId: form.locationId,
      title: form.title.trim(),
      description: form.description.trim() || undefined,
      relatedEntityType: form.relatedEntityType || undefined,
      relatedEntityId: form.relatedEntityId.trim() || undefined,
      assignedTo: form.assignedTo,
      dueDate: form.dueDate || undefined,
      priority: form.priority,
      status: 'PENDING',
    });

    onCreated?.();
    onClose();
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          bgcolor: dk ? '#1a1a2e' : '#fff',
          borderRadius: 3,
          border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
        },
      }}
    >
      {/* Header */}
      <DialogTitle
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          pb: 1,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <TaskIcon sx={{ color: '#7c4dff' }} />
          <Typography variant="h6" sx={{ fontWeight: 700 }}>
            Create Task
          </Typography>
        </Box>
        <IconButton onClick={onClose} size="small">
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent dividers sx={{ borderColor: dk ? 'rgba(255,255,255,0.08)' : 'divider' }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5, pt: 1 }}>
          {/* Title */}
          <TextField
            label="Task Title"
            value={form.title}
            onChange={(e) => updateField('title', e.target.value)}
            error={!!errors.title}
            helperText={errors.title}
            fullWidth
            autoFocus
            placeholder="e.g. Prepare bouquet for ORD-001"
          />

          {/* Description */}
          <TextField
            label="Description (optional)"
            value={form.description}
            onChange={(e) => updateField('description', e.target.value)}
            fullWidth
            multiline
            rows={2}
            placeholder="Additional details or instructions…"
          />

          {/* Priority + Due Date row */}
          <Box sx={{ display: 'flex', gap: 2 }}>
            <FormControl size="small" sx={{ minWidth: 140 }}>
              <InputLabel>Priority</InputLabel>
              <Select
                value={form.priority}
                label="Priority"
                onChange={(e) => updateField('priority', e.target.value as TaskPriority)}
              >
                {TASK_PRIORITIES.map((p) => (
                  <MenuItem key={p} value={p}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Box
                        sx={{
                          width: 10,
                          height: 10,
                          borderRadius: '50%',
                          bgcolor: TASK_PRIORITY_CONFIG[p].color,
                        }}
                      />
                      {TASK_PRIORITY_CONFIG[p].label}
                    </Box>
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <TextField
              label="Due Date"
              type="date"
              value={form.dueDate}
              onChange={(e) => updateField('dueDate', e.target.value)}
              size="small"
              sx={{ flex: 1 }}
              slotProps={{ inputLabel: { shrink: true } }}
            />
          </Box>

          {/* Assign To */}
          <FormControl fullWidth error={!!errors.assignedTo}>
            <InputLabel>Assign To</InputLabel>
            <Select
              value={form.assignedTo}
              label="Assign To"
              onChange={(e) => updateField('assignedTo', e.target.value)}
            >
              {activeStaff.map((s) => (
                <MenuItem key={s.id} value={s.id}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    {s.name}
                    <Chip
                      label={s.role}
                      size="small"
                      sx={{
                        height: 20,
                        fontSize: '0.65rem',
                        fontWeight: 600,
                        ml: 0.5,
                      }}
                    />
                  </Box>
                </MenuItem>
              ))}
            </Select>
            {errors.assignedTo && (
              <Typography variant="caption" color="error" sx={{ mt: 0.5, ml: 1.5 }}>
                {errors.assignedTo}
              </Typography>
            )}
          </FormControl>

          {/* Location */}
          <FormControl fullWidth error={!!errors.locationId}>
            <InputLabel>Location</InputLabel>
            <Select
              value={form.locationId}
              label="Location"
              onChange={(e) => updateField('locationId', e.target.value)}
            >
              {activeLocations.map((loc) => (
                <MenuItem key={loc.id} value={loc.id}>
                  {loc.name}
                </MenuItem>
              ))}
            </Select>
            {errors.locationId && (
              <Typography variant="caption" color="error" sx={{ mt: 0.5, ml: 1.5 }}>
                {errors.locationId}
              </Typography>
            )}
          </FormControl>

          {/* Related Entity (optional) */}
          <Box sx={{ display: 'flex', gap: 2 }}>
            <FormControl size="small" sx={{ minWidth: 160 }}>
              <InputLabel>Related To</InputLabel>
              <Select
                value={form.relatedEntityType}
                label="Related To"
                onChange={(e) => updateField('relatedEntityType', e.target.value as RelatedEntityType | '')}
              >
                <MenuItem value="">None</MenuItem>
                {(Object.keys(ENTITY_TYPE_CONFIG) as RelatedEntityType[]).map((t) => (
                  <MenuItem key={t} value={t}>
                    {ENTITY_TYPE_CONFIG[t].icon} {ENTITY_TYPE_CONFIG[t].label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            {form.relatedEntityType && (
              <TextField
                label="Entity ID"
                value={form.relatedEntityId}
                onChange={(e) => updateField('relatedEntityId', e.target.value)}
                size="small"
                sx={{ flex: 1 }}
                placeholder={`e.g. ${form.relatedEntityType === 'ORDER' ? 'ORD-001' : form.relatedEntityType === 'EVENT' ? 'EVT-001' : 'ORD-002'}`}
              />
            )}
          </Box>
        </Box>
      </DialogContent>

      {/* Actions */}
      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} color="inherit">
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          startIcon={<TaskIcon />}
          sx={{
            bgcolor: '#7c4dff',
            '&:hover': { bgcolor: '#651fff' },
            fontWeight: 700,
            px: 3,
          }}
        >
          Create Task
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CreateTaskDialog;
