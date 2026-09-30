export interface DeliveryDriver {
  id: string;
  name: string;
  phone: string;
  vehicleType: 'Bike' | 'Van' | 'Scooter' | 'Car';
  vehicleNumber: string;
  status: 'On Duty' | 'In Transit' | 'Available' | 'Offline';
  assignedCompanyId: string;
  assignedCompanyName: string;
  activeOrdersCount: number;
  completedTodayCount: number;
  currentLat?: number;
  currentLng?: number;
  lastPingAt: string;
  batteryPercent: number;
}

export interface DeliverySession {
  id: string;
  orderNumber: string;
  companyId: string;
  companyName: string;
  driverId: string;
  driverName: string;
  recipientName: string;
  recipientPhone: string;
  deliveryAddress: string;
  status: 'Assigned' | 'Picked Up' | 'In Transit' | 'Delivered' | 'Failed';
  startedAt: string;
  estimatedDeliveryAt: string;
  completedAt?: string;
  distanceKm: number;
  currentLat?: number;
  currentLng?: number;
}
