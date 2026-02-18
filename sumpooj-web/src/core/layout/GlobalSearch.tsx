/**
 * GlobalSearch.tsx — Universal Search Component
 *
 * Search across:
 * - Products
 * - Orders
 * - Customers
 *
 * Features:
 * - Keyboard shortcut (Ctrl+K)
 * - Category filtering
 * - Recent searches
 * - Quick navigation
 */
import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  Box, Typography, TextField, InputAdornment, Dialog, Chip, List,
  ListItem, ListItemButton, ListItemIcon, ListItemText, Divider,
  IconButton, useTheme, alpha, Fade,
} from '@mui/material';
import {
  Search as SearchIcon,
  Close as CloseIcon,
  LocalFlorist as ProductIcon,
  Receipt as OrderIcon,
  Person as CustomerIcon,
  History as HistoryIcon,
  TrendingUp as TrendingIcon,
  Keyboard as KeyboardIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

// ─── Types ──────────────────────────────────────────────────

type SearchCategory = 'all' | 'products' | 'orders' | 'customers';

interface SearchResult {
  id: string;
  type: 'product' | 'order' | 'customer';
  title: string;
  subtitle: string;
  path: string;
  icon: React.ReactNode;
}

// ─── Mock Search Data ───────────────────────────────────────

const MOCK_PRODUCTS: SearchResult[] = [
  { id: 'p1', type: 'product', title: 'Red Rose Bouquet', subtitle: 'SKU: RRB-001 • ₹1,500', path: '/products/p1', icon: <ProductIcon /> },
  { id: 'p2', type: 'product', title: 'White Lily Arrangement', subtitle: 'SKU: WLA-002 • ₹2,200', path: '/products/p2', icon: <ProductIcon /> },
  { id: 'p3', type: 'product', title: 'Mixed Flower Basket', subtitle: 'SKU: MFB-003 • ₹1,800', path: '/products/p3', icon: <ProductIcon /> },
  { id: 'p4', type: 'product', title: 'Orchid Plant', subtitle: 'SKU: ORC-004 • ₹3,500', path: '/products/p4', icon: <ProductIcon /> },
  { id: 'p5', type: 'product', title: 'Sunflower Bunch', subtitle: 'SKU: SFB-005 • ₹800', path: '/products/p5', icon: <ProductIcon /> },
];

const MOCK_ORDERS: SearchResult[] = [
  { id: 'o1', type: 'order', title: 'Order #1234', subtitle: 'Rahul Sharma • Delivery Today', path: '/order-list?id=1234', icon: <OrderIcon /> },
  { id: 'o2', type: 'order', title: 'Order #1235', subtitle: 'Priya Patel • Ready for Pickup', path: '/order-list?id=1235', icon: <OrderIcon /> },
  { id: 'o3', type: 'order', title: 'Order #1236', subtitle: 'Ankit Singh • Being Made', path: '/order-list?id=1236', icon: <OrderIcon /> },
];

const MOCK_CUSTOMERS: SearchResult[] = [
  { id: 'c1', type: 'customer', title: 'Rahul Sharma', subtitle: '+91 98765 43210 • 12 orders', path: '/customers?id=c1', icon: <CustomerIcon /> },
  { id: 'c2', type: 'customer', title: 'Priya Patel', subtitle: '+91 87654 32109 • 8 orders', path: '/customers?id=c2', icon: <CustomerIcon /> },
  { id: 'c3', type: 'customer', title: 'Ankit Singh', subtitle: '+91 76543 21098 • 3 orders', path: '/customers?id=c3', icon: <CustomerIcon /> },
];

// ─── Component ──────────────────────────────────────────────

interface GlobalSearchProps {
  onClose?: () => void;
}

export const GlobalSearch: React.FC<GlobalSearchProps> = ({ onClose }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const inputRef = useRef<HTMLInputElement>(null);

  const [query, setQuery] = useState('');
  const [category, setCategory] = useState<SearchCategory>('all');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [recentSearches, setRecentSearches] = useState<string[]>([
    'Rose Bouquet',
    'Order 1234',
    'Rahul',
  ]);
  const [selectedIndex, setSelectedIndex] = useState(0);

  // Focus input on mount
  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  // Search logic (mock)
  useEffect(() => {
    if (!query.trim()) {
      setResults([]);
      return;
    }

    const q = query.toLowerCase();
    let filtered: SearchResult[] = [];

    if (category === 'all' || category === 'products') {
      filtered = [...filtered, ...MOCK_PRODUCTS.filter(
        (p) => p.title.toLowerCase().includes(q) || p.subtitle.toLowerCase().includes(q)
      )];
    }

    if (category === 'all' || category === 'orders') {
      filtered = [...filtered, ...MOCK_ORDERS.filter(
        (o) => o.title.toLowerCase().includes(q) || o.subtitle.toLowerCase().includes(q)
      )];
    }

    if (category === 'all' || category === 'customers') {
      filtered = [...filtered, ...MOCK_CUSTOMERS.filter(
        (c) => c.title.toLowerCase().includes(q) || c.subtitle.toLowerCase().includes(q)
      )];
    }

    setResults(filtered);
    setSelectedIndex(0);
  }, [query, category]);

  // Keyboard navigation
  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        setSelectedIndex((i) => Math.min(i + 1, results.length - 1));
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        setSelectedIndex((i) => Math.max(i - 1, 0));
      } else if (e.key === 'Enter' && results.length > 0) {
        e.preventDefault();
        const result = results[selectedIndex];
        if (result) {
          handleSelect(result);
        }
      } else if (e.key === 'Escape') {
        onClose?.();
      }
    },
    [results, selectedIndex, onClose]
  );

  const handleSelect = (result: SearchResult) => {
    // Add to recent searches
    setRecentSearches((prev) => {
      const filtered = prev.filter((s) => s !== result.title);
      return [result.title, ...filtered].slice(0, 5);
    });

    navigate(result.path);
    onClose?.();
  };

  const handleRecentClick = (search: string) => {
    setQuery(search);
  };

  const clearRecent = () => {
    setRecentSearches([]);
  };

  return (
    <Box
      sx={{
        width: '100%',
        maxWidth: 600,
        bgcolor: dk ? '#1a1a2e' : '#fff',
        borderRadius: 3,
        overflow: 'hidden',
        boxShadow: dk ? '0 24px 48px rgba(0,0,0,0.5)' : '0 16px 40px rgba(0,0,0,0.2)',
        border: dk ? '1px solid rgba(255,255,255,0.1)' : 'none',
      }}
    >
      {/* Search Input */}
      <Box sx={{ p: 2, borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}` }}>
        <TextField
          fullWidth
          placeholder="Search products, orders, customers..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={handleKeyDown}
          inputRef={inputRef}
          autoComplete="off"
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }} />
                </InputAdornment>
              ),
              endAdornment: query && (
                <InputAdornment position="end">
                  <IconButton size="small" onClick={() => setQuery('')}>
                    <CloseIcon fontSize="small" />
                  </IconButton>
                </InputAdornment>
              ),
            },
          }}
          sx={{
            '& .MuiOutlinedInput-root': {
              bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5',
              borderRadius: 2,
              fontSize: '1.1rem',
              '& fieldset': { borderColor: 'transparent' },
              '&:hover fieldset': { borderColor: 'transparent' },
              '&.Mui-focused fieldset': { borderColor: '#fdd835', borderWidth: 2 },
            },
          }}
        />

        {/* Category Chips */}
        <Box sx={{ display: 'flex', gap: 1, mt: 1.5 }}>
          {(['all', 'products', 'orders', 'customers'] as SearchCategory[]).map((cat) => (
            <Chip
              key={cat}
              label={cat.charAt(0).toUpperCase() + cat.slice(1)}
              size="small"
              onClick={() => setCategory(cat)}
              sx={{
                fontWeight: 600,
                bgcolor: category === cat
                  ? alpha('#fdd835', dk ? 0.2 : 0.15)
                  : dk
                  ? 'rgba(255,255,255,0.08)'
                  : 'rgba(0,0,0,0.06)',
                color: category === cat ? '#fdd835' : dk ? 'rgba(255,255,255,0.7)' : 'text.primary',
                '&:hover': {
                  bgcolor: category === cat
                    ? alpha('#fdd835', dk ? 0.3 : 0.2)
                    : dk
                    ? 'rgba(255,255,255,0.12)'
                    : 'rgba(0,0,0,0.1)',
                },
              }}
            />
          ))}
        </Box>
      </Box>

      {/* Results or Recent */}
      <Box sx={{ maxHeight: 400, overflow: 'auto' }}>
        {query.trim() ? (
          // Search Results
          results.length > 0 ? (
            <List sx={{ py: 0 }}>
              {results.map((result, index) => (
                <ListItem key={result.id} disablePadding>
                  <ListItemButton
                    selected={index === selectedIndex}
                    onClick={() => handleSelect(result)}
                    sx={{
                      py: 1.5,
                      px: 2,
                      '&.Mui-selected': {
                        bgcolor: dk ? 'rgba(253,216,53,0.1)' : 'rgba(253,216,53,0.08)',
                      },
                    }}
                  >
                    <ListItemIcon
                      sx={{
                        minWidth: 40,
                        color: result.type === 'product'
                          ? '#4caf50'
                          : result.type === 'order'
                          ? '#2196f3'
                          : '#ff9800',
                      }}
                    >
                      {result.icon}
                    </ListItemIcon>
                    <ListItemText
                      primary={result.title}
                      secondary={result.subtitle}
                      primaryTypographyProps={{ fontWeight: 600 }}
                      secondaryTypographyProps={{ fontSize: '0.8rem' }}
                    />
                    <Chip
                      size="small"
                      label={result.type}
                      sx={{
                        height: 20,
                        fontSize: '0.65rem',
                        fontWeight: 600,
                        textTransform: 'capitalize',
                        bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)',
                      }}
                    />
                  </ListItemButton>
                </ListItem>
              ))}
            </List>
          ) : (
            // No Results
            <Box sx={{ py: 6, textAlign: 'center' }}>
              <SearchIcon sx={{ fontSize: 48, color: dk ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.15)', mb: 2 }} />
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 0.5 }}>
                No Results
              </Typography>
              <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
                Try different search words
              </Typography>
            </Box>
          )
        ) : (
          // Recent Searches & Quick Actions
          <Box sx={{ py: 2 }}>
            {/* Recent Searches */}
            {recentSearches.length > 0 && (
              <>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', px: 2, mb: 1 }}>
                  <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
                    Recent Searches
                  </Typography>
                  <Typography
                    variant="caption"
                    onClick={clearRecent}
                    sx={{
                      cursor: 'pointer',
                      color: '#f44336',
                      fontWeight: 600,
                      '&:hover': { textDecoration: 'underline' },
                    }}
                  >
                    Clear
                  </Typography>
                </Box>
                <List sx={{ py: 0 }}>
                  {recentSearches.map((search) => (
                    <ListItem key={search} disablePadding>
                      <ListItemButton onClick={() => handleRecentClick(search)} sx={{ py: 1, px: 2 }}>
                        <ListItemIcon sx={{ minWidth: 36, color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
                          <HistoryIcon fontSize="small" />
                        </ListItemIcon>
                        <ListItemText primary={search} primaryTypographyProps={{ fontSize: '0.9rem' }} />
                      </ListItemButton>
                    </ListItem>
                  ))}
                </List>
              </>
            )}

            {/* Quick Suggestions */}
            <Box sx={{ px: 2, pt: 2 }}>
              <Typography variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase', color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', display: 'block', mb: 1 }}>
                Popular
              </Typography>
              <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                {['Rose', 'Lily', 'Today\'s Orders', 'Pending Delivery'].map((term) => (
                  <Chip
                    key={term}
                    label={term}
                    size="small"
                    icon={<TrendingIcon sx={{ fontSize: 14 }} />}
                    onClick={() => setQuery(term)}
                    sx={{
                      fontWeight: 500,
                      bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)',
                      '&:hover': {
                        bgcolor: dk ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.1)',
                      },
                    }}
                  />
                ))}
              </Box>
            </Box>
          </Box>
        )}
      </Box>

      {/* Footer Hint */}
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'center',
          gap: 3,
          py: 1.5,
          borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
          bgcolor: dk ? 'rgba(255,255,255,0.02)' : '#fafafa',
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
          <KeyboardIcon sx={{ fontSize: 14, color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }} />
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            <strong>↑↓</strong> Navigate
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            <strong>Enter</strong> Select
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            <strong>Esc</strong> Close
          </Typography>
        </Box>
      </Box>
    </Box>
  );
};

// ─── Search Trigger Button ──────────────────────────────────

interface SearchTriggerProps {
  onClick: () => void;
  variant?: 'full' | 'icon';
}

export const SearchTrigger: React.FC<SearchTriggerProps> = ({ onClick, variant = 'full' }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  if (variant === 'icon') {
    return (
      <IconButton onClick={onClick} sx={{ color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary' }}>
        <SearchIcon />
      </IconButton>
    );
  }

  return (
    <Box
      onClick={onClick}
      sx={{
        display: 'flex',
        alignItems: 'center',
        gap: 1,
        px: 2,
        py: 1,
        borderRadius: 2,
        bgcolor: dk ? 'rgba(255,255,255,0.05)' : '#f5f5f5',
        border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : 'transparent'}`,
        cursor: 'pointer',
        transition: 'all 0.2s',
        minWidth: 200,
        '&:hover': {
          bgcolor: dk ? 'rgba(255,255,255,0.08)' : '#eeeeee',
          borderColor: dk ? 'rgba(255,255,255,0.15)' : '#bdbdbd',
        },
      }}
    >
      <SearchIcon sx={{ fontSize: 20, color: dk ? 'rgba(255,255,255,0.5)' : 'text.disabled' }} />
      <Typography
        variant="body2"
        sx={{
          color: dk ? 'rgba(255,255,255,0.5)' : 'text.disabled',
          flexGrow: 1,
        }}
      >
        Search...
      </Typography>
      <Chip
        size="small"
        label="Ctrl+K"
        sx={{
          height: 20,
          fontSize: '0.65rem',
          fontWeight: 600,
          bgcolor: dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)',
          color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
        }}
      />
    </Box>
  );
};

// ─── Search Dialog Wrapper ──────────────────────────────────

export const GlobalSearchDialog: React.FC = () => {
  const [open, setOpen] = useState(false);

  // Keyboard shortcut
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        setOpen(true);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  return (
    <>
      <SearchTrigger onClick={() => setOpen(true)} />
      <Dialog
        open={open}
        onClose={() => setOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{
          sx: {
            bgcolor: 'transparent',
            boxShadow: 'none',
            overflow: 'visible',
          },
        }}
        sx={{
          '& .MuiBackdrop-root': {
            bgcolor: 'rgba(0,0,0,0.6)',
            backdropFilter: 'blur(4px)',
          },
        }}
      >
        <Fade in={open}>
          <Box sx={{ display: 'flex', justifyContent: 'center' }}>
            <GlobalSearch onClose={() => setOpen(false)} />
          </Box>
        </Fade>
      </Dialog>
    </>
  );
};

export default GlobalSearch;
