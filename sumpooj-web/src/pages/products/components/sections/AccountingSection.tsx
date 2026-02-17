/**
 * Accounting Section
 * Income and expense account assignments
 */

import { Grid, Alert, Typography } from '@mui/material';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import SectionCard from '../SectionCard';
import { FormSelect } from '../FormFields';
import { FormSectionProps, INCOME_ACCOUNTS, EXPENSE_ACCOUNTS } from '../../types/product.types';

const AccountingSection = ({
  control,
  errors,
  watch,
  setValue,
  darkMode = false,
}: FormSectionProps) => {
  return (
    <SectionCard
      title="Accounting"
      subtitle="Financial account assignments"
      icon={AccountBalanceIcon}
      darkMode={darkMode}
      accentColor="#9c27b0"
    >
      <Grid container spacing={2.5}>
        {/* Info Alert */}
        <Grid size={{ xs: 12 }}>
          <Alert severity="info" sx={{ mb: 1 }}>
            <Typography variant="body2">
              These accounts determine how sales and costs are recorded in your financial reports.
            </Typography>
          </Alert>
        </Grid>

        {/* Income Account */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormSelect
            name="incomeAccount"
            control={control}
            label="Income Account"
            options={INCOME_ACCOUNTS}
            required
            tooltip="Account where sales revenue will be recorded"
            darkMode={darkMode}
          />
        </Grid>

        {/* Expense Account */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormSelect
            name="expenseAccount"
            control={control}
            label="Expense Account"
            options={EXPENSE_ACCOUNTS}
            required
            tooltip="Account where cost of goods will be recorded"
            darkMode={darkMode}
          />
        </Grid>
      </Grid>
    </SectionCard>
  );
};

export default AccountingSection;
