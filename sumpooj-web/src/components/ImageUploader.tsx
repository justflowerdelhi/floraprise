/**
 * ImageUploader.tsx — Reusable Image Upload Component
 *
 * Features:
 * - Drag & drop support
 * - Browse file button
 * - Mobile camera capture (input accept="image/*" capture="environment")
 * - Preview thumbnail grid with hover-delete
 * - Multiple image support
 * - Validates file type + max 5 MB
 * - Uploads to backend → stores returned URL (no base64 in state)
 * - Loading spinner per upload
 */

import { useState, useRef, useCallback } from 'react';
import {
  Box, Typography, IconButton, CircularProgress, useTheme, alpha, Tooltip,
} from '@mui/material';
import {
  CloudUpload as UploadIcon,
  CameraAlt as CameraIcon,
  Close as CloseIcon,
  AddPhotoAlternate as AddIcon,
} from '@mui/icons-material';
import { uploadImage } from '../pages/production/api/production.api';

const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB
const ACCEPTED_TYPES = ['image/png', 'image/jpeg', 'image/webp'];

interface ImageUploaderProps {
  /** Current image URLs */
  images: string[];
  /** Called when images change (additions / removals) */
  onChange: (images: string[]) => void;
  /** Max number of images allowed (default: 10) */
  maxImages?: number;
  /** Disable uploading */
  disabled?: boolean;
}

interface UploadingFile {
  id: string;
  name: string;
  previewUrl: string;
}

