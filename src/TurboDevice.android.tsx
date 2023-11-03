import { NativeModules } from 'react-native';

const { TurboDevice } = NativeModules;

export type TurboDeviceApi = {
  getXXXX: () => Promise<number>;
};

export default TurboDevice as TurboDeviceApi;
