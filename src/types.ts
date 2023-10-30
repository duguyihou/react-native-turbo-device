export type TurboDeviceApi = {
  getTotalDiskCapacity(): () => Promise<number>;

  getFreeDiskStorage(): () => Promise<number>;

  getTotalMemory(): () => Promise<number>;

  getUsedMemory(): () => Promise<number>;

  getBatteryLevel(): () => Promise<number>;

  isBatteryCharging(): () => Promise<boolean>;

  getPowerState(): () => Promise<Record<string, any>>;

  getCarrier(): () => Promise<string>;

  getIpAddress(): () => Promise<string>;

  isLocationEnabled(): () => Promise<boolean>;

  getAvailableLocationProviders(): () => Promise<Array<string>>;

  isHeadphonesConnected(): () => Promise<boolean>;

  getBrightness(): () => Promise<number>;

  getFontScale(): () => Promise<number>;

  getUserAgent(): () => Promise<string>;

  getSupportedAbis(): () => Promise<string>;

  isPinOrFingerprintSet(): () => Promise<boolean>;

  isEmulator(): () => Promise<boolean>;

  getInstallerPackageName(): () => Promise<number>;

  getFirstInstallTime(): () => Promise<number>;

  getDeviceToken(): () => Promise<string>;

  getUniqueId(): () => Promise<string>;

  syncUniqueId(): () => Promise<string>;

  getDeviceName(): () => Promise<string>;

  getBuildNumber(): () => Promise<string>;
};
