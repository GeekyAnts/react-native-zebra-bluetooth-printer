
package com.zebrabluetoothprinter;

import com.facebook.react.bridge.Callback;
import android.widget.Toast;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.bluetooth.le.ScanCallback;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.util.Log;
import com.facebook.react.bridge.*;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import org.json.JSONArray;
import org.json.JSONObject;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import javax.annotation.Nullable;
import java.lang.reflect.Method;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.logging.Handler;

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
      // Activity a = (Activity) getContext();
      // startActivityForResult(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE),1);
      Toast.makeText(getReactApplicationContext(), "Disabled", Toast.LENGTH_LONG).show();
      this.enableBluetooth();
      promise.resolve(false);
    }
    else {
         Toast.makeText(getReactApplicationContext(), "Enabled", Toast.LENGTH_LONG).show();
      promise.resolve(true);
    }
  }
  // @ReactMethod 
  // public void scanDevices(final Promise promise) {
  //   if(bluetoothAdapter == null || !bluetoothAdapter.isEnabled()) {
  //     promise.reject("BT NOT ENABLED");
  //   } else {
  //     handler.postDelayed(new Runnable(){
  //       @Override 
  //       public void run() {
  //        bluetoothAdapter.stopLeScan(leScanCallback);
  //       }
  //     }, SCAN_PERIOD);
  //     bluetoothAdapter.startLeScan(leScanCallback);
  //     promise.resolve("FOUND");
  //   }
  // }
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
}