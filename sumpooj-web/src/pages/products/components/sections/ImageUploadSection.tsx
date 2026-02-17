/**
 * Image Upload Section
 * Multi-image upload with previews (UI only)
 */

import { useState, useCallback } from 'react';
import {
  Grid,
  Box,
  Typography,
  IconButton,
  Button,
  ImageList,
  ImageListItem,
  ImageListItemBar,
  alpha,
  useTheme,
} from '@mui/material';
import PhotoLibraryIcon from '@mui/icons-material/PhotoLibrary';
import CloudUploadIcon from '@mui/icons-material/CloudUpload';
import DeleteIcon from '@mui/icons-material/Delete';
import StarIcon from '@mui/icons-material/Star';
import StarBorderIcon from '@mui/icons-material/StarBorder';
import SectionCard from '../SectionCard';
import type { FormSectionProps } from '../../types/product.types';

interface ImageUploadSectionProps extends FormSectionProps {
  images: File[];
  imageUrls: string[];
  onImagesChange: (files: File[], urls: string[]) => void;
}

const ImageUploadSection = ({
  control,
  errors,
  watch,
  setValue,
  darkMode = false,
  images,
  imageUrls,
  onImagesChange,
}: ImageUploadSectionProps) => {
  const theme = useTheme();
  const [primaryIndex, setPrimaryIndex] = useState(0);
  const [isDragging, setIsDragging] = useState(false);

  const handleFileSelect = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      const files = event.target.files;
      if (!files) return;

      const newFiles = [...images];
      const newUrls = [...imageUrls];

      Array.from(files).forEach((file) => {
        if (file.type.startsWith('image/')) {
          newFiles.push(file);
          newUrls.push(URL.createObjectURL(file));
        }
      });

      onImagesChange(newFiles, newUrls);
      event.target.value = ''; // Reset input
    },
    [images, imageUrls, onImagesChange]
  );

  const handleDrop = useCallback(
    (event: React.DragEvent<HTMLDivElement>) => {
      event.preventDefault();
      setIsDragging(false);

      const files = event.dataTransfer.files;
      const newFiles = [...images];
      const newUrls = [...imageUrls];

      Array.from(files).forEach((file) => {
        if (file.type.startsWith('image/')) {
          newFiles.push(file);
          newUrls.push(URL.createObjectURL(file));
        }
      });

      onImagesChange(newFiles, newUrls);
    },
    [images, imageUrls, onImagesChange]
  );

  const handleDragOver = useCallback((event: React.DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback(() => {
    setIsDragging(false);
  }, []);

  const handleRemove = useCallback(
    (index: number) => {
      const newFiles = images.filter((_, i) => i !== index);
      const newUrls = imageUrls.filter((_, i) => i !== index);

      // Revoke the URL to prevent memory leaks
      URL.revokeObjectURL(imageUrls[index]);

      // Adjust primary index if needed
      if (primaryIndex === index) {
        setPrimaryIndex(0);
      } else if (primaryIndex > index) {
        setPrimaryIndex(primaryIndex - 1);
      }

      onImagesChange(newFiles, newUrls);
    },
    [images, imageUrls, primaryIndex, onImagesChange]
  );

  const handleSetPrimary = useCallback((index: number) => {
    setPrimaryIndex(index);
  }, []);

  return (
    <SectionCard
      title="Product Images"
      subtitle="Upload product photos"
      icon={PhotoLibraryIcon}
      darkMode={darkMode}
      accentColor="#673ab7"
      collapsible
      defaultExpanded={false}
    >
      <Grid container spacing={2.5}>
        {/* Drop Zone */}
        <Grid size={{ xs: 12 }}>
          <Box
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            sx={{
              border: '2px dashed',
              borderColor: isDragging
                ? 'primary.main'
                : darkMode
                  ? 'grey.700'
                  : 'grey.300',
              borderRadius: 2,
              p: 4,
              textAlign: 'center',
              backgroundColor: isDragging
                ? alpha(theme.palette.primary.main, 0.1)
                : darkMode
                  ? 'grey.900'
                  : 'grey.50',
              transition: 'all 0.2s ease',
              cursor: 'pointer',
              '&:hover': {
                borderColor: 'primary.main',
                backgroundColor: alpha(theme.palette.primary.main, 0.05),
              },
            }}
          >
            <input
              type="file"
              accept="image/*"
              multiple
              onChange={handleFileSelect}
              style={{ display: 'none' }}
              id="image-upload-input"
            />
            <label htmlFor="image-upload-input" style={{ cursor: 'pointer' }}>
              <CloudUploadIcon
                sx={{
                  fontSize: 48,
                  color: isDragging ? 'primary.main' : 'grey.400',
                  mb: 1,
                }}
              />
              <Typography variant="body1" color="text.secondary" gutterBottom>
                {isDragging
                  ? 'Drop images here...'
                  : 'Drag & drop images here or click to browse'}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Supports: JPG, PNG, WEBP (max 5MB each)
              </Typography>
            </label>
          </Box>
        </Grid>

        {/* Image Previews */}
        {imageUrls.length > 0 && (
          <Grid size={{ xs: 12 }}>
            <Typography
              variant="subtitle2"
              sx={{ mb: 1.5, color: darkMode ? 'grey.400' : 'grey.600' }}
            >
              Uploaded Images ({imageUrls.length})
            </Typography>
            <ImageList
              sx={{
                width: '100%',
                maxHeight: 300,
                borderRadius: 2,
                overflow: 'hidden',
              }}
              cols={window.innerWidth < 600 ? 2 : 4}
              rowHeight={140}
              gap={8}
            >
              {imageUrls.map((url, index) => (
                <ImageListItem
                  key={url}
                  sx={{
                    borderRadius: 1,
                    overflow: 'hidden',
                    border: primaryIndex === index ? '3px solid' : '1px solid',
                    borderColor:
                      primaryIndex === index
                        ? 'primary.main'
                        : darkMode
                          ? 'grey.800'
                          : 'grey.200',
                  }}
                >
                  <img
                    src={url}
                    alt={`Product image ${index + 1}`}
                    loading="lazy"
                    style={{
                      objectFit: 'cover',
                      width: '100%',
                      height: '100%',
                    }}
                  />
                  <ImageListItemBar
                    sx={{
                      background:
                        'linear-gradient(to top, rgba(0,0,0,0.7) 0%, rgba(0,0,0,0.3) 70%, rgba(0,0,0,0) 100%)',
                    }}
                    actionIcon={
                      <Box sx={{ display: 'flex', gap: 0.5 }}>
                        <IconButton
                          size="small"
                          onClick={() => handleSetPrimary(index)}
                          sx={{ color: 'white' }}
                        >
                          {primaryIndex === index ? (
                            <StarIcon sx={{ color: 'warning.main' }} />
                          ) : (
                            <StarBorderIcon />
                          )}
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => handleRemove(index)}
                          sx={{ color: 'white' }}
                        >
                          <DeleteIcon />
                        </IconButton>
                      </Box>
                    }
                  />
                  {primaryIndex === index && (
                    <Box
                      sx={{
                        position: 'absolute',
                        top: 4,
                        left: 4,
                        backgroundColor: 'primary.main',
                        color: 'white',
                        px: 1,
                        py: 0.25,
                        borderRadius: 1,
                        fontSize: '0.65rem',
                        fontWeight: 600,
                      }}
                    >
                      PRIMARY
                    </Box>
                  )}
                </ImageListItem>
              ))}
            </ImageList>
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
              Click the star icon to set the primary image
            </Typography>
          </Grid>
        )}
      </Grid>
    </SectionCard>
  );
};

export default ImageUploadSection;
