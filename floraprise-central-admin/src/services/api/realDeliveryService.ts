/**
 * Real Delivery Service for Central Admin
 * 
 * Delivery Fleet Telemetry, Route Optimization, and Driver Dispatches are
 * tenant-scoped and managed inside the ERP Delivery Control Center (/delivery-routes).
 * 
 * Central Admin provides the high-level operational launchpad and subsystem status
 * without fabricating mock telemetry or mock driver locations.
 */

import { DeliveryDriver, DeliverySession } from '../../types/delivery';

export interface DeliverySubsystemStatus {
  isOperational: boolean;
  mode: 'Tenant-Scoped';
  controlCenterUrl: string;
  activeFleetCount: number;
  inTransitCount: number;
  completedTodayCount: number;
  notes: string;
}

class RealDeliveryService {
  async getSummary(): Promise<DeliverySubsystemStatus> {
    return {
      isOperational: true,
      mode: 'Tenant-Scoped',
      controlCenterUrl: 'https://erp.floraprise.com/delivery-routes',
      activeFleetCount: 0,
      inTransitCount: 0,
      completedTodayCount: 0,
      notes: 'Real-time driver dispatching, GPS route telemetry, and proof-of-delivery sessions are managed on a per-tenant basis in the Delivery Control Center.'
    };
  }

  async getDrivers(): Promise<DeliveryDriver[]> {
    // Return empty array rather than fabricated mock drivers
    return [];
  }

  async getSessions(_filter?: string): Promise<DeliverySession[]> {
    // Return empty array rather than fabricated mock sessions
    return [];
  }
}

export const realDeliveryService = new RealDeliveryService();
