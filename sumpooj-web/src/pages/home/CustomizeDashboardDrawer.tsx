/**
 * CustomizeDashboardDrawer.tsx — Drawer for show/hide + reorder dashboard modules
 *
 * Features:
 * - Checkbox per module (visible / hidden)
 * - Drag-and-drop reordering via pointer events (no extra lib)
 * - Core modules (POS) cannot be hidden
 * - Save button calls POST /api/dashboard-preference
 */
import React, { useState, useCallback, useRef } from 'react';
import {
  Drawer,
  Box,
  Typography,
  Button,
  IconButton,
  Checkbox,
  Divider,
  CircularProgress,
} from '@mui/material';
import {
  Close as CloseIcon,
  DragIndicator as DragIcon,
  Save as SaveIcon,
} from '@mui/icons-material';

// ─── Types ──────────────────────────────────────────────────

/** Module keys that cannot be hidden */
const CORE_MODULES = new Set(['POS']);

export interface ModuleItem {
  key: string;
  visible: boolean;
}

interface Props {
  open: boolean;
  onClose: () => void;
  modules: ModuleItem[];
  saving: boolean;
  onSave: (modules: ModuleItem[]) => void;
}

// ─── Component ──────────────────────────────────────────────

const CustomizeDashboardDrawer: React.FC<Props> = ({ open, onClose, modules: initialModules, saving, onSave }) => {
  const [items, setItems] = useState<ModuleItem[]>(initialModules);

  // Sync when drawer opens with new data
  React.useEffect(() => {
    if (open) setItems(initialModules);
  }, [open, initialModules]);

  // ── Drag state ────────────────────────────────
  const dragIdx = useRef<number | null>(null);
  const [dragOverIdx, setDragOverIdx] = useState<number | null>(null);

  const handleDragStart = useCallback((idx: number) => {
    dragIdx.current = idx;
  }, []);

  const handleDragOver = useCallback((e: React.DragEvent, idx: number) => {
    e.preventDefault();
    setDragOverIdx(idx);
  }, []);

  const handleDrop = useCallback((idx: number) => {
    const from = dragIdx.current;
    if (from === null || from === idx) {
      dragIdx.current = null;
      setDragOverIdx(null);
      return;
    }
    setItems((prev) => {
      const next = [...prev];
      const [moved] = next.splice(from, 1);
      next.splice(idx, 0, moved);
      return next;
    });
    dragIdx.current = null;
    setDragOverIdx(null);
  }, []);

  const handleDragEnd = useCallback(() => {
    dragIdx.current = null;
    setDragOverIdx(null);
  }, []);

  // ── Toggle visibility ─────────────────────────
  const toggleVisible = useCallback((key: string) => {
    if (CORE_MODULES.has(key)) return; // can't hide core modules
    setItems((prev) =>
      prev.map((m) => (m.key === key ? { ...m, visible: !m.visible } : m)),
    );
  }, []);

  return (
    <Drawer
      anchor="right"
      open={open}
      onClose={onClose}
      PaperProps={{ sx: { width: { xs: '100%', sm: 380 }, display: 'flex', flexDirection: 'column' } }}
    >
      {/* ── Header ─────────────────────────────── */}
      <Box sx={{ p: 2, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Typography variant="h6" fontWeight={700}>
          Customize Dashboard
        </Typography>
        <IconButton onClick={onClose} size="small">
          <CloseIcon />
        </IconButton>
      </Box>

      <Divider />

      <Typography variant="body2" sx={{ px: 2, pt: 1.5, pb: 1, color: 'text.secondary' }}>
        Drag to reorder. Uncheck to hide. Core modules cannot be hidden.
      </Typography>

      {/* ── Module list ────────────────────────── */}
      <Box sx={{ flex: 1, overflowY: 'auto', px: 1 }}>
        {items.map((mod, idx) => {
          const isCore = CORE_MODULES.has(mod.key);
          const isDragOver = dragOverIdx === idx;

          return (
            <Box
              key={mod.key}
              draggable
              onDragStart={() => handleDragStart(idx)}
              onDragOver={(e) => handleDragOver(e, idx)}
              onDrop={() => handleDrop(idx)}
              onDragEnd={handleDragEnd}
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 1,
                py: 1,
                px: 1.5,
                mx: 0.5,
                my: 0.5,
                borderRadius: 2,
                cursor: 'grab',
                bgcolor: isDragOver ? 'action.hover' : 'transparent',
                border: isDragOver ? '2px dashed' : '2px solid transparent',
                borderColor: isDragOver ? 'primary.main' : 'transparent',
                transition: 'background 150ms, border 150ms',
                '&:hover': { bgcolor: 'action.hover' },
                opacity: mod.visible ? 1 : 0.5,
                userSelect: 'none',
                touchAction: 'none',
              }}
            >
              {/* Drag handle */}
              <DragIcon sx={{ color: 'text.disabled', fontSize: 20 }} />

              {/* Checkbox */}
              <Checkbox
                checked={mod.visible}
                disabled={isCore}
                onChange={() => toggleVisible(mod.key)}
                size="small"
                sx={{ p: 0.5 }}
              />

              {/* Module name */}
              <Typography
                variant="body2"
                sx={{
                  flex: 1,
                  fontWeight: mod.visible ? 600 : 400,
                  color: mod.visible ? 'text.primary' : 'text.disabled',
                }}
              >
                {mod.key}
              </Typography>

              {isCore && (
                <Typography variant="caption" sx={{ color: 'text.disabled', fontSize: 10 }}>
                  Required
                </Typography>
              )}
            </Box>
          );
        })}
      </Box>

      <Divider />

      {/* ── Footer ─────────────────────────────── */}
      <Box sx={{ p: 2, display: 'flex', gap: 1.5 }}>
        <Button variant="outlined" fullWidth onClick={onClose} disabled={saving}>
          Cancel
        </Button>
        <Button
          variant="contained"
          fullWidth
          onClick={() => onSave(items)}
          disabled={saving}
          startIcon={saving ? <CircularProgress size={18} color="inherit" /> : <SaveIcon />}
        >
          {saving ? 'Saving…' : 'Save Layout'}
        </Button>
      </Box>
    </Drawer>
  );
};

export default CustomizeDashboardDrawer;
