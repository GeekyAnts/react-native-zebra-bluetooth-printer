
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
// import com.zebra.sdk.comm.BluetoothConnection;
// import com.zebra.sdk.comm.Connection;
// import com.zebra.sdk.printer.PrinterStatus;
// import com.zebra.sdk.comm.ConnectionException;
// import com.zebra.sdk.printer.PrinterLanguage;
// import com.zebra.sdk.printer.SGD;
// import com.zebra.sdk.printer.ZebraPrinter;
// import com.zebra.sdk.printer.ZebraPrinterFactory;
// import com.zebra.sdk.printer.discovery.DiscoveredPrinter;

public class RNZebraBluetoothPrinterModule extends ReactContextBaseJavaModule implements ActivityEventListener,BluetoothServiceStateObserver {

  private final ReactApplicationContext reactContext;
  private BluetoothAdapter bluetoothAdapter;
  private static final String TAG = "BluetoothManager";
  private LeDeviceListAdapter leDeviceListAdapter;
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
  
  private BluetoothAdapter.LeScanCallback leScanCallback = new BluetoothAdapter.LeScanCallback() {
    @Override
    public void onLeScan(final BluetoothDevice device, int rssi, byte[] scanRecord) {
      UiThreadUtil.runOnUiThread(new Runnable() {
        @Override
        public void run() {
          leDeviceListAdapter.addDevice(device);
          
          // leDeviceListAdapter.notifyDataSetChanged();
        }
      });
    }
  };
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
  public void show(String text) {
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
    handler = new Handler();
    if(bluetoothAdapter == null || !bluetoothAdapter.isEnabled()) {
      promise.reject("BT NOT ENABLED");
    } else {
      cancelDiscovery();
      // handler.postDelayed(new Runnable(){
      //   @Override 
      //   public void run() {
      //    bluetoothAdapter.stopLeScan(leScanCallback);
      //   }
      // }, 10000);
      // bluetoothAdapter.startLeScan(leScanCallback);
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

      // promise.resolve(LeDeviceListAdapter.mLeDevices);
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

  // public void disconnect() {
  //   try {
  //     if (connection != null) {
  //       connection.close();
  //     }

  //   } catch (ConnectionException e) {
  //     Log.d("Error on disconnect", e.toString());
  //   }
  // }
  // @ReactMethod
  // public void print(String device, String label, Boolean setTemplate, Callback errorCallback,
  //     Callback successCallback) {
  //   boolean success = false;
  //   boolean loading = false;
  //   sleep(500);
  //   connection = new BluetoothConnection(device);
  //   try {
  //     loading = true;
  //     connection.open();
  //   } catch (ConnectionException e) {
  //     disconnect();
  //     Log.d("Connection err", e.toString());
  //     loading = false;
  //     success = false;
  //     errorCallback.invoke("Unable to establish connection.Please try again!");
  //   }
  //   if (connection.isConnected()) {
  //     try {
  //       Log.d("Connection estd", "here");

  //       ZebraPrinter zebraPrinter = ZebraPrinterFactory.getInstance(connection);
  //       PrinterStatus status = zebraPrinter.getCurrentStatus();

  //       String pl = SGD.GET("device.languages", connection);

  //       byte[] configLabel = getConfigLabel(zebraPrinter, label, setTemplate);
  //       connection.write(configLabel);
  //       sleep(1500);
  //       success = true;
  //       loading = false;
  //       successCallback.invoke(loading, success);

  //     } catch (Exception err) {
  //       success = false;
  //       loading = false;
  //       Log.d("Connection err", err.toString());
  //       errorCallback.invoke(err.toString());
  //       // disconnect();
  //       // promise.reject(E_LAYOUT_ERROR, err);

  //     } finally {
  //       disconnect();
  //     }
  //   }

  // }
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


private class LeDeviceListAdapter {
        private ArrayList<BluetoothDevice> mLeDevices;
        // private LayoutInflater mInflator;
        public LeDeviceListAdapter() {
            super();
            mLeDevices = new ArrayList<BluetoothDevice>();
            // mInflator = DeviceScanActivity.this.getLayoutInflater();
        }
        public void addDevice(BluetoothDevice device) {
            if(!mLeDevices.contains(device)) {
                mLeDevices.add(device);
            }
        }
        public BluetoothDevice getDevice(int position) {
            return mLeDevices.get(position);
        }
        public void clear() {
            mLeDevices.clear();
        }
       
        public int getCount() {
            return mLeDevices.size();
        }
       
        public Object getItem(int i) {
            return mLeDevices.get(i);
        }
    
        public long getItemId(int i) {
            return i;
        }
      }
  
    }