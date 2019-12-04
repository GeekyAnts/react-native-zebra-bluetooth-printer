
package com.zebrabluetoothprinter;

import com.facebook.react.bridge.Callback;
import android.widget.Toast;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.bluetooth.BluetoothClass;
import com.facebook.react.bridge.UiThreadUtil;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.bluetooth.le.ScanCallback;
import android.util.Log;
import android.widget.BaseAdapter;
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
import android.os.Handler;
import java.util.ArrayList;
import java.util.List;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.zebra.sdk.comm.BluetoothConnection;
import com.zebra.sdk.comm.Connection;
import com.zebra.sdk.printer.PrinterStatus;
import com.zebra.sdk.comm.ConnectionException;
import com.zebra.sdk.printer.PrinterLanguage;
import com.zebra.sdk.printer.SGD;
import com.zebra.sdk.printer.ZebraPrinter;
import com.zebra.sdk.printer.ZebraPrinterFactory;
import com.zebra.sdk.printer.discovery.DiscoveredPrinter;

public class RNZebraBluetoothPrinterModule extends ReactContextBaseJavaModule implements ActivityEventListener,BluetoothServiceStateObserver {

  private final ReactApplicationContext reactContext;
  private BluetoothAdapter bluetoothAdapter;
  private static final String TAG = "BluetoothManager";
  // private LeDeviceListAdapter leDeviceListAdapter;
  public BluetoothManager bluetoothManager;
  private boolean mScanning;
  public static Context context;
  private static final String PROMISE_CONNECT = "CONNECT";
  private static final String PROMISE_ENABLE_BT = "ENABLE_BT";
  public static String EXTRA_DEVICE_ADDRESS = "device_address";
  private Handler handler;
  private String mConnectedDeviceName = null;
  private static final Map<String, Promise> promiseMap = Collections.synchronizedMap(new HashMap<String, Promise>());
  private BluetoothService mService = null;
  private static final int BT_ENABLED_REQUEST = 1;
  private Activity activity;
  private Connection connection;
  private static final String E_LAYOUT_ERROR = "E_LAYOUT_ERROR";
  public static final String EVENT_DEVICE_ALREADY_PAIRED = "EVENT_DEVICE_ALREADY_PAIRED";
  public static final String EVENT_DEVICE_FOUND = "EVENT_DEVICE_FOUND";
  public static final String EVENT_DEVICE_DISCOVER_DONE = "EVENT_DEVICE_DISCOVER_DONE";
  public static final String EVENT_CONNECTION_LOST = "EVENT_CONNECTION_LOST";
  public static final String EVENT_UNABLE_CONNECT = "EVENT_UNABLE_CONNECT";
  public static final String EVENT_CONNECTED = "EVENT_CONNECTED";
  public static final String EVENT_BLUETOOTH_NOT_SUPPORT = "EVENT_BLUETOOTH_NOT_SUPPORT";
  private static final String PROMISE_SCAN = "SCAN";
  // Intent request codes
  private static final int REQUEST_CONNECT_DEVICE = 1;
  private static final int REQUEST_ENABLE_BT = 2;
  private JSONArray pairedDeivce = new JSONArray();
  private JSONArray foundDevice = new JSONArray();
  public static final int MESSAGE_STATE_CHANGE = BluetoothService.MESSAGE_STATE_CHANGE;
  public static final int MESSAGE_READ = BluetoothService.MESSAGE_READ;
  public static final int MESSAGE_WRITE = BluetoothService.MESSAGE_WRITE;
  public static final int MESSAGE_DEVICE_NAME = BluetoothService.MESSAGE_DEVICE_NAME;

  public static final int MESSAGE_CONNECTION_LOST = BluetoothService.MESSAGE_CONNECTION_LOST;
  public static final int MESSAGE_UNABLE_CONNECT = BluetoothService.MESSAGE_UNABLE_CONNECT;
  public static final String DEVICE_NAME = BluetoothService.DEVICE_NAME;
  public static final String TOAST = BluetoothService.TOAST;
  public void getBluetoothManagerInstance(Context c) {                                        
    this.bluetoothManager = (BluetoothManager) c.getSystemService(Context.BLUETOOTH_SERVICE);
    this.bluetoothAdapter = this.bluetoothManager.getAdapter();
  }
  
