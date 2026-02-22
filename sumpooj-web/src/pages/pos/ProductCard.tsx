/**
 * ProductCard.tsx — Individual product card for POS grid
 * Shows image, name, price, stock badge, expiry indicator
 */
import React, { memo } from 'react';
import { Add as AddIcon, AccessTime as ExpiryIcon } from '@mui/icons-material';
import type { Product } from './POSTypes';
import { getStockStatus, STOCK_STATUS_CONFIG } from './POSTypes';

interface ProductCardProps {
  product: Product;
  onAdd: (product: Product) => void;
}

const ProductCard: React.FC<ProductCardProps> = memo(({ product, onAdd }) => {
  const stockStatus = getStockStatus(product.availableStock);
  const stockConfig = STOCK_STATUS_CONFIG[stockStatus];
  const isDisabled = stockStatus === 'out-of-stock';

  // Check for upcoming expiry (within 3 days)
  const hasExpiryWarning = product.isPerishable && product.batches?.some(batch => {
    const expiryDate = new Date(batch.expiryDate);
    const today = new Date();
    const diffDays = Math.ceil((expiryDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
    return diffDays <= 3 && diffDays >= 0;
  });

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
    }).format(amount);
  };

  const handleClick = () => {
    if (!isDisabled) {
      onAdd(product);
    }
  };

  return (
    <div
      onClick={handleClick}
      className={`
        group relative bg-white border border-gray-200 rounded-xl overflow-hidden
        transition-all duration-200 ease-out cursor-pointer
        ${isDisabled 
          ? 'opacity-50 cursor-not-allowed' 
          : 'hover:shadow-lg hover:shadow-purple-100/50 hover:border-purple-300 hover:-translate-y-1 hover:scale-[1.02] active:scale-[0.98] active:shadow-sm'
        }
      `}
    >
      {/* Product Image */}
      <div className="aspect-square bg-gray-100 relative overflow-hidden">
        {product.imageUrl ? (
          <img
            src={product.imageUrl}
            alt={product.name}
            className="w-full h-full object-cover"
            loading="lazy"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-gray-300">
            <svg className="w-12 h-12" fill="currentColor" viewBox="0 0 24 24">
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" />
            </svg>
          </div>
        )}

        {/* Stock Badge */}
        <span
          className="absolute top-2 right-2 px-2 py-0.5 text-[10px] font-semibold rounded"
          style={{ 
            color: stockConfig.color, 
            backgroundColor: stockConfig.bgColor 
          }}
        >
          {product.availableStock > 0 ? product.availableStock : 'Out'}
        </span>

        {/* Expiry Warning */}
        {hasExpiryWarning && (
          <span className="absolute top-2 left-2 p-1 bg-amber-100 rounded text-amber-600">
            <ExpiryIcon className="w-4 h-4" />
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
      <div className="p-3">
        <h3 className="text-sm font-medium text-gray-900 line-clamp-2 min-h-[2.5rem]">
          {product.name}
        </h3>
        <div className="mt-2 flex items-center justify-between">
          <span className="text-base font-bold text-purple-700">
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
