/**
 * CategorySidebar.tsx — Vertical icon-only category navigation
 * 80px width, scrollable, with tooltips
 */
import React from 'react';
import {
  GridView as AllIcon,
  LocalFlorist as FlowersIcon,
  Spa as ArrangementsIcon,
  Yard as BouquetsIcon,
  Park as PlantsIcon,
  Grass as GreensIcon,
  Inventory2 as SuppliesIcon,
  Redeem as AddOnsIcon,
  CardGiftcard as GiftsIcon,
} from '@mui/icons-material';
import { Tooltip } from '@mui/material';
import type { POSCategory } from './POSTypes';
import { POS_CATEGORIES } from './POSTypes';

// Icon mapping
const CATEGORY_ICONS: Record<string, React.ElementType> = {
  GridView: AllIcon,
  LocalFlorist: FlowersIcon,
  Spa: ArrangementsIcon,
  Yard: BouquetsIcon,
  Park: PlantsIcon,
  Grass: GreensIcon,
  Inventory2: SuppliesIcon,
  Redeem: AddOnsIcon,
  CardGiftcard: GiftsIcon,
};

interface CategorySidebarProps {
  selectedCategory: string;
  onCategorySelect: (categoryId: string) => void;
  categories?: POSCategory[];
  collapsed?: boolean;
  disableExpand?: boolean;
}

const CategorySidebar: React.FC<CategorySidebarProps> = ({
  selectedCategory,
  onCategorySelect,
  categories = POS_CATEGORIES,
  collapsed = false,
  disableExpand = false,
}) => {
  return (
    <aside className={`bg-white border-r border-gray-200 flex flex-col shrink-0 overflow-hidden ${collapsed ? 'w-16' : 'w-20'}`}>
      <nav className="flex-1 overflow-y-auto py-2">
        <ul className="flex flex-col gap-1">
          {categories.map((category) => {
            const IconComponent = (category.icon && CATEGORY_ICONS[category.icon]) || AllIcon;
            const isSelected = selectedCategory === category.id;
            return (
              <li key={category.id}>
                <Tooltip title={category.name} placement="right" arrow>
                  <button
                    onClick={() => onCategorySelect(category.id)}
                    className={`
                      w-full flex flex-col items-center justify-center py-4 px-2 min-h-[48px]
                      transition-all duration-150 cursor-pointer
                      ${isSelected 
                        ? 'bg-purple-50 text-purple-700 border-r-2 border-purple-600' 
                        : 'text-gray-500 hover:bg-gray-50 hover:text-gray-700 border-r-2 border-transparent'
                      }
                    `}
                    style={collapsed ? { paddingTop: 8, paddingBottom: 8 } : {}}
                  >
                    <IconComponent 
                      className={`w-6 h-6 ${isSelected ? 'text-purple-600' : ''}`}
                    />
                    {!collapsed && (
                      <span 
                        className={`
                          text-[10px] mt-1 leading-tight text-center
                          ${isSelected ? 'font-medium' : 'font-normal'}
                        `}
                      >
                        {category.name}
                      </span>
                    )}
                  </button>
                </Tooltip>
              </li>
            );
          })}
        </ul>
      </nav>
    </aside>
  );
};

export default CategorySidebar;
