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

export function multiply(a: number, b: number): Promise<number> {
  return TurboDevice.multiply(a, b);
}

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
