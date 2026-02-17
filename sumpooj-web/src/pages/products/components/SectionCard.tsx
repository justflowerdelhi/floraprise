/**
 * Section Card Component
 * Reusable card wrapper for form sections
 */

import { useState } from 'react';
import type { ReactNode } from 'react';
import {
  Card,
  CardContent,
  Box,
  Typography,
  Collapse,
  IconButton,
  useTheme,
  alpha,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import type { SvgIconComponent } from '@mui/icons-material';

interface SectionCardProps {
  title: string;
  subtitle?: string;
  icon?: SvgIconComponent;
  children: ReactNode;
  collapsible?: boolean;
  defaultExpanded?: boolean;
  badge?: ReactNode;
  darkMode?: boolean;
  accentColor?: string;
}

const SectionCard = ({
  title,
  subtitle,
  icon: Icon,
  children,
  collapsible = false,
  defaultExpanded = true,
  badge,
  darkMode = false,
  accentColor,
}: SectionCardProps) => {
  const theme = useTheme();
  const [expanded, setExpanded] = useState(defaultExpanded);

  const bgColor = darkMode 
    ? alpha(theme.palette.grey[900], 0.8) 
    : 'white';
  
  const borderColor = darkMode
    ? theme.palette.grey[800]
    : theme.palette.grey[200];

  const headerBg = darkMode
    ? alpha(theme.palette.primary.dark, 0.1)
    : alpha(theme.palette.primary.light, 0.08);

  return (
    <Card
      elevation={0}
      sx={{
        backgroundColor: bgColor,
        border: `1px solid ${borderColor}`,
        borderRadius: 2,
        overflow: 'hidden',
        transition: 'all 0.2s ease-in-out',
        '&:hover': {
          borderColor: darkMode
            ? theme.palette.grey[700]
            : theme.palette.grey[300],
          boxShadow: darkMode
            ? '0 4px 12px rgba(0,0,0,0.3)'
            : '0 4px 12px rgba(0,0,0,0.05)',
        },
      }}
    >
      {/* Section Header */}
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          px: 2.5,
          py: 2,
          backgroundColor: headerBg,
          borderBottom: expanded ? `1px solid ${borderColor}` : 'none',
          cursor: collapsible ? 'pointer' : 'default',
          transition: 'background-color 0.2s ease',
          '&:hover': collapsible ? {
            backgroundColor: darkMode
              ? alpha(theme.palette.primary.dark, 0.15)
              : alpha(theme.palette.primary.light, 0.12),
          } : {},
        }}
        onClick={() => collapsible && setExpanded(!expanded)}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          {Icon && (
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: 36,
                height: 36,
                borderRadius: 1.5,
                backgroundColor: accentColor 
                  ? alpha(accentColor, darkMode ? 0.2 : 0.15)
                  : darkMode
                    ? alpha(theme.palette.primary.main, 0.2)
                    : alpha(theme.palette.primary.main, 0.1),
              }}
            >
              <Icon
                sx={{
                  fontSize: 20,
                  color: accentColor || theme.palette.primary.main,
                }}
              />
            </Box>
          )}
          <Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Typography
                variant="subtitle1"
                sx={{
                  fontWeight: 600,
                  color: darkMode ? 'grey.100' : 'grey.800',
                }}
              >
                {title}
              </Typography>
              {badge}
            </Box>
            {subtitle && (
              <Typography
                variant="caption"
                sx={{
                  color: darkMode ? 'grey.500' : 'grey.600',
                }}
              >
                {subtitle}
              </Typography>
            )}
          </Box>
        </Box>
        
        {collapsible && (
          <IconButton
            size="small"
            sx={{
              color: darkMode ? 'grey.500' : 'grey.600',
              transition: 'transform 0.2s ease',
            }}
          >
            {expanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
          </IconButton>
        )}
      </Box>

      {/* Section Content */}
      <Collapse in={expanded}>
        <CardContent sx={{ p: 2.5 }}>
          {children}
        </CardContent>
      </Collapse>
    </Card>
  );
};

export default SectionCard;
