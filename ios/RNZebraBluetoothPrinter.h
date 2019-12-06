
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol WriteDataToBleDelegate <NSObject>
@required
- (void) didWriteDataToBle: (BOOL)success;
@end

@interface RNZebraBluetoothPrinter <CBCentralManagerDelegate,CBPeripheralDelegate> : RCTEventEmitter <RCTBridgeModule>
@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (nonatomic,copy) RCTPromiseResolveBlock scanResolveBlock;
@property (nonatomic,copy) RCTPromiseRejectBlock scanRejectBlock;
@property (strong,nonatomic) NSMutableDictionary <NSString *,CBPeripheral *> *foundDevices;
@property (strong,nonatomic) NSString *waitingConnect;
@property (nonatomic,copy) RCTPromiseResolveBlock connectResolveBlock;
@property (nonatomic,copy) RCTPromiseRejectBlock connectRejectBlock;
@property (strong, nonatomic) NSMutableData         *data;
@property (strong, nonatomic) CBCharacteristic      *writeCharacteristic;
@property (strong, nonatomic) CBPeripheral     *printer;
@property(nonatomic,copy) RCTPromiseResolveBlock printResolveBlock;
@property(nonatomic,copy) RCTPromiseRejectBlock printRejectBlock;
@property (nonatomic) bool * printerSuccess;
// DIS Values
@property (strong, nonatomic) IBOutlet UILabel      *disName;
@property (strong, nonatomic) IBOutlet UILabel      *disSerialNumber;
@property (strong, nonatomic) IBOutlet UILabel      *disManufacturerName;
@property (strong, nonatomic) IBOutlet UILabel      *disFirmwareRevision;
@property (strong, nonatomic) IBOutlet UILabel      *disHardwareRevision;
@property (strong, nonatomic) IBOutlet UILabel      *disSoftwareRevision;
+(void)writeValue:(NSData *) data withDelegate:(NSObject<WriteDataToBleDelegate> *) delegate;
+(Boolean)isConnected;
-(void)initSupportServices;
-(void)callStop;
@end
