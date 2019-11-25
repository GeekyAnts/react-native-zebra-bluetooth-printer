
package com.zebrabluetoothprinter;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import android.widget.Toast;
public class RNZebraBluetoothPrinterModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public RNZebraBluetoothPrinterModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
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
}