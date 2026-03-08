import api from "./axios";

export interface FinishedGoodsSearchParams {
  Query?: string;
  Page?: number;
  PageSize?: number;
}

export const searchFinishedGoods = async (
  params: FinishedGoodsSearchParams = {}
) => {

  const res = await api.get("/finished-goods/search", {
    params
  });

  return res.data;
};
