import React from 'react';
import { AccountBalanceWallet, AccountTree, AttachMoney, TrendingUp, Receipt, Store, LocalShipping, People, Home, FlashOn } from '@mui/icons-material';
import { People as StaffIcon, Home as RentIcon, FlashOn as UtilitiesIcon, LocalShipping as DeliveryIcon, Store as COGSIcon, HelpOutline as OtherIcon } from '@mui/icons-material';

export const accountTypes = [
  'Asset',
  'Liability',
  'Income',
  'Expense',
  'Equity',
];

export const AccountTypeIcons: Record<string, React.ReactNode> = {
  Asset: <AccountBalanceWallet fontSize="small" />, // Cash/Bank
  Liability: <AccountTree fontSize="small" />, // Payable
  Income: <TrendingUp fontSize="small" />, // Revenue
  Expense: <Receipt fontSize="small" />, // Expense
  Equity: <Store fontSize="small" />, // Equity
};

export const expenseCategories = [
  'Staff',
  'Rent',
  'Utilities',
  'COGS',
  'Delivery',
  'Other',
];

export const categoryIcons: Record<string, React.ReactNode> = {
  Staff: <StaffIcon fontSize="small" />,
  Rent: <RentIcon fontSize="small" />,
  Utilities: <UtilitiesIcon fontSize="small" />,
  COGS: <COGSIcon fontSize="small" />,
  Delivery: <DeliveryIcon fontSize="small" />,
  Other: <OtherIcon fontSize="small" />,
};

export const paymentMethods = ['Cash', 'Bank', 'Card', 'UPI'];
export const locations = ['Main', 'Branch1', 'Branch2'];
