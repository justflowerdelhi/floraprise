import { OperationalMode } from './subscriber';

export interface AppRelease {
  id: string;
  appType: 'Android APK' | 'Flutter Web' | 'Solo Windows/Android' | 'Backend Cloud API';
  version: string;
  buildNumber: number;
  releaseDate: string;
  isMandatory: boolean;
  minSupportedVersion: string;
  downloadUrl?: string;
  releaseNotes: string[];
  activeInstallsCount: number;
  healthStatus: 'Stable' | 'Deprecated' | 'Beta';
}
