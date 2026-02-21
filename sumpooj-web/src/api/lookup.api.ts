/**
 * lookup.api.ts — Lookup / Reference Data API Service
 *
 * All read-only endpoints that return dropdown / select options.
 */
import api from './axios';

export const getProductTypes = async () => {
  const res = await api.get('/lookup/product-types');
  return res.data;
};

export const getProductCategories = async () => {
  const res = await api.get('/lookup/product-categories');
  return res.data;
};

export const getUnitsOfMeasure = async () => {
  const res = await api.get('/lookup/units-of-measure');
  return res.data;
};

export const getTaxCategories = async () => {
  const res = await api.get('/lookup/tax-categories');
  return res.data;
};

export const getFlowerGrades = async () => {
  const res = await api.get('/lookup/flower-grades');
  return res.data;
};

export const getSeasonalAvailability = async () => {
  const res = await api.get('/lookup/seasonal-availability');
  return res.data;
};

export const getAdjustmentTypes = async () => {
  const res = await api.get('/lookup/adjustment-types');
  return res.data;
};

export const getLocationTypes = async () => {
  const res = await api.get('/lookup/location-types');
  return res.data;
};

export const getPurchaseOrderStatuses = async () => {
  const res = await api.get('/lookup/purchase-order-statuses');
  return res.data;
};

export const getOrderStatuses = async () => {
  const res = await api.get('/lookup/order-statuses');
  return res.data;
};
