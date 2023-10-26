import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import { getTotalDiskCapacity, multiply } from 'react-native-turbo-device';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();
  const [totalDiskCapacity, setTotalDiskCapacity] = React.useState<
    number | undefined
  >();
  React.useEffect(() => {
    multiply(3, 7).then(setResult);
  }, []);

  React.useEffect(() => {
    const a = async () => {
      const total = await getTotalDiskCapacity();
      setTotalDiskCapacity(total);
    };
    a();
  }, []);

  return (
    <View style={styles.container}>
      <Text>Result: {result}</Text>
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