  // private BluetoothAdapter.LeScanCallback leScanCallback = new BluetoothAdapter.LeScanCallback() {
  //   @Override
  //   public void onLeScan(final BluetoothDevice device, int rssi, byte[] scanRecord) {
  //     UiThreadUtil.runOnUiThread(new Runnable() {
  //       @Override
  //       public void run() {
  //         leDeviceListAdapter.addDevice(device);
          
  //         // leDeviceListAdapter.notifyDataSetChanged();
  //       }
  //     });
  //   }
  // };
  public RNZebraBluetoothPrinterModule(ReactApplicationContext reactContext,BluetoothService bluetoothService) {
    super(reactContext);
    this.reactContext = reactContext;
    context = getReactApplicationContext();
    this.getBluetoothManagerInstance(context);
    this.mService = bluetoothService;
    this.mService.addStateObserver(this);
    IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
    filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
    this.reactContext.registerReceiver(discoverReceiver, filter);
  }

  private void cancelDiscovery() {
    try {
      BluetoothAdapter adapter = this.bluetoothManager.getAdapter();
      if (adapter != null && adapter.isDiscovering()) {
        adapter.cancelDiscovery();
      }
      Log.d(TAG, "Discover canceled");
    } catch (Exception e) {
      // ignore
    }
  }

  @Override
  public String getName() {
    return "RNZebraBluetoothPrinter";
  }
  
  private void emitRNEvent(String event, @Nullable WritableMap params) {                            
    getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(event, params);
  }


