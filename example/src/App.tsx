import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import TurboDevice from '../../src/TurboDevice';

export default function App() {
  const [totalDiskCapacity, setTotalDiskCapacity] = React.useState<
    number | undefined
  >();

  React.useEffect(() => {
    const a = async () => {
      const total = await TurboDevice.getTotalDiskCapacity();
      setTotalDiskCapacity(total);
    };
    a();
  }, []);

  return (
    <View style={styles.container}>
      <Text>TotalDiskCapacity: {totalDiskCapacity}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
