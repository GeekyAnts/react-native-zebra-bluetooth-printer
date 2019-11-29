
package com.zebrabluetoothprinter;

import com.facebook.react.bridge.Callback;
import android.widget.Toast;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.bluetooth.BluetoothClass;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.bluetooth.le.ScanCallback;
// import androidx.core.app.ActivityCompat;
// import androidx.core.content.ContextCompat;
import android.util.Log;
import org.json.JSONException;
import com.facebook.react.bridge.*;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import org.json.JSONArray;
import org.json.JSONObject;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.uimanager.IllegalViewOperationException;
import javax.annotation.Nullable;
import java.lang.reflect.Method;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.logging.Handler;
import java.util.ArrayList;
import java.util.List;

// import com.zebra.sdk.comm.BluetoothConnection;
// import com.zebra.sdk.comm.Connection;
// import com.zebra.sdk.printer.PrinterStatus;
// import com.zebra.sdk.comm.ConnectionException;
// import com.zebra.sdk.printer.PrinterLanguage;
// import com.zebra.sdk.printer.SGD;
// import com.zebra.sdk.printer.ZebraPrinter;
// import com.zebra.sdk.printer.ZebraPrinterFactory;
// import com.zebra.sdk.printer.discovery.DiscoveredPrinter;

public class RNZebraBluetoothPrinterModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
  private BluetoothAdapter bluetoothAdapter;
  public BluetoothManager bluetoothManager;
  private boolean mScanning;
  public static Context context;
  private Handler handler;
  private static final long SCAN_PERIOD = 10000;
  private static final int BT_ENABLED_REQUEST = 1;
  private Activity activity;
  private static final String E_LAYOUT_ERROR = "E_LAYOUT_ERROR";
  public void getBluetoothManagerInstance(Context c) {
    this.bluetoothManager = (BluetoothManager) c.getSystemService(Context.BLUETOOTH_SERVICE);
    this.bluetoothAdapter = this.bluetoothManager.getAdapter();
  }
  public RNZebraBluetoothPrinterModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    context = getReactApplicationContext();
    this.getBluetoothManagerInstance(context);
  }

  @Override
  public String getName() {
    return "RNZebraBluetoothPrinter";
  }
  
  @ReactMethod
  public void show(String text) {
    // Context context = getReactApplicationContext();
    Toast.makeText(getReactApplicationContext(), text, Toast.LENGTH_LONG).show();
  }
  @ReactMethod
  public void enableBluetooth() {
   this.reactContext.startActivityForResult(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE),1,null);
  }
  @ReactMethod
  public void isEnabledBluetooth(final Promise promise) {
    
    if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled()) {
      Toast.makeText(getReactApplicationContext(), "Disabled", Toast.LENGTH_LONG).show();
      this.enableBluetooth();
      promise.resolve(false);
    }
    else {
      Toast.makeText(getReactApplicationContext(), "Enabled", Toast.LENGTH_LONG).show();
      promise.resolve(true);
    }
  }
  @ReactMethod 
  public void scanDevices(final Promise promise) {
    if(bluetoothAdapter == null || !bluetoothAdapter.isEnabled()) {
      promise.reject("BT NOT ENABLED");
    } else {
      // handler = new Handler();
      promise.resolve("can scan");
      // handler.postDelayed(new Runnable(){
      //   @Override 
      //   public void run() {
      //    bluetoothAdapter.stopLeScan(leScanCallback);
      //   }
      // }, SCAN_PERIOD);
      // bluetoothAdapter.startLeScan(leScanCallback);
      // promise.resolve("FOUND");
    }
  }
  @ReactMethod
  public void disableBluetooth(final Promise promise) {
    if( bluetoothAdapter == null ) {
      promise.resolve(true);
    }
    else {
      bluetoothAdapter.disable();
      promise.resolve(true);
    }
  }
  @ReactMethod
  public void pairedDevices(final Promise promise) {
    this.context = getCurrentActivity();
    if( bluetoothAdapter == null || !bluetoothAdapter.isEnabled()) {
      promise.reject("BT NOT ENABLED");
    }
    else {
          Set<BluetoothDevice> pairedDevices = bluetoothAdapter.getBondedDevices();
             List<String> deviceName = new ArrayList<String>();
            List<String> deviceAddress = new ArrayList<String>();
            List<Integer> ble = new ArrayList<Integer>();
          try {
      
        WritableArray app_list = Arguments.createArray();
        for (BluetoothDevice bt : pairedDevices) {
          BluetoothClass bluetoothClass = bt.getBluetoothClass();
          
          // promise.resolve("inside for loop");
         JSONObject info = new JSONObject();
          info.put("address", bt.getAddress());
      
          info.put("class", bluetoothClass.getDeviceClass()); // 1664
          info.put("name", bt.getName());
          info.put("type", "paired");
        
          // deviceAddress.add(bt.getAddress());
          app_list.pushString(info.toString());
        }
      promise.resolve(app_list.toString());
      } catch (JSONException e) {
        promise.reject(E_LAYOUT_ERROR, e);
      }
     
    }
  }
  @ReactMethod
  public void connectDevice(final Promise promise) {

  }
  @ReactMethod
  public void print() {
    
  }
}