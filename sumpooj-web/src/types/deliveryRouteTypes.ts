export interface Delivery {
  id: string;
  stopOrder: number;
  orderNumber: string;
  customerName: string;
  timeSlot: string;
  postalCode: string;
  status?: 'Pending' | 'Delivered' | 'Failed';
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