/**
 * Real Device & License Service
 * Connects to:
 * - GET  /api/platform/mobile-admin/devices
 * - GET  /api/platform/mobile-admin/licenses
 * - POST /api/platform/mobile-admin/devices/{mobileDeviceId}/force-logout
 * - POST /api/platform/mobile-admin/devices/{mobileDeviceId}/disable
 * - POST /api/platform/mobile-admin/devices/{mobileDeviceId}/reset
 * - POST /api/platform/mobile-admin/licenses/{licenseId}/suspend
 * - POST /api/platform/mobile-admin/licenses/{licenseId}/resume
 * - POST /api/platform/mobile-admin/licenses/{licenseId}/extend
 */

import { apiClient } from './apiClient';
import { SubscriberDevice } from '../../types/subscriber';
import { AppRelease } from '../../types/device';

export interface MobileAdminDeviceListItemDto {
  mobileDeviceId: string;
  companyId: string;
  mobileUserId: string;
  deviceName: string;
  deviceId: string;
  businessName?: string;
  platform: string;
  osVersion?: string;
  appVersion: string;
  online: boolean;
  lastSeenAtUtc?: string;
  registeredAtUtc: string;
  subscriptionType: string;
  deviceStatus: string;
}

export interface MobileAdminLicenseListItemDto {
  mobileLicenseId: string;
  companyId: string;
  mobileUserId: string;
  licenseNumber: string;
  businessName?: string;
  plan?: string;
  status: string;
  issueDateUtc: string;
  expiryDateUtc?: string;
  remainingDays: number;
}

const PRODUCTION_APP_RELEASES: AppRelease[] = [
  {
    id: 'rel-android-241',
    appType: 'Android APK',
    version: '2.4.1',
    buildNumber: 142,
    releaseDate: '2026-09-25',
    isMandatory: true,
    minSupportedVersion: '2.4.0',
    downloadUrl: 'https://download.floraprise.com/apps/android/floraprise-v2.4.1.apk',
    releaseNotes: [
      'Customer bulk import with preview & deduplication',
      'PDF Bill & Delivery Slip builder integration',
      'Selectable customer text in dashboard',
      'Cloud production stability enhancements'
    ],
    activeInstallsCount: 0,
    healthStatus: 'Stable'
  },
  {
    id: 'rel-web-241',
    appType: 'Flutter Web',
    version: '2.4.1-web',
    buildNumber: 142,
    releaseDate: '2026-09-25',
    isMandatory: true,
    minSupportedVersion: '2.4.0-web',
    downloadUrl: 'https://app.floraprise.com',
    releaseNotes: [
      'Web-optimized PDF preview & direct print',
      'Selectable phone and name text',
      'Enhanced day close ledger diagnostics'
    ],
    activeInstallsCount: 0,
    healthStatus: 'Stable'
  },
  {
    id: 'rel-solo-240',
    appType: 'Solo Windows/Android',
    version: '2.4.0-solo',
    buildNumber: 139,
    releaseDate: '2026-09-12',
    isMandatory: false,
    minSupportedVersion: '2.3.8-solo',
    downloadUrl: 'https://download.floraprise.com/apps/solo/floraprise-solo-2.4.0.exe',
    releaseNotes: [
      'Local SQLite backup encryption',
      'Offline customer import engine',
      'Direct thermal receipt printing driver'
    ],
    activeInstallsCount: 0,
    healthStatus: 'Stable'
  },
  {
    id: 'rel-api-241',
    appType: 'Backend Cloud API',
    version: '2.4.1-api',
    buildNumber: 420,
    releaseDate: '2026-09-27',
    isMandatory: true,
    minSupportedVersion: '2.4.0-api',
    releaseNotes: [
      'Automatic default location self-healing',
      'Mobile company logo upload multipart route',
      'Delivery live coordinate tracking high-throughput pipeline'
    ],
    activeInstallsCount: 1,
    healthStatus: 'Stable'
  }
];

class RealDeviceService {
  async getAllDevices(): Promise<SubscriberDevice[]> {
    const res = await apiClient.get<{ items: MobileAdminDeviceListItemDto[] }>('/api/platform/mobile-admin/devices', {
      page: 1,
      pageSize: 100
    });

    if (res.isSuccess && res.data?.items && res.data.items.length > 0) {
      return res.data.items.map(d => ({
        id: d.mobileDeviceId,
        companyId: d.companyId,
        deviceName: d.deviceName || d.deviceId,
        deviceModel: d.osVersion || d.platform,
        platform: d.platform.toLowerCase().includes('android') ? 'Android' : d.platform.toLowerCase().includes('win') ? 'Windows' : 'Web',
        operationalMode: d.platform.toLowerCase().includes('android') ? 'Flutter Cloud Android' : 'Flutter Web',
        appVersion: d.appVersion || '2.4.1',
        lastSeenAt: d.lastSeenAtUtc ? new Date(d.lastSeenAtUtc).toLocaleTimeString() : 'Offline',
        ipAddress: '—',
        status: d.online ? 'Online' : 'Offline',
        licenseKey: d.mobileUserId ? `LIC-${d.companyId.substring(0, 8).toUpperCase()}` : '—'
      }));
    }

    return [];
  }

