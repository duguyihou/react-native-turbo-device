import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-turbo-device' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const TurboDevice = NativeModules.TurboDevice
  ? NativeModules.TurboDevice
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function getTotalDiskCapacity(): Promise<number> {
  return TurboDevice.getTotalDiskCapacity();
}

export function getFreeDiskStorage(): Promise<number> {
  return TurboDevice.getFreeDiskStorage();
}

export function getTotalMemory(): Promise<number> {
  return TurboDevice.getTotalMemory();
}

export function getUsedMemory(): Promise<number> {
  return TurboDevice.getUsedMemory();
}

export function getBatteryLevel(): Promise<number> {
  return TurboDevice.getBatteryLevel();
}

export function isBatteryCharging(): Promise<boolean> {
  return TurboDevice.isBatteryCharging();
}

export function getPowerState(): Promise<Record<string, any>> {
  return TurboDevice.getPowerState();
}

export function getCarrier(): Promise<string> {
  return TurboDevice.getCarrier();
}

export function getIpAddress(): Promise<string> {
  return TurboDevice.getIpAddress();
}

export function isLocationEnabled(): Promise<boolean> {
  return TurboDevice.isLocationEnabled();
}

export function getAvailableLocationProviders(): Promise<Array<string>> {
  return TurboDevice.getAvailableLocationProviders();
}

export function isHeadphonesConnected(): Promise<boolean> {
  return TurboDevice.isHeadphonesConnected();
}

export function getBrightness(): Promise<number> {
  return TurboDevice.getBrightness();
}

export function getFontScale(): Promise<number> {
  return TurboDevice.getFontScale();
}

export function getUserAgent(): Promise<string> {
  return TurboDevice.getUserAgent();
}

export function getSupportedAbis(): Promise<string> {
  return TurboDevice.getSupportedAbis();
}

export function isPinOrFingerprintSet(): Promise<boolean> {
  return TurboDevice.isPinOrFingerprintSet();
}

export function isEmulator(): Promise<boolean> {
  return TurboDevice.isEmulator();
}

export function getInstallerPackageName(): Promise<number> {
  return TurboDevice.getInstallerPackageName();
}

export function getFirstInstallTime(): Promise<number> {
  return TurboDevice.getFirstInstallTime();
}

export function getDeviceToken(): Promise<string> {
  return TurboDevice.getDeviceToken();
}

export function getUniqueId(): Promise<string> {
  return TurboDevice.getUniqueId();
}

export function syncUniqueId(): Promise<string> {
  return TurboDevice.syncUniqueId();
}

export function getDeviceName(): Promise<string> {
  return TurboDevice.getDeviceName();
}

export function getBuildNumber(): Promise<string> {
  return TurboDevice.getBuildNumber();
}