  @ReactMethod
  public void enableBluetooth() {                                                                                       //enable bluetooth
   this.reactContext.startActivityForResult(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE),1,null);
  }
  @ReactMethod
  public void isEnabledBluetooth(final Promise promise) {                                                     //check if the bluetooth is enabled or not
    
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
  public void scanDevices(final Promise promise) {                                                    //scan for unpaired devices
    handler = new Handler();
    if(bluetoothAdapter == null || !bluetoothAdapter.isEnabled()) {
      promise.reject("BT NOT ENABLED");
    } else {
      cancelDiscovery();
     
      int permissionChecked = ContextCompat.checkSelfPermission(reactContext,
          android.Manifest.permission.ACCESS_COARSE_LOCATION);
      if (permissionChecked == PackageManager.PERMISSION_DENIED) {
    
        ActivityCompat.requestPermissions(reactContext.getCurrentActivity(),
            new String[] { android.Manifest.permission.ACCESS_COARSE_LOCATION }, 1);
      }
      if (!bluetoothAdapter.startDiscovery()) {
        promise.reject("DISCOVER", "NOT_STARTED");
        cancelDiscovery();
      } else {
        promiseMap.put(PROMISE_SCAN, promise);
      }

    }
  }
  @ReactMethod
  public void disableBluetooth(final Promise promise) {                                           // disable bluetooth
    if( bluetoothAdapter == null ) {
      promise.resolve(true);
    }
    else {
      bluetoothAdapter.disable();
      promise.resolve(true);
    }
  }
  @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        BluetoothAdapter adapter = this.bluetoothManager.getAdapter();
        Log.d(TAG, "onActivityResult " + resultCode);
        switch (requestCode) {
            case REQUEST_CONNECT_DEVICE: {
                // When DeviceListActivity returns with a device to connect
                if (resultCode == Activity.RESULT_OK) {
                    // Get the device MAC address
                    String address = data.getExtras().getString(
                            EXTRA_DEVICE_ADDRESS);
                    // Get the BLuetoothDevice object
                    if (adapter!=null && BluetoothAdapter.checkBluetoothAddress(address)) {
                        BluetoothDevice device = adapter
                                .getRemoteDevice(address);
                        // Attempt to connect to the device
                        mService.connect(device);
                    }
                }
                break;
            }
            case REQUEST_ENABLE_BT: {
                Promise promise = promiseMap.remove(PROMISE_ENABLE_BT);
                // When the request to enable Bluetooth returns
                if (resultCode == Activity.RESULT_OK && promise != null) {
                    // Bluetooth is now enabled, so set up a session
                    if(adapter!=null){
                        WritableArray pairedDeivce =Arguments.createArray();
                        Set<BluetoothDevice> boundDevices = adapter.getBondedDevices();
                        for (BluetoothDevice d : boundDevices) {
                            try {
                                JSONObject obj = new JSONObject();
                                obj.put("name", d.getName());
                                obj.put("address", d.getAddress());
                                pairedDeivce.pushString(obj.toString());
                            } catch (Exception e) {
                                //ignore.
                            }
                        }
                        promise.resolve(pairedDeivce);
                    }else{
                        promise.resolve(null);
                    }

                } else {
                    // User did not enable Bluetooth or an error occured
                    Log.d(TAG, "BT not enabled");
                    if (promise != null) {
                        promise.reject("ERR", new Exception("BT NOT ENABLED"));
                    }
                }
                break;
            }
        }
    }

  @Override
  public void onNewIntent(Intent intent) {

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
  
  private final BroadcastReceiver discoverReceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
      String action = intent.getAction();
      Log.d(TAG, "on receive:" + action);
      // When discovery finds a device
      if (BluetoothDevice.ACTION_FOUND.equals(action)) {
        // Get the BluetoothDevice object from the Intent
        BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
        if (device.getBondState() != BluetoothDevice.BOND_BONDED) {
          JSONObject deviceFound = new JSONObject();
          try {
            deviceFound.put("name", device.getName());
            deviceFound.put("address", device.getAddress());
          } catch (Exception e) {
            // ignore
          }
          if (!objectFound(deviceFound)) {
            foundDevice.put(deviceFound);
            WritableMap params = Arguments.createMap();
            params.putString("device", deviceFound.toString());
            reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(EVENT_DEVICE_FOUND,
                params);
          }

        }
      } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
        Promise promise = promiseMap.remove(PROMISE_SCAN);
        if (promise != null) {

          JSONObject result = null;
          try {
            result = new JSONObject();
            result.put("paired", pairedDeivce);
            result.put("found", foundDevice);
            promise.resolve(result.toString());
          } catch (Exception e) {
            // ignore
          }
          WritableMap params = Arguments.createMap();
          params.putString("paired", pairedDeivce.toString());
          params.putString("found", foundDevice.toString());
          emitRNEvent(EVENT_DEVICE_DISCOVER_DONE, params);
        }
      }
    }
  };

  private boolean objectFound(JSONObject obj) {
    boolean found = false;
    if (foundDevice.length() > 0) {
      for (int i = 0; i < foundDevice.length(); i++) {
        try {
          String objAddress = obj.optString("address", "objAddress");
          String dsAddress = ((JSONObject) foundDevice.get(i)).optString("address", "dsAddress");
          if (objAddress.equalsIgnoreCase(dsAddress)) {
            found = true;
            break;
          }
        } catch (Exception e) {
        }
      }
    }
    return found;
  }
  @ReactMethod
  public void connectDevice(String address,final Promise promise) {
    BluetoothAdapter adapter = this.bluetoothManager.getAdapter();
    if (adapter != null && adapter.isEnabled()) {
      BluetoothDevice device = adapter.getRemoteDevice(address);
      promiseMap.put(PROMISE_CONNECT, promise);
      mService.connect(device);
    } else {
      promise.reject("BT NOT ENABLED");
    }
  }
  
  public static void sleep(int ms) {
    try {
      Thread.sleep(ms);
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }

  public void disconnect() {
    try {
      if (connection != null) {
        connection.close();
      }

    } catch (ConnectionException e) {
      Log.d("Error on disconnect", e.toString());
    }
  }
  
  private byte[] getConfigLabel(ZebraPrinter printer, String label, Boolean setTemplate) {
    byte[] configLabel = null;
    String template = "CT~~CD,~CC^~CT~\n" + "^XA~TA000~JSN^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR6,6~SD15^JUS^LRN^CI0^XZ\n"
        + "^XA\n" + "^MMT\n" + "^PW734\n" + "^LL1231\n" + "^LS0\n" + "^FO0,768^GFA,38272,38272,00092,:Z64:\n"
        + "eJzs0aERADAIADEG6/AM1rvWIjAIXH6AmI+QJEmSVHtrXXZj59rJw2az2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZo/sDwAA///t3SEBAAAAwrD+rQmARrEHWIWz2Ww2m81ms7/s5ced3bYkSZK+CxLzLNk=:2676\n"
        + "^FO544,384^GFA,08448,08448,00024,:Z64:\n"
        + "eJzt2bENACAMA8F0LMVwDI4EC6SJFKjuy2s8gCOk/sbJ2n2+stXJOeecc84555xzzjnnnHPOOa/4419P+tkF6t+Orw==:613B\n"
        + "^FO0,384^GFA,03072,03072,00024,:Z64:\n"
        + "eJxjYBgFo4B88B8reEA18QfYLGUcFR8VHxUfFR8VHxVHFad1fTQKRsFwAgDs9Soi:881A\n"
        + "^FO0,64^GFA,11776,11776,00092,:Z64:\n"
        + "eJzt2kENACAQA8HzrxIJOAAB8LqkISGzAubTb6skdVqxJvtij9iSbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2W/s5NeCfdqSJP3SBqioe54=:6F90\n"
        + "^FO160,384^GFA,06656,06656,00052,:Z64:\n"
        + "eJzt16ENACAMRNEyAftvxyZgcU1NQ8j7/omTFyFJnzZ2refNKs2fDMMwDMMwDMMwTGK6/lyTkSTp6gCtY7SA:79AF\n"
        + "^FO160,160^GFA,13312,13312,00052,:Z64:\n"
        + "eJzt2rENACAMA8F0rM3I2QDECGkiBPf9Fe4dIZ1WrXm7ydL6wTAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzBfm66/f5d5qw1iM9Ft:54B5\n"
        + "^FO0,160^GFA,23552,23552,00092,:Z64:\n"
        + "eJzt3DENACAUQ8EvDP86EEICAmAiKSz3BNzSvVWSbpqxBvtg99iSjc1ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZn+wk3+m7N3W2xZx7Nny:39B6\n"
        + "^FO0,448^GFA,13824,13824,00072,:Z64:\n"
        + "eJzt2jENADAMA8EwKH+WZdBS6OBIVXQP4AbPrpIkSertJBrs7MDGi8PhcDgcDofD4XA4HA6Hw+FwOBwOh8PhcDgcDofD4XA4HA6Hw3l0Uj/Yqc5vXbfZvV8=:185D\n"
        + "^FO0,608^GFA,09216,09216,00072,:Z64:\n"
        + "eJzt2DEVACAMQ8Fu2EYqTkBEs9B3X8ANGVMlSZK63UR7rnMCGy8Oh8PhcDgcDofD4XA4HA7nUyf1s011JElSvwcBgIlT:9B3D\n"
        + "^FO0,704^GFA,11776,11776,00092,:Z64:\n"
        + "eJzt2aERACAQA8Evm7KRODA4sBE/s1fAmshU9WzHWuyPPWNLDjabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2ddOfv/s15YkSZI6dgABKlDe:FE9A\n"
        + "^FO352,64^GFA,06144,06144,00048,:Z64:\n"
        + "eJzt10uOnDAQBmBbLFhyBF8kCleaZRZRY2kOkqPEN8gVmBuQnaVBVOovmzYPQyCaTtIS1sht4IP2YLvKrdRVnqxUdLj0l7/8v/WqUc38mKsWrjzuHVxx3NuTXp3zw0nvH+zbB3v7WB9e5+O8//veq7ESP6ga1lbiu7W3ymCWl9G3aOG54t3KDzjiSkdv0cKw1jT2zk+9B0U3G/GDtPDcyqnQtblHDxtUtfheWlglZd6jhzVmlRHfSQvfUuQ9Johx0oZvpYWLOu/xYXBTKd5Jq0teBiH5QWmvaqVwLniyBfvKFhue+3HjR1ot3pbUFvw6yZdZ3/M5h6pT4vmU1+Q09VXWez7+2cvJ4Gu+Qo7HmN9XTRlP9I6qF32TGSSz51uMV3PfYfS5B6ym3sT5ufbcDBW/pUZ9jfO03vItZmOHyorXR7xU1oze3sLMzHosAalc8p8P+y9F8PRR3i28LL89b4TKTXf/6azXf+qxMNQzebx/6n/jWzMbL8zoTZ8Z37Uvd+fDGa+Db+a+2p3/Ex/HN3lZWov1SLRcX83u+t316/hAP1bxgbbjDz/5VeLP9w3f0Ns0vnHw12N8+wDfM3BS3eMt4ifibfJl8gPyBOK5ivEcwZ+zTNOVyZvkOb90yBcvKV/wH+cLOc54jPgkH7VqzK86+XrpnRrzHTJXEfJd3uOBk3zq5Zskn+Z9Jl+HrJn+33eaeNkP4CDuH+ROZHGT94Ps1mULEvcbGJ027CfGSTTx/CiDatw6dbiTr2qal7RfwpX+fjnul9zyp8cT/N65/OX/L3+Vq1zlKtnyC7+HEQk=:C478\n"
        + "^BY4,3,160^FT50,1068^BCN,,Y,N\n" + "^FD>;8900>60JX>553713012^FS\n" + "^FT31,390^A0N,51,50^FH\\^FDNRHT^FS\n"
        + "^FT193,455^A0N,28,28^FH\\^FDNN4 5EL^FS\n"
        + "^FT96,764^A0N,28,28^FH\\^FDStorekeeper instruction: GIVE TO DRIVER^FS\n"
        + "^FT578,668^A0N,51,50^FH\\^FD72 HR^FS\n" + "^FT94,682^A0N,28,28^FH\\^FDParcel label for ECPABCDEFGH^FS\n"
        + "^FT33,439^A0N,20,19^FH\\^FDCreation Date: ^FS\n" + "^FT33,463^A0N,20,19^FH\\^FD06-06-2019^FS\n"
        + "^FT589,556^A0N,102,100^FH\\^FD72^FS\n" + "^FT560,328^A0N,102,100^FH\\^FD02A^FS\n"
        + "^FT93,517^A0N,25,24^FH\\^FDClick & Collect your online purchases ^FS\n"
        + "^FT93,548^A0N,25,24^FH\\^FD      to your local Collect+ store^FS\n"
        + "^FT93,610^A0N,25,24^FH\\^FDwww.collectplus.co.uk/services^FS\n" + "^FT42,303^A0N,102,100^FH\\^FD12^FS\n"
        + "^FT190,225^A0N,28,28^FH\\^FDJohn Lewis^FS\n" + "^FT190,259^A0N,28,28^FH\\^FDClipper Logistics^FS\n"
        + "^FT190,293^A0N,28,28^FH\\^FDUnit 1, Saxon Avenue,^FS\n" + "^FT190,327^A0N,28,28^FH\\^FDGrange Park^FS\n"
        + "^FT190,361^A0N,28,28^FH\\^FDNorthampton^FS\n" + "^FT190,395^A0N,28,28^FH\\^FDNorthamptonshire^FS\n"
        + "^PQ1,0,1,Y^XZ";
    String printLabel = label;
    try {
      PrinterLanguage printerLanguage = printer.getPrinterControlLanguage();
      SGD.SET("device.languages", "zpl", connection);

      if (printerLanguage == PrinterLanguage.ZPL) {
        if (setTemplate == true) {
          configLabel = template.getBytes();

        } else {
          configLabel = printLabel.getBytes();
        }
      } else if (printerLanguage == PrinterLanguage.CPCL) {
        String cpclConfigLabel = "! 0 200 200 406 1\r\n" + "ON-FEED IGNORE\r\n" + "BOX 20 20 380 380 8\r\n"
            + "T 0 6 137 177 TEST\r\n" + "PRINT\r\n";
        configLabel = cpclConfigLabel.getBytes();
      }
    } catch (ConnectionException e) {
      Log.d("Connection err", e.toString());
      // disconnect();
    }
    return configLabel;
  }
  @ReactMethod
  public void print(String device, String label, Boolean setTemplate,final Promise promise) {
    boolean success = false;
    boolean loading = false;
    sleep(500);
    connection = new BluetoothConnection(device);
    try {
      loading = true;
      connection.open();
    } catch (ConnectionException e) {
      disconnect();
      Log.d("Connection err", e.toString());
      loading = false;
      success = false;
      promise.reject("Unable to establish connection.Please try again!!!");
    }
    if (connection.isConnected()) {
      try {
        Log.d("Connection estd", "here");

        ZebraPrinter zebraPrinter = ZebraPrinterFactory.getInstance(connection);
        PrinterStatus status = zebraPrinter.getCurrentStatus();

        String pl = SGD.GET("device.languages", connection);

        byte[] configLabel = getConfigLabel(zebraPrinter, label, setTemplate);
        connection.write(configLabel);
        sleep(1500);
        success = true;
        loading = false;
       promise.resolve(success);

      } catch (Exception err) {
        success = false;
        loading = false;
        Log.d("Connection err", err.toString());
        promise.reject(err.toString());
        // disconnect();
        // promise.reject(E_LAYOUT_ERROR, err);

      } finally {
        disconnect();
      }
    }

  }
  @Override
    public void onBluetoothServiceStateChanged(int state, Map<String, Object> bundle) {
        Log.d(TAG,"on bluetoothServiceStatChange:"+state);
        switch (state) {
            case BluetoothService.STATE_CONNECTED:
            case MESSAGE_DEVICE_NAME: {
                // save the connected device's name
                mConnectedDeviceName = (String) bundle.get(DEVICE_NAME);
                Promise p = promiseMap.remove(PROMISE_CONNECT);
                if (p == null) {   Log.d(TAG,"No Promise found.");
                    WritableMap params = Arguments.createMap();
                    params.putString(DEVICE_NAME, mConnectedDeviceName);
                    emitRNEvent(EVENT_CONNECTED, params);
                } else { Log.d(TAG,"Promise Resolve.");
                    p.resolve(mConnectedDeviceName);
                }

                break;
            }
            case MESSAGE_CONNECTION_LOST: {
                //Connection lost should not be the connect result.
               // Promise p = promiseMap.remove(PROMISE_CONNECT);
               // if (p == null) {
                    emitRNEvent(EVENT_CONNECTION_LOST, null);
               // } else {
                 //   p.reject("Device connection was lost");
                //}
                break;
            }
            case MESSAGE_UNABLE_CONNECT: {     //无法连接设备
                Promise p = promiseMap.remove(PROMISE_CONNECT);
                if (p == null) {
                    emitRNEvent(EVENT_UNABLE_CONNECT, null);
                } else {
                    p.reject("Unable to connect device");
                }

                break;
            }
            default:
                break;
        }
      }


// private class LeDeviceListAdapter {
//         private ArrayList<BluetoothDevice> mLeDevices;
//         // private LayoutInflater mInflator;
//         public LeDeviceListAdapter() {
//             super();
//             mLeDevices = new ArrayList<BluetoothDevice>();
//             // mInflator = DeviceScanActivity.this.getLayoutInflater();
//         }
//         public void addDevice(BluetoothDevice device) {
//             if(!mLeDevices.contains(device)) {
//                 mLeDevices.add(device);
//             }
//         }
//         public BluetoothDevice getDevice(int position) {
//             return mLeDevices.get(position);
//         }
//         public void clear() {
//             mLeDevices.clear();
//         }
       
//         public int getCount() {
//             return mLeDevices.size();
//         }
       
//         public Object getItem(int i) {
//             return mLeDevices.get(i);
//         }
    
//         public long getItemId(int i) {
//             return i;
//         }
//       }
  
    }