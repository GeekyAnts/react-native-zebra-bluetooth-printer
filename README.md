
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
```javascript
import RNZebraBluetoothPrinter from 'react-native-zebra-bluetooth-printer';

// TODO: What to do with the module?
RNZebraBluetoothPrinter;
```
  