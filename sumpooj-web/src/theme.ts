import { createTheme } from "@mui/material/styles";

/**
 * FloraPrice Brand Theme
 * 
 * Brand Colors:
 * - Primary Purple: #5B2E91 (main brand color)
 * - Flora Green: #2E7D32 (nature, growth)
 * - Accent Yellow: #F4C430 (highlights, CTAs)
 */

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: "#5B2E91",      // FloraPrice Purple
      light: "#7B4DB1",
      dark: "#3B1E71",
      contrastText: "#FFFFFF",
    },
    secondary: {
      main: "#2E7D32",      // Flora Green
      light: "#4CAF50",
      dark: "#1B5E20",
      contrastText: "#FFFFFF",
    },
    warning: {
      main: "#F4C430",      // Accent Yellow
      light: "#F6D55C",
      dark: "#D4A82C",
      contrastText: "#1F2937",
    },
    success: {
      main: "#2E7D32",      // Flora Green (same as secondary)
      light: "#4CAF50",
      dark: "#1B5E20",
    },
    background: {
      default: "#F9FAFB",
      paper: "#FFFFFF",
    },
    text: {
      primary: "#1F2937",
      secondary: "#6B7280",
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: {
      fontWeight: 700,
    },
    h2: {
      fontWeight: 700,
    },
    h3: {
      fontWeight: 600,
    },
    h4: {
      fontWeight: 600,
    },
    h5: {
      fontWeight: 600,
    },
    h6: {
      fontWeight: 600,
    },
    button: {
      fontWeight: 600,
      textTransform: 'none', // More modern look
    },
  },
  shape: {
    borderRadius: 8,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          padding: '8px 16px',
        },
        contained: {
          boxShadow: 'none',
          '&:hover': {
            boxShadow: '0 2px 8px rgba(91, 46, 145, 0.25)',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          '&:hover': {
            boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
          },
        },
      },
    },
  },
});

export default theme;
