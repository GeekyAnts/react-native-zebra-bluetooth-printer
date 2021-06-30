
# react-native-zebra-bluetooth-printer

## Getting started

`$ npm install react-native-zebra-bluetooth-printer --save`



### Mostly automatic installation

`$ react-native link react-native-zebra-bluetooth-printer`

Note : For react-native > 0.59, don't use above command it uses auto-linking.

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-zebra-bluetooth-printer` and add `RNZebraBluetoothPrinter.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNZebraBluetoothPrinter.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNZebraBluetoothPrinterPackage;` to the imports at the top of the file
  - Add `new RNZebraBluetoothPrinterPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-zebra-bluetooth-printer'
  	project(':react-native-zebra-bluetooth-printer').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-zebra-bluetooth-printer/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-zebra-bluetooth-printer')
  	```

### Update Android Manifest
```
 <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```
## Usage

# RNZebraBluetoothPrinter

RNZebraBluetoothPrinter is a module for Bluetooth management and supports print functionality for zebra bluetooth printers ( only ble devices ). 
It includes features like bluetooth enable/disable, pair/unpair a BLE/Bluetooth device, scan for nearby bluetooth devices and printing using bluetooth.
```javascript
import RNZebraBluetoothPrinter from 'react-native-zebra-bluetooth-printer';

```
1. isEnabledBluetooth == > async function, check the status of bluetooth service in the bluetooth client(mobile phone) .Returns true if already enabled, false if not enabled.
```javascript
RNZebraBluetoothPrinter.isEnabledBluetooth().then((res) => {
	//do something with res
})
```
2. enableBluetooth == > async function,
	 Android: requests for bluetooth on/off permission on the android device.
	 iOS: resolves to nil.

```javascript
RNZebraBluetoothPrinter.enableBluetooth().then((res) => {
	//do something with res
})
```

3. disableBluetooth == > async function,
	Android: disables bluetooth if bluetooth is switched on.
	iOS: simply resolves by nil.	
```javascript
RNZebraBluetoothPrinter.disableBluetooth().then((res) => {
	//do something with res
})
```	
4. scanDevices == > async function, scans for available nearby bluetooth devices for a specific period of time.
```javascript
RNZebraBluetoothPrinter.scanDevices().then((deviceArray) => {
	//do something with res
})
```	
5. pairedDevices == > async function, 	
	Android: returns already paired devices.
	iOS: resolves to nil.
```javascript
RNZebraBluetoothPrinter.pairedDevices().then((deviceArray) => {
	//do something with deviceArray
})
```	
6. connectDevice == > async function, for both android and iOS
```javascript
RNZebraBluetoothPrinter.connectDevice(deviceAddress).then((res) => {
	//do something with res
	//for android, device address is mac address
	//for iOS, device address is a long string like 0C347F9F-2881-9CCB-43B0-205976944626
})
```	
7. unpairDevice == > async function,
	Android: unpair/disconnect a paired device from paired device list.
```javascript
RNZebraBluetoothPrinter.unpairDevice(deviceAddress).then((res) => {
	//do something with res
})
```
	iOS: function resolves to nil.		
8. print == > async function, prints specific zpl string from a zebra printer for both android and iOS.	CPCL strings can also be printed using this for Android.

For example :
```javascript
const zpl = "^XA^FX Top section with company logo, name and address.^CF0,60^FO50,50^GB100,100,100^FS^ FO75,75 ^ FR ^ GB100, 100, 100 ^ FS^ FO88, 88 ^ GB50, 50, 50 ^ FS ^XZ";

```
Android
```javascript
RNZebraBluetoothPrinter.print(deviceAddress,zpl).then((res) => {
	//do something with res
})
```
iOS
```javascript
RNZebraBluetoothPrinter.print(zpl).then((res)=>{
	//do something with res
})
```	
  