  async getAppReleases(): Promise<AppRelease[]> {
    const devices = await this.getAllDevices().catch(() => [] as SubscriberDevice[]);
    const androidCount = devices.filter(d => d.platform === 'Android').length;
    const webCount = devices.filter(d => d.platform === 'Web').length;
    const soloCount = devices.filter(d => d.platform === 'Windows').length;

    return PRODUCTION_APP_RELEASES.map(rel => {
      let activeCount = rel.activeInstallsCount;
      if (rel.appType.includes('Android')) activeCount = androidCount;
      else if (rel.appType.includes('Web')) activeCount = webCount;
      else if (rel.appType.includes('Solo')) activeCount = soloCount;

      return {
        ...rel,
        activeInstallsCount: activeCount
      };
    });
  }

  async forceLogoutDevice(deviceId: string, companyId?: string): Promise<{ success: boolean; message: string }> {
    const res = await apiClient.post<any>(`/api/platform/mobile-admin/devices/${deviceId}/force-logout`, {
      companyId: companyId || '',
      reason: 'Central Admin Force Logout'
    });

    if (res.isSuccess) {
      return { 
        success: true, 
        message: res.data?.message || 'Device session terminated successfully.' 
      };
    }

    return {
      success: false,
      message: res.error || 'Failed to terminate device session.'
    };
  }

  async disableDevice(deviceId: string, companyId?: string, reason?: string): Promise<{ success: boolean; message: string }> {
    const res = await apiClient.post<any>(`/api/platform/mobile-admin/devices/${deviceId}/disable`, {
      companyId: companyId || '',
      reason: reason || 'Central Admin Administrative Disablement'
    });

    if (res.isSuccess) {
      return { 
        success: true, 
        message: res.data?.message || 'Device disabled successfully.' 
      };
    }

    return {
      success: false,
      message: res.error || 'Failed to disable device.'
    };
  }

  async resetDevice(deviceId: string, companyId?: string): Promise<{ success: boolean; message: string }> {
    const res = await apiClient.post<any>(`/api/platform/mobile-admin/devices/${deviceId}/reset`, {
      companyId: companyId || '',
      reason: 'Central Admin Pairing Reset'
    });

    if (res.isSuccess) {
      return { 
        success: true, 
        message: res.data?.message || 'Device pairing reset successfully.' 
      };
    }

    return {
      success: false,
      message: res.error || 'Failed to reset device pairing.'
    };
  }

  async suspendLicense(licenseId: string, companyId?: string, reason?: string): Promise<{ success: boolean; message: string }> {
    const res = await apiClient.post<any>(`/api/platform/mobile-admin/licenses/${licenseId}/suspend`, {
      companyId: companyId || '',
      reason: reason || 'Central Admin Administrative Suspension'
    });

    if (res.isSuccess) {
      return { 
        success: true, 
        message: res.data?.message || 'License suspended successfully.' 
      };
    }

    return {
      success: false,
      message: res.error || 'Failed to suspend license.'
    };
  }

  async resumeLicense(licenseId: string, companyId?: string, notes?: string): Promise<{ success: boolean; message: string }> {
    const res = await apiClient.post<any>(`/api/platform/mobile-admin/licenses/${licenseId}/resume`, {
      companyId: companyId || '',
      notes: notes || 'Central Admin License Resumed'
    });

    if (res.isSuccess) {
      return { 
        success: true, 
        message: res.data?.message || 'License resumed successfully.' 
      };
    }

    return {
      success: false,
      message: res.error || 'Failed to resume license.'
    };
  }

  async extendLicense(licenseId: string, companyId?: string, extendByDays: number = 30, notes?: string): Promise<{ success: boolean; message: string; expiryUtc?: string }> {
    const res = await apiClient.post<any>(`/api/platform/mobile-admin/licenses/${licenseId}/extend`, {
      companyId: companyId || '',
      extendByDays,
      notes: notes || `Central Admin License Extension +${extendByDays} days`
    });

    if (res.isSuccess) {
      return { 
        success: true, 
        message: res.data?.message || `License extended by ${extendByDays} days.`,
        expiryUtc: res.data?.expiryUtc
      };
    }

    return {
      success: false,
      message: res.error || 'Failed to extend license.'
    };
  }
}

export const realDeviceService = new RealDeviceService();
