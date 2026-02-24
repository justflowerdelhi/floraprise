export interface Delivery {
  id: string;
  stopOrder: number;
  orderNumber: string;
  customerName: string;
  timeSlot: string;
  postalCode: string;
}

export interface Driver {
  id: string;
  name: string;
}

export interface RouteDetail {
  id: string;
  name: string;
  status: 'Draft' | 'Assigned' | 'InProgress' | 'Completed';
  deliveryPersonName?: string;
  deliveries: Delivery[];
}