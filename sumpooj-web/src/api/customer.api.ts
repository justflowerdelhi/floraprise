import api from "./axios";

export const searchCustomers = async (
  query: string,
  page: number,
  pageSize: number
) => {
  const res = await api.get(
    `/customers/search?query=${query}&page=${page}&pageSize=${pageSize}`
  );
  return res.data;
};

export const createCustomer = async (data: {
  name: string;
  email?: string;
  phone?: string;
  defaultCardMessage?: string;
}) => {
  await api.post("/customers", data);
};
