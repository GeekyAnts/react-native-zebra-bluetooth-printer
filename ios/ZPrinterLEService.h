

#ifndef ZPrinterLEService_h
#define ZPrinterLEService_h

// Zebra printer UUID, defined on Link-OS® Environment Bluetooth® Low Energy
// AppNote (https://www.zebra.com/content/dam/zebra/software/en/application-notes/AppNote-BlueToothLE-v4.pdf)
#define ZPRINTER_SERVICE_UUID                   @"38EB4A80-C570-11E3-9507-0002A5D5C51B"
#define WRITE_TO_ZPRINTER_CHARACTERISTIC_UUID   @"38EB4A82-C570-11E3-9507-0002A5D5C51B"
#define READ_FROM_ZPRINTER_CHARACTERISTIC_UUID  @"38EB4A81-C570-11E3-9507-0002A5D5C51B"

// The names used for Notification Center
#define ZPRINTER_WRITE_NOTIFICATION        @"WriteNotification" // For sending ZPL
#define ZPRINTER_READ_NOTIFICATION         @"ReadNotification"  // For getting response
#define ZPRINTER_DIS_NOTIFICATION          @"DISNotification"   // For reading DIS values

// Device Information Service (DIS) of Zebra printer
#define ZPRINTER_DIS_SERVICE                    @"180A"
#define ZPRINTER_DIS_CHARAC_MODEL_NAME          @"2A24"
#define ZPRINTER_DIS_CHARAC_SERIAL_NUMBER       @"2A25"
#define ZPRINTER_DIS_CHARAC_FIRMWARE_REVISION   @"2A26"
#define ZPRINTER_DIS_CHARAC_HARDWARE_REVISION   @"2A27"
#define ZPRINTER_DIS_CHARAC_SOFTWARE_REVISION   @"2A28"
#define ZPRINTER_DIS_CHARAC_MANUFACTURER_NAME   @"2A29"

// device events
#define EVENT_DEVICE_ALREADY_PAIRED         @"EVENT_DEVICE_ALREADY_PAIRED"
#define EVENT_DEVICE_DISCOVER_DONE          @"EVENT_DEVICE_DISCOVER_DONE"
#define EVENT_DEVICE_FOUND                  @"EVENT_DEVICE_FOUND"
#define EVENT_CONNECTION_LOST               @"EVENT_CONNECTION_LOST"
#define EVENT_UNABLE_CONNECT                @"EVENT_UNABLE_CONNECT"
#define EVENT_CONNECTED                     @"EVENT_CONNECTED"
#endif /* ZPrinterLEService_h */

