export interface Delivery {
  id: string;
  stopOrder: number;
  orderNumber: string;
  customerName: string;
  timeSlot: string;
  postalCode: string;
  status?: 'Pending' | 'Delivered' | 'Failed';
  latitude?: number;
  longitude?: number;
  address?: string;
}

export interface Driver {
  id: string;
  name: string;
}

export interface RouteDetail {
  id: string;
  name: string;
  status: 'Draft' | 'Assigned' | 'InProgress' | 'Completed';
  routeDate?: string;
  deliveryPersonName?: string;
  deliveries: Delivery[];
}