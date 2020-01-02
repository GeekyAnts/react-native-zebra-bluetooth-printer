/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React,{useState} from 'react';
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
  Platform,
  Button,
  ActivityIndicator,
  Flatlist
} from 'react-native';

import {
  Header,
  LearnMoreLinks,
  Colors,
  DebugInstructions,
  ReloadInstructions,
} from 'react-native/Libraries/NewAppScreen';

// import RNZebraBluetoothPrinter from 'react-native-zebra-bluetooth-printer';
// import RNZebraBluetoothPrinter from './node_modules/react-native-zebra-bluetooth-printer';
const zpl = "^XA^FX Top section with company logo, name and address.^CF0,60^FO50,50^GB100,100,100^FS^ FO75,75 ^ FR ^ GB100, 100, 100 ^ FS^ FO88, 88 ^ GB50, 50, 50 ^ FS ^XZ";
const App: () => React$Node = () => {
const [devices,setDeviceArray] = useState([]);
const [loading,toggleLoading] = useState(false);
const [deviceType,setDeviceType] = useState('');
  return (
   
      <SafeAreaView>
        <ScrollView
          contentInsetAdjustmentBehavior="automatic"
          style={styles.scrollView}>
            <View style={{
            flexDirection: 'row',
            justifyContent: 'center'
            }}>
              <Text style={{
                fontSize:30,
               
              }}>Demo App</Text>
            </View>
          <View style={styles.body}>
            <Button
              title="enable BT"
              onPress={() => {
                NativeModules.RNZebraBluetoothPrinter.enableBluetooth().then(res => {
                  console.log(res);
                });
              }}
            ></Button>
            <Button
            title="disable BT"
            onPress={()=>{
              NativeModules.RNZebraBluetoothPrinter.disableBluetooth().then(res=>{  
              console.log(res);
              });
            }}
            ></Button>
            </View>
          <View>
            <Button
            title="Paired devices"
              onPress={() => {
                toggleLoading(true);
                NativeModules.RNZebraBluetoothPrinter.pairedDevices().then(res => {
                  setDeviceArray(res); 
                  setDeviceType('paired');                      //filter array for printers [class:1664]
                  toggleLoading(false);
                });
              }}
            ></Button>
            <View style={{padding:10}}></View>
            <Button
            title="Unpaired devices"
              onPress={() => {
                toggleLoading(true);
                  NativeModules.RNZebraBluetoothPrinter.scanDevices().then(res => {
                    console.log(res);
                    if(Platform.OS == 'ios') {
                      var found = JSON.parse(res.found);  //filter array for printers [class:1664]
                    }
                    else {
                      var devices = JSON.parse(res);
                      var found = devices.found;
                    }
                    setDeviceType(''); 
                    setDeviceArray(found); 
                    toggleLoading(false);
                  });
               
              }}
            ></Button>
          </View>
      
       {
         loading == true?<ActivityIndicator />:
         devices.map((device)=>
           
            <View style={{
              flexDirection:'row',
              padding:20,
              justifyContent:'center'
            }}>
                <View style={{
                  flex:0.4
                }}>
                  <Text>{device.name}</Text>
                </View>
                <View style={{
                  flex:0.3
                }}>
                <Text>{device.address}</Text>
                </View>
                {device.type !='paired' &&
                 <View>
                   <Button
                   title="connect"
                   onClick={()=>{
                     NativeModules.RNZebraBluetoothPrinter.connectDevice(device.address).then(res=>alert(res));
                   }}></Button>
                 </View>}
            </View>
         )}
      </ScrollView>
      </SafeAreaView> 
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
    padding:30,
    flexDirection:'row',
    justifyContent:'space-evenly'
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