const ImageUploader = ({ images, onChange, maxImages = 10, disabled = false }: ImageUploaderProps) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const fileInputRef = useRef<HTMLInputElement>(null);
  const cameraInputRef = useRef<HTMLInputElement>(null);

  const [dragOver, setDragOver] = useState(false);
  const [uploading, setUploading] = useState<UploadingFile[]>([]);
  const [error, setError] = useState('');

  // ── Validation ─────────────────────────────────────────────
  const validateFile = (file: File): string | null => {
    if (!ACCEPTED_TYPES.includes(file.type)) {
      return `"${file.name}" is not a supported format. Use PNG, JPEG, or WebP.`;
    }
    if (file.size > MAX_FILE_SIZE) {
      return `"${file.name}" exceeds 5 MB limit.`;
    }
    return null;
  };

  // ── Upload handler ─────────────────────────────────────────
  const processFiles = useCallback(async (files: FileList | File[]) => {
    setError('');
    const fileArray = Array.from(files);

    // Check capacity
    const remaining = maxImages - images.length;
    if (remaining <= 0) {
      setError(`Maximum ${maxImages} images allowed.`);
      return;
    }
    const batch = fileArray.slice(0, remaining);

    // Validate all
    for (const file of batch) {
      const err = validateFile(file);
      if (err) {
        setError(err);
        return;
      }
    }

    // Create preview entries
    const uploadEntries: UploadingFile[] = batch.map((file) => ({
      id: `upload-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
      name: file.name,
      previewUrl: URL.createObjectURL(file),
    }));
    setUploading((prev) => [...prev, ...uploadEntries]);

    // Upload each file
    const newUrls: string[] = [];
    for (let i = 0; i < batch.length; i++) {
      try {
        const url = await uploadImage(batch[i]);
        newUrls.push(url);
      } catch {
        setError(`Failed to upload "${batch[i].name}". Please try again.`);
      } finally {
        // Revoke object URL to free memory
        URL.revokeObjectURL(uploadEntries[i].previewUrl);
      }
    }

    // Remove upload entries + add new URLs
    setUploading((prev) => prev.filter((u) => !uploadEntries.some((e) => e.id === u.id)));
    if (newUrls.length > 0) {
      onChange([...images, ...newUrls]);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [images, maxImages, onChange]);

  // ── Event handlers ─────────────────────────────────────────
  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    if (!disabled) setDragOver(true);
  };

  const handleDragLeave = () => setDragOver(false);

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    if (disabled) return;
    if (e.dataTransfer.files.length > 0) {
      processFiles(e.dataTransfer.files);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      processFiles(e.target.files);
    }
    // Reset so same file can be re-selected
    e.target.value = '';
  };

  const handleRemoveImage = (index: number) => {
    onChange(images.filter((_, i) => i !== index));
  };

  const canAddMore = images.length + uploading.length < maxImages && !disabled;

  return (
    <Box>
      {/* ── Drop Zone ────────────────────────────────────── */}
      <Box
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onClick={() => canAddMore && fileInputRef.current?.click()}
        sx={{
          border: `2px dashed ${dragOver ? theme.palette.primary.main : dk ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.15)'}`,
          borderRadius: 2,
          p: 3,
          textAlign: 'center',
          cursor: canAddMore ? 'pointer' : 'default',
          bgcolor: dragOver
            ? alpha(theme.palette.primary.main, 0.06)
            : dk ? 'rgba(255,255,255,0.02)' : 'rgba(0,0,0,0.01)',
          transition: 'all 0.2s ease',
          '&:hover': canAddMore ? {
            borderColor: theme.palette.primary.main,
            bgcolor: alpha(theme.palette.primary.main, 0.04),
          } : {},
          opacity: disabled ? 0.5 : 1,
        }}
      >
        <UploadIcon sx={{ fontSize: 36, color: 'text.disabled', mb: 0.5 }} />
        <Typography variant="body2" color="text.secondary" fontWeight={500}>
          Drag & drop images here, or click to browse
        </Typography>
        <Typography variant="caption" color="text.disabled">
          PNG, JPEG, WebP — max 5 MB each
        </Typography>

        {/* Action buttons row */}
        <Box sx={{ display: 'flex', justifyContent: 'center', gap: 1, mt: 1.5 }}>
          <Tooltip title="Browse files">
            <IconButton
              size="small"
              onClick={(e) => { e.stopPropagation(); canAddMore && fileInputRef.current?.click(); }}
              disabled={!canAddMore}
              sx={{
                bgcolor: alpha(theme.palette.primary.main, 0.08),
                '&:hover': { bgcolor: alpha(theme.palette.primary.main, 0.16) },
              }}
            >
              <AddIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Take photo">
            <IconButton
              size="small"
              onClick={(e) => { e.stopPropagation(); canAddMore && cameraInputRef.current?.click(); }}
              disabled={!canAddMore}
              sx={{
                bgcolor: alpha(theme.palette.primary.main, 0.08),
                '&:hover': { bgcolor: alpha(theme.palette.primary.main, 0.16) },
              }}
            >
              <CameraIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* Hidden file inputs */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/png,image/jpeg,image/webp"
        multiple
        hidden
        onChange={handleFileSelect}
      />
      <input
        ref={cameraInputRef}
        type="file"
        accept="image/*"
        capture="environment"
        hidden
        onChange={handleFileSelect}
      />

      {/* ── Error ────────────────────────────────────────── */}
      {error && (
        <Typography variant="caption" color="error" sx={{ display: 'block', mt: 1 }}>
          {error}
        </Typography>
      )}

      {/* ── Thumbnail Grid ───────────────────────────────── */}
      {(images.length > 0 || uploading.length > 0) && (
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(90px, 1fr))',
            gap: 1,
            mt: 2,
          }}
        >
          {/* Uploaded thumbnails */}
          {images.map((url, i) => (
            <Box
              key={`img-${i}`}
              sx={{
                position: 'relative',
                aspectRatio: '1',
                borderRadius: 1.5,
                overflow: 'hidden',
                border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'}`,
                '&:hover .delete-btn': { opacity: 1 },
              }}
            >
              <Box
                component="img"
                src={url}
                alt={`Upload ${i + 1}`}
                sx={{
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover',
                }}
              />
              {!disabled && (
                <IconButton
                  className="delete-btn"
                  size="small"
                  onClick={() => handleRemoveImage(i)}
                  sx={{
                    position: 'absolute',
                    top: 4,
                    right: 4,
                    bgcolor: 'rgba(0,0,0,0.6)',
                    color: '#fff',
                    opacity: 0,
                    transition: 'opacity 0.2s',
                    '&:hover': { bgcolor: 'rgba(244,67,54,0.85)' },
                    width: 24,
                    height: 24,
                  }}
                >
                  <CloseIcon sx={{ fontSize: 16 }} />
                </IconButton>
              )}
            </Box>
          ))}

          {/* Uploading placeholders */}
          {uploading.map((u) => (
            <Box
              key={u.id}
              sx={{
                position: 'relative',
                aspectRatio: '1',
                borderRadius: 1.5,
                overflow: 'hidden',
                border: `1px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'}`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
              }}
            >
              <Box
                component="img"
                src={u.previewUrl}
                alt={u.name}
                sx={{ width: '100%', height: '100%', objectFit: 'cover', opacity: 0.4 }}
              />
              <CircularProgress
                size={24}
                sx={{ position: 'absolute', color: theme.palette.primary.main }}
              />
            </Box>
          ))}
        </Box>
      )}

      {/* ── Counter ──────────────────────────────────────── */}
      {maxImages < Infinity && (
        <Typography variant="caption" color="text.disabled" sx={{ display: 'block', mt: 1 }}>
          {images.length}/{maxImages} images
        </Typography>
      )}
    </Box>
  );
};

export default ImageUploader;
