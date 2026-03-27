/**
 * ProductCard.tsx — Individual product card for POS grid
 * Shows image, name, price, stock badge, expiry indicator
 */
import React, { memo, useEffect, useState } from 'react';
import {
  Add as AddIcon,
  LocalFlorist as FlowersIcon,
  Spa as ArrangementsIcon,
  Yard as BouquetsIcon,
  Park as PlantsIcon,
  Grass as GreensIcon,
  Inventory2 as SuppliesIcon,
  Redeem as AddOnsIcon,
  CardGiftcard as GiftsIcon,
} from '@mui/icons-material';
import type { Product } from './POSTypes';
import { getStockStatus, STOCK_STATUS_CONFIG } from './POSTypes';
import { formatCurrency } from '../../core/i18n';

interface ProductCardProps {
  product: Product;
  onAdd: (product: Product) => void;
}

const getCategoryVisual = (category?: string) => {
  const normalized = (category ?? '').trim().toLowerCase();

  if (normalized === 'fresh flowers') {
    return { Icon: FlowersIcon, bg: 'linear-gradient(135deg, #fef3c7 0%, #fde68a 100%)', fg: '#b45309', label: 'Fresh Flowers' };
  }

  if (normalized === 'bouquets' || normalized === 'bouquets & arrangements') {
    return { Icon: BouquetsIcon, bg: 'linear-gradient(135deg, #fce7f3 0%, #f9a8d4 100%)', fg: '#9d174d', label: 'Bouquets' };
  }

  if (normalized === 'arrangements') {
    return { Icon: ArrangementsIcon, bg: 'linear-gradient(135deg, #ede9fe 0%, #c4b5fd 100%)', fg: '#6d28d9', label: 'Arrangements' };
  }

  if (normalized === 'plants' || normalized === 'plants & succulents') {
    return { Icon: PlantsIcon, bg: 'linear-gradient(135deg, #dcfce7 0%, #86efac 100%)', fg: '#166534', label: 'Plants' };
  }

  if (normalized === 'greens & foliage' || normalized === 'greens & fillers') {
    return { Icon: GreensIcon, bg: 'linear-gradient(135deg, #d1fae5 0%, #6ee7b7 100%)', fg: '#065f46', label: 'Greens' };
  }

  if (normalized === 'gift items') {
    return { Icon: GiftsIcon, bg: 'linear-gradient(135deg, #fee2e2 0%, #fca5a5 100%)', fg: '#991b1b', label: 'Gift Items' };
  }

  if (normalized === 'add-ons') {
    return { Icon: AddOnsIcon, bg: 'linear-gradient(135deg, #ffedd5 0%, #fdba74 100%)', fg: '#9a3412', label: 'Add-Ons' };
  }

  if (normalized === 'supplies' || normalized === 'vases & containers') {
    return { Icon: SuppliesIcon, bg: 'linear-gradient(135deg, #e5e7eb 0%, #cbd5e1 100%)', fg: '#334155', label: 'Supplies' };
  }

  return { Icon: SuppliesIcon, bg: 'linear-gradient(135deg, #e0f2fe 0%, #bae6fd 100%)', fg: '#0f766e', label: category || 'Product' };
};

const ProductCard: React.FC<ProductCardProps> = memo(({ product, onAdd }) => {
  const stockStatus = getStockStatus(product.availableStock);
  const stockConfig = STOCK_STATUS_CONFIG[stockStatus];
  const isDisabled = stockStatus === 'out-of-stock';
  const [imageFailed, setImageFailed] = useState(false);
  const categoryVisual = getCategoryVisual(product.category);

  useEffect(() => {
    setImageFailed(false);
  }, [product.id, product.imageUrl]);

  const handleClick = () => {
    if (!isDisabled) {
      onAdd(product);
    }
  };

  return (
    <div
      onClick={handleClick}
      style={{
        minHeight: window.innerWidth < 640 ? 96 : 112,
        borderRadius: 12,
        transition: 'all 0.15s ease',
        boxShadow: 'none',
        background: '#fff',
        cursor: isDisabled ? 'not-allowed' : 'pointer',
        opacity: isDisabled ? 0.5 : 1,
        border: '1px solid #e5e7eb',
        overflow: 'hidden',
        position: 'relative',
        transform: 'none',
      }}
      className={`group product-card self-start${isDisabled ? ' disabled' : ''}`}
      onMouseEnter={e => {
        if (!isDisabled) {
          (e.currentTarget as HTMLDivElement).style.transform = 'scale(1.02)';
          (e.currentTarget as HTMLDivElement).style.boxShadow = '0 6px 18px rgba(0,0,0,0.08)';
        }
      }}
      onMouseLeave={e => {
        (e.currentTarget as HTMLDivElement).style.transform = 'none';
        (e.currentTarget as HTMLDivElement).style.boxShadow = 'none';
      }}
    >
      {/* Product Image */}
      <div className="h-14 sm:h-16 md:h-18 bg-gray-100 relative overflow-hidden">
        {product.imageUrl && !imageFailed ? (
          <img
            src={product.imageUrl}
            alt={product.name}
            className="w-full h-full object-cover"
            onError={() => setImageFailed(true)}
          />
        ) : (
          <div
            className="w-full h-full flex flex-col items-center justify-center px-4 text-center"
            style={{ background: categoryVisual.bg, color: categoryVisual.fg }}
          >
            <div
              className="flex flex-col items-center justify-center rounded-xl px-2 py-1"
              style={{ backgroundColor: 'rgba(255,255,255,0.35)' }}
            >
              <categoryVisual.Icon sx={{ fontSize: { xs: 16, sm: 18 }, mb: 0.25 }} />
              <span className="text-[8px] sm:text-[9px] font-semibold leading-tight">
                {categoryVisual.label}
              </span>
            </div>
          </div>
        )}

        {/* Out-of-stock Chip (small, clean) */}
        {isDisabled && (
          <span
            className="absolute top-2 right-2 px-2 py-0.5 text-[10px] font-semibold rounded-full bg-gray-200 text-gray-600 shadow"
            style={{ fontWeight: 500, fontSize: 11 }}
          >
            Out of stock
          </span>
        )}

        {/* Add Button Overlay */}
        {!isDisabled && (
          <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors flex items-center justify-center opacity-0 group-hover:opacity-100">
            <span className="w-10 h-10 bg-purple-600 text-white rounded-full flex items-center justify-center shadow-lg transform scale-90 group-hover:scale-100 transition-transform">
              <AddIcon className="w-6 h-6" />
            </span>
          </div>
        )}
      </div>

      {/* Product Info */}
      <div className="p-1.5">
        <h3
          className="text-[10px] sm:text-[11px] font-semibold text-gray-900 truncate"
          style={{ fontWeight: 600 }}
          title={product.name}
        >
          {product.name}
        </h3>
        <div className="mt-0.5 flex items-center justify-between gap-1">
          <span
            className="text-[11px] sm:text-xs text-purple-700 font-bold"
          >
            {formatCurrency(product.sellingPrice)}
          </span>
          <span className="text-[10px] sm:text-xs text-gray-400 truncate">
            {product.sku}
          </span>
        </div>
      </div>
    </div>
  );
});

ProductCard.displayName = 'ProductCard';

export default ProductCard;
