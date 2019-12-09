/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React from 'react';
import {
  SafeAreaView,
  StyleSheet,
  ScrollView,
  View,
  Text,
  StatusBar,
  TouchableOpacity,
  NativeModules,
  Alert,
  Platform
} from 'react-native';

import {
  Header,
  LearnMoreLinks,
  Colors,
  DebugInstructions,
  ReloadInstructions,
} from 'react-native/Libraries/NewAppScreen';
import DeviceInfo from 'react-native-device-info';
import RNZebraBluetoothPrinter from 'react-native-zebra-bluetooth-printer';
// import RNZebraBluetoothPrinter from './node_modules/react-native-zebra-bluetooth-printer';
const zpl = "^XA^FX Top section with company logo, name and address.^CF0,60^FO50,50^GB100,100,100^FS^ FO75,75 ^ FR ^ GB100, 100, 100 ^ FS^ FO88, 88 ^ GB50, 50, 50 ^ FS ^XZ";
const App: () => React$Node = () => {
  console.log(NativeModules,RNZebraBluetoothPrinter);
  // NativeModules.RNZebraBluetoothPrinter.isEnabledBluetooth().then(res=>{
  //   console.log(res);
  // });
  return (
    <>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView>
        <ScrollView
          contentInsetAdjustmentBehavior="automatic"
          style={styles.scrollView}>
          <Header />
          {global.HermesInternal == null ? null : (
            <View style={styles.engine}>
              <Text style={styles.footer}>Engine: Hermes</Text>
            </View>
          )}
          <View style={styles.body}>
            <TouchableOpacity 
            onPress={()=>{
              NativeModules.RNZebraBluetoothPrinter.disableBluetooth().then(res=>{  
              console.log(res);
              });
            }}
            ><Text>
              Press to Disable
              </Text></TouchableOpacity>
            <TouchableOpacity
              onPress={() => {
                NativeModules.RNZebraBluetoothPrinter.pairedDevices().then(res => {
                console.log(res);
                });
              }}
            ><Text>
                Get paired Devices
              </Text></TouchableOpacity>
            <TouchableOpacity
              onPress={() => {
                NativeModules.RNZebraBluetoothPrinter.scanDevices().then(res => {
                 console.log(res);
                });
              }}
            ><Text>
                Get unpaired Devices
              </Text></TouchableOpacity>
            <TouchableOpacity
              onPress={() => {
                NativeModules.RNZebraBluetoothPrinter.connectDevice("0C347F9F-2881-9CCB-43B0-205976944626").then(res => {
                  Alert.alert(res);
                });
              }}
            ><Text>
               connect to printer
              </Text></TouchableOpacity>
            <TouchableOpacity
              onPress={() => {
                NativeModules.RNZebraBluetoothPrinter.unpairDevice("38:F9:D3:AB:72:3E").then(res => {
                  Alert.alert(res);
                });
              }}
            ><Text>
                disconnect to device
              </Text></TouchableOpacity>
            <TouchableOpacity
              onPress={() => {
                if(Platform.OS == 'ios') {
                  NativeModules.RNZebraBluetoothPrinter.print(zpl).then(res => {
                    console.log(res);
                  });
                }
                else {
                  NativeModules.RNZebraBluetoothPrinter.print("AC:3F:A4:AF:36:17", zpl).then(res => {

                    console.log(res);
                  });
                }
              
              }}
            ><Text>
               Print Zpl
              </Text></TouchableOpacity>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Step One</Text>
              <Text style={styles.sectionDescription}>
                Edit <Text style={styles.highlight}>App.js</Text> to change this
                screen and then come back to see your edits.
              </Text>
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>See Your Changes</Text>
              <Text style={styles.sectionDescription}>
                <ReloadInstructions />
              </Text>
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Debug</Text>
              <Text style={styles.sectionDescription}>
                <DebugInstructions />
              </Text>
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Learn More</Text>
              <Text style={styles.sectionDescription}>
                Read the docs to discover what to do next:
              </Text>
            </View>
            <LearnMoreLinks />
          </View>
        </ScrollView>
      </SafeAreaView>
    </>
  );
};

const styles = StyleSheet.create({
  scrollView: {
    backgroundColor: Colors.lighter,
  },
  engine: {
    position: 'absolute',
    right: 0,
  },
  body: {
    backgroundColor: Colors.white,
  },
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
    color: Colors.black,
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
    color: Colors.dark,
  },
  highlight: {
    fontWeight: '700',
  },
  footer: {
    color: Colors.dark,
    fontSize: 12,
    fontWeight: '600',
    padding: 4,
    paddingRight: 12,
    textAlign: 'right',
  },
});

export default App;
