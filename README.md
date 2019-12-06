
# react-native-zebra-bluetooth-printer

## Getting started

`$ npm install react-native-zebra-bluetooth-printer --save`

### Mostly automatic installation

`$ react-native link react-native-zebra-bluetooth-printer`

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


## Usage

# RNZebraBluetoothPrinter

RNZebraBluetoothPrinter is a module for Bluetooth management and supports print functionality for zebra bluetooth printers ( only ble devices ). 
It includes features like bluetooth enable/disable, pair/unpair a BLE/Bluetooth device, scan for nearby bluetooth devices and printing using bluetooth.
```javascript
import RNZebraBluetoothPrinter from 'react-native-zebra-bluetooth-printer';

// TODO: What to do with the module?
RNZebraBluetoothPrinter;
```
1. isEnabledBluetooth == > async function, check the status of bluetooth service in the bluetooth client(mobile phone) .Returns true if already enabled, false if not enabled.
2. enableBluetooth == > async function,
	 Android: requests for bluetooth on/off permission on the android device.
	 iOS: requests the user to go to settings and enable bluetooth as iOS doesn't give direct permission to access bluetooth.

3. disableBluetooth == > async function,
	Android: disables bluetooth if bluetooth is switched on.
	iOS: simply resolves by nil.
4. scanDevices == > async function, scans for available nearby bluetooth devices for a specific period of time.
5. pairedDevices == > async function, 	
	Android: returns already paired devices.
	iOS: resolves to nil.
6. unpairDevice == > async function,
	Android: unpair/disconnect a paired device from paired device list.
	iOS:
7. print == > async function, prints specific zpl string from a zebra printer for both android and iOS.		
  