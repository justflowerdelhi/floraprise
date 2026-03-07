export function canViewAccounting(role: string) {
  return (
    role === "ADMIN" ||
    role === "OWNER" ||
    role === "ACCOUNTANT"
  );
}
