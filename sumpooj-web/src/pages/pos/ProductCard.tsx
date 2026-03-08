/**
 * ProductCard.tsx — Individual product card for POS grid
 * Shows image, name, price, stock badge, expiry indicator
 */
import React, { memo } from 'react';
import { Add as AddIcon, AccessTime as ExpiryIcon } from '@mui/icons-material';
import type { Product } from './POSTypes';
import { getStockStatus, STOCK_STATUS_CONFIG } from './POSTypes';
import { formatCurrency } from '../../core/i18n';

interface ProductCardProps {
  product: Product;
  onAdd: (product: Product) => void;
}

const ProductCard: React.FC<ProductCardProps> = memo(({ product, onAdd }) => {
  const stockStatus = getStockStatus(product.availableStock);
  const stockConfig = STOCK_STATUS_CONFIG[stockStatus];
  const isDisabled = stockStatus === 'out-of-stock';

  const handleClick = () => {
    if (!isDisabled) {
      onAdd(product);
    }
  };

  return (
    <div
      onClick={handleClick}
      style={{
        minHeight: window.innerWidth < 640 ? 170 : 220,
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
      className={`group product-card${isDisabled ? ' disabled' : ''}`}
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
      <div className="aspect-square bg-gray-100 relative overflow-hidden">
        {product.imageUrl ? (
          <img
            src={product.imageUrl}
            alt={product.name}
            className="w-full h-full object-cover"
          />
        ) : (
          <img
            src="/images/product-placeholder.png"
            alt="product"
            className="w-full h-full object-cover opacity-80"
          />
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

        // ...existing code...

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
      <div className="p-2 sm:p-3">
        <h3
          className="text-sm sm:text-base font-semibold text-gray-900 line-clamp-2"
          style={{ fontWeight: 600 }}
        >
          {product.name}
        </h3>
        <div className="mt-2 flex items-center justify-between">
          <span
            className="text-base sm:text-lg text-purple-700 font-bold"
          >
            {formatCurrency(product.sellingPrice)}
          </span>
          <span className="text-xs text-gray-400">
            {product.sku}
          </span>
        </div>
      </div>
    </div>
  );
});

ProductCard.displayName = 'ProductCard';

export default ProductCard;
