
#import <Foundation/Foundation.h>
#import "RNZebraBluetoothPrinter.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "ZPrinterLEService.h"
#import "React/RCTEventDispatcher.h"
    
@implementation RNZebraBluetoothPrinter;

static NSArray<CBUUID *> *supportServices = nil;
static NSDictionary *writeableCharactiscs = nil;
bool hasListeners;
bool printCompleted;
static CBPeripheral *connected;
static RNZebraBluetoothPrinter *instance;
static NSObject<WriteDataToBleDelegate> *writeDataDelegate;// delegate of write data resule;
static NSData *toWrite;
static NSTimer *timer;
static CBPeripheral * printer;

RCT_EXPORT_MODULE();
+(Boolean)isConnected{
    return !(connected==nil);
}

+(void)writeValue:(NSData *) data withDelegate:(NSObject<WriteDataToBleDelegate> *) delegate
{
    @try{
        writeDataDelegate = delegate;
        toWrite = data;
        connected.delegate = instance;
        [connected discoverServices:supportServices];
//    [connected writeValue:data forCharacteristic:[writeableCharactiscs objectForKey:supportServices[0]] type:CBCharacteristicWriteWithoutResponse];
    }
    @catch(NSException *e){
        NSLog(@"error in writing data to %@,issue:%@",connected,e);
        [writeDataDelegate didWriteDataToBle:false];
    }
}

// Will be called when this module's first listener is added.
-(void)startObserving {
    hasListeners = YES;
    // Set up any upstream listeners or background tasks as necessary
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    hasListeners = NO;
    // Remove upstream listeners, stop unnecessary background tasks
}

/**
 * Exports the constants to javascritp.
 **/
- (NSDictionary *)constantsToExport
{
    
    /*
     EVENT_DEVICE_ALREADY_PAIRED    Emits the devices array already paired
     EVENT_DEVICE_DISCOVER_DONE    Emits when the scan done
     EVENT_DEVICE_FOUND    Emits when device found during scan
     EVENT_CONNECTION_LOST    Emits when device connection lost
     EVENT_UNABLE_CONNECT    Emits when error occurs while trying to connect device
     EVENT_CONNECTED    Emits when device connected
     */

    return @{ EVENT_DEVICE_ALREADY_PAIRED: EVENT_DEVICE_ALREADY_PAIRED,
              EVENT_DEVICE_DISCOVER_DONE:EVENT_DEVICE_DISCOVER_DONE,
              EVENT_DEVICE_FOUND:EVENT_DEVICE_FOUND,
              EVENT_CONNECTION_LOST:EVENT_CONNECTION_LOST,
              EVENT_UNABLE_CONNECT:EVENT_UNABLE_CONNECT,
              EVENT_CONNECTED:EVENT_CONNECTED
              };
}
- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

/**
 * Defines the event would be emited.
 **/
- (NSArray<NSString *> *)supportedEvents
{
    return @[EVENT_DEVICE_DISCOVER_DONE,
             EVENT_DEVICE_FOUND,
             EVENT_UNABLE_CONNECT,
             EVENT_CONNECTION_LOST,
             EVENT_CONNECTED,
             EVENT_DEVICE_ALREADY_PAIRED];
}

RCT_EXPORT_METHOD(print:(NSString*)zpl
                  findEventsWithResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"print called %@",_writeCharacteristic);
    NSLog(@"print calles %@",_printer);
  self.printResolveBlock=resolve;
  self.printRejectBlock=reject;
  NSString *szpl = [zpl stringByAppendingString:@"\r\n"];
    const char *bytes = [szpl UTF8String];
    size_t len = [szpl length];
    NSData *payload = [NSData dataWithBytes:bytes length:len];
    NSUInteger length = [payload length];
    NSUInteger chunkSize = 50;
    NSUInteger offset = 0;
do {
    NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
    NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[payload bytes] + offset  
                    length:thisChunkSize  freeWhenDone:NO];
                    offset += thisChunkSize;
    [self.printer writeValue:chunk forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
} while (offset < length);
  printCompleted = YES; 
}


//isBluetoothEnabled
RCT_EXPORT_METHOD(isEnabledBluetooth:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    CBManagerState state = [self.centralManager  state];
    resolve(state == CBManagerStatePoweredOn?@"true":@"false");//canot pass boolean or int value to resolve directly.
}

//enableBluetooth
RCT_EXPORT_METHOD(enableBluetooth:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve(nil);
}
RCT_EXPORT_METHOD(unpairDevice:(NSString*)address
                 findEventsWithResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) 
{
resolve(nil);
}
//disableBluetooth
RCT_EXPORT_METHOD(disableBluetooth:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve(nil);
}
// find paired Devices
RCT_EXPORT_METHOD(pairedDevices:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve(nil);
}
//scanDevices
RCT_EXPORT_METHOD(scanDevices:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    @try{
        if (!self.centralManager || self.centralManager.state!=CBManagerStatePoweredOn) {
            reject(@"BLUETOOTCH_INVALID_STATE",@"BLUETOOTCH_INVALID_STATE",nil);
            return;
        }
        if (self.centralManager.isScanning) {
            [self.centralManager stopScan];
        }
        self.scanResolveBlock = resolve;
        self.scanRejectBlock = reject;
        if (connected && connected.identifier) {
            NSLog(@"values%@",connected);
            BOOL state= connected.state;
            NSString *status;
            if (state) {
                status=@"connected";
            }
            else {
                status=@"not-connected";
            }
            NSDictionary *idAndName =@{@"address":connected.identifier.UUIDString,@"name":connected.name?connected.name:@"",@"state":status};
            NSDictionary *peripheralStored = @{connected.identifier.UUIDString:connected};
            if (!self.foundDevices) {
                self.foundDevices = [[NSMutableDictionary alloc] init];
            }
            [self.foundDevices addEntriesFromDictionary:peripheralStored];
            if (hasListeners) {
                [self sendEventWithName:EVENT_DEVICE_FOUND body:@{@"device":idAndName}];
            }
        }
        [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        //Callbacks:
        // centralManager:didDiscoverPeripheral:advertisementData:RSSI:
        NSLog(@"Scanning started with services.");
        if(timer && timer.isValid) {
            [timer invalidate];
            timer = nil;
        }
        timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(callStop) userInfo:nil repeats:NO];
    
    }
    @catch(NSException *exception){
        NSLog(@"ERROR IN STARTING SCANE %@",exception);
        reject([exception name],[exception name],nil);
    }
}
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"did discover peripheral: %@",peripheral);
  
    NSDictionary *idAndName =@{@"address":peripheral.identifier.UUIDString,@"name":peripheral.name?peripheral.name:@"",@"state":peripheral};
    NSDictionary *peripheralStored = @{peripheral.identifier.UUIDString:peripheral};
    if ( !self.foundDevices ) {
        self.foundDevices = [[NSMutableDictionary alloc] init];
    }
    [self.foundDevices addEntriesFromDictionary:peripheralStored];
    NSLog(@"CentralManager");
   
    if(hasListeners) {
        NSLog(@"Listeners");
        [self sendEventWithName:EVENT_DEVICE_FOUND body:@{@"device":idAndName}];
    }
    if(_waitingConnect && [_waitingConnect isEqualToString: peripheral.identifier.UUIDString]){
        NSLog(@"stopcall");
        [self.centralManager connectPeripheral:peripheral options:nil];
        [self callStop];
    }
}

//stop scan
RCT_EXPORT_METHOD(stopScan:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self callStop];
    resolve(nil);
}

//connect(address)
RCT_EXPORT_METHOD(connectDevice:(NSString *)address
                  findEventsWithResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Trying to connect....%@",address);
    [self callStop];
  
    CBPeripheral *peripheral = [self.foundDevices objectForKey:address];
    self.connectResolveBlock = resolve;
    self.connectRejectBlock = reject;
    if(peripheral){
          _waitingConnect = address;
          NSLog(@"Trying to connectPeripheral....%@",address);
        [self.centralManager connectPeripheral:peripheral options:nil];
        // Callbacks:
        //    centralManager:didConnectPeripheral:
        //    centralManager:didFailToConnectPeripheral:error:
    } else {
          //starts the scan.
        _waitingConnect = address;
         NSLog(@"Scan to find ....%@",address);
        [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        //Callbacks:
        //centralManager:didDiscoverPeripheral:advertisementData:RSSI:
    }
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"did connected: %@",peripheral);
    connected = peripheral;
    NSString *pId = peripheral.identifier.UUIDString;
    if(_waitingConnect && [_waitingConnect isEqualToString: pId] && self.connectResolveBlock){
        NSLog(@"Predefined the support services, stop to looking up services.");
        self.connectResolveBlock(nil);
        _waitingConnect = nil;
        self.connectRejectBlock = nil;
        self.connectResolveBlock = nil;

    }
    peripheral.delegate=self;
    _printer=peripheral;
    self.printer=peripheral;    
       NSLog(@"going to emit EVENT_CONNECTED.");
        [peripheral discoverServices:@[[CBUUID UUIDWithString:ZPRINTER_SERVICE_UUID], [CBUUID UUIDWithString:ZPRINTER_DIS_SERVICE]]];
    if (hasListeners) {
        [self sendEventWithName:EVENT_CONNECTED body:@{@"device":@{@"name":peripheral.name?peripheral.name:@"",@"address":peripheral.identifier.UUIDString}}];
    }
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    if (self.connectRejectBlock) {
        RCTPromiseRejectBlock rjBlock = self.connectRejectBlock;
        rjBlock(@"",@"",error);
        self.connectRejectBlock = nil;
        self.connectResolveBlock = nil;
        _waitingConnect = nil;
    }
    connected = nil;
    if (hasListeners) {
        [self sendEventWithName:EVENT_UNABLE_CONNECT body:@{@"name":peripheral.name?peripheral.name:@"",@"address":peripheral.identifier.UUIDString}];
    }
    }
-(void)callStop{
    if (self.centralManager.isScanning) {
        [self.centralManager stopScan];
        NSMutableArray *devices = [[NSMutableArray alloc] init];
         
        for(NSString *key in self.foundDevices){
            NSLog(@"insert found devies:%@ =>%@",key,[self.foundDevices objectForKey:key]);
            NSString *name = [self.foundDevices objectForKey:key].name;
            BOOL state= [self.foundDevices objectForKey:key].state;
            NSLog(@"stateIs %d",state);
            NSString *status;
            if (state) {
                status=@"connected";
            }
            else {
                status=@"not-connected";
            }
            if (!name) {
                name = @"";
            }
            [devices addObject:@{@"address":key,@"name":name,@"state":status}];
        }
        NSError *error = nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:devices options:NSJSONWritingPrettyPrinted error:&error];
        NSString * jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (hasListeners) {
            [self sendEventWithName:EVENT_DEVICE_DISCOVER_DONE body:@{@"found":jsonStr,@"paired":@"[]"}];
        }
        if (self.scanResolveBlock) {
            RCTPromiseResolveBlock rsBlock = self.scanResolveBlock;
            rsBlock(@{@"found":jsonStr,@"paired":@"[]"});
            self.scanResolveBlock = nil;
        }
    }
    if (timer && timer.isValid) {
        [timer invalidate];
        timer = nil;
    }
    self.scanRejectBlock = nil;
    self.scanResolveBlock = nil;
}
- (void) initSupportServices
{
    if (!supportServices) {
        CBUUID *issc = [CBUUID UUIDWithString: @"49535343-FE7D-4AE5-8FA9-9FAFD205E455"];
        supportServices = [NSArray arrayWithObject:issc];/*ISSC*/
        writeableCharactiscs = @{issc:@"49535343-8841-43F4-A8D4-ECBE34729BB3"};
    }
}

- (CBCentralManager *) centralManager
{
    @synchronized(_centralManager)
    {
        if (!_centralManager) {
            if (![CBCentralManager instancesRespondToSelector:@selector(initWithDelegate:queue:options:)]) {
                //for ios version lowser than 7.0
                self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
            } else {
                self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey:@(YES)} ];
            }
        }
        if (!instance) {
            instance = self;
        }
    }
    [self initSupportServices];
    return _centralManager;
}

/**
 * CBCentralManagerDelegate
 **/
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSLog(@"%ld",(long)central.state);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    if (!connected && _waitingConnect && [_waitingConnect isEqualToString:peripheral.identifier.UUIDString]) {
        if (self.connectRejectBlock) {
            RCTPromiseRejectBlock rjBlock = self.connectRejectBlock;
            rjBlock(@"",@"",error);
            self.connectRejectBlock = nil;
            self.connectResolveBlock = nil;
            _waitingConnect=nil;
        }
        connected = nil;
        if (hasListeners) {
            [self sendEventWithName:EVENT_UNABLE_CONNECT body:@{@"name":peripheral.name?peripheral.name:@"",@"address":peripheral.identifier.UUIDString}];
        }
    }else{
        connected = nil;
        if (hasListeners) {
            [self sendEventWithName:EVENT_CONNECTION_LOST body:nil];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
  NSLog(@"did called2");
    // Deal with errors (if any)
    if (error) {
        return;
    }
    // Discover the characteristics of Write-To-Printer and Read-From-Printer.
    // Loop through the newly filled peripheral.services array, just in case there's more than one service.
    for (CBService *service in peripheral.services) {
        NSLog(@"atleast this:%@",service);
        // Discover the characteristics of read from and write to printer
        if ([service.UUID isEqual:[CBUUID UUIDWithString:ZPRINTER_SERVICE_UUID]]) {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:WRITE_TO_ZPRINTER_CHARACTERISTIC_UUID],
                                                  [CBUUID UUIDWithString:READ_FROM_ZPRINTER_CHARACTERISTIC_UUID]] forService:service];
        } else if ([service.UUID isEqual:[CBUUID UUIDWithString:ZPRINTER_DIS_SERVICE]]) {
            
            // Discover the characteristics of Device Information Service (DIS)
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_MODEL_NAME],
                                                  [CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_SERIAL_NUMBER],
                                                  [CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_FIRMWARE_REVISION],
                                                  [CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_HARDWARE_REVISION],
                                                  [CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_SOFTWARE_REVISION],
                                                  [CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_MANUFACTURER_NAME]] forService:service];

        }
    }
}


// The characteristics of Zebra Printer Service was discovered. Then we want to subscribe to the characteristics.
// This lets the peripheral know we want the data it contains.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
  NSLog(@"didDiscoverCalled1");
    // Deal with errors (if any)
    if (error) {   
        return;
    }
    // Again, we loop through the array, as there might be multiple characteristics in service.
    for (CBCharacteristic *characteristic in service.characteristics) {
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:WRITE_TO_ZPRINTER_CHARACTERISTIC_UUID]]) {
            NSLog(@"write characteristic called:");
            // WRITE_TO_ZPRINTER_CHARACTERISTIC_UUID is a write-only characteristic
            // Notify that Write Characteristic has been discovered through the Notification Center
            [[NSNotificationCenter defaultCenter] postNotificationName:ZPRINTER_WRITE_NOTIFICATION object:self userInfo:@{@"Characteristic":characteristic}];
            
        //   NSString * zpl=@"CT~~CD,~CC^~CT~^XA^MMT^PW734^LL1231^LS0^FO0,768^GFA,38272,38272,00092,:Z64:\neJzs0aERADAIADEG6/AM1rvWIjAIXH6AmI+QJEmSVHtrXXZj59rJw2az2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZo/sDwAA///t3SEBAAAAwrD+rQmARrEHWIWz2Ww2m81ms7/s5ced3bYkSZK+CxLzLNk=:2676^FO544,384^GFA,08448,08448,00024,:Z64:\neJzt2bENACAMA8F0LMVwDI4EC6SJFKjuy2s8gCOk/sbJ2n2+stXJOeecc84555xzzjnnnHPOOa/4419P+tkF6t+Orw==:613B^FO0,384^GFA,03072,03072,00024,:Z64:\neJxjYBgFo4B88B8reEA18QfYLGUcFR8VHxUfFR8VHxVHFad1fTQKRsFwAgDs9Soi:881A^FO0,64^GFA,11776,11776,00092,:Z64:\neJzt2kENACAQA8HzrxIJOAAB8LqkISGzAubTb6skdVqxJvtij9iSbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2W/s5NeCfdqSJP3SBqioe54=:6F90^FO160,384^GFA,06656,06656,00052,:Z64:\neJzt16ENACAMRNEyAftvxyZgcU1NQ8j7/omTFyFJnzZ2refNKs2fDMMwDMMwDMMwTGK6/lyTkSTp6gCtY7SA:79AF^FO160,160^GFA,13312,13312,00052,:Z64:\neJzt2rENACAMA8F0rM3I2QDECGkiBPf9Fe4dIZ1WrXm7ydL6wTAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzBfm66/f5d5qw1iM9Ft:54B5^FO0,160^GFA,23552,23552,00092,:Z64:\neJzt3DENACAUQ8EvDP86EEICAmAiKSz3BNzSvVWSbpqxBvtg99iSjc1ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZn+wk3+m7N3W2xZx7Nny:39B6^FO0,448^GFA,13824,13824,00072,:Z64:\neJzt2jENADAMA8EwKH+WZdBS6OBIVXQP4AbPrpIkSertJBrs7MDGi8PhcDgcDofD4XA4HA6Hw+FwOBwOh8PhcDgcDofD4XA4HA6Hw3l0Uj/Yqc5vXbfZvV8=:185D^FO0,608^GFA,09216,09216,00072,:Z64:\neJzt2DEVACAMQ8Fu2EYqTkBEs9B3X8ANGVMlSZK63UR7rnMCGy8Oh8PhcDgcDofD4XA4HA7nUyf1s011JElSvwcBgIlT:9B3D^FO0,704^GFA,11776,11776,00092,:Z64:\neJzt2aERACAQA8Evm7KRODA4sBE/s1fAmshU9WzHWuyPPWNLDjabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2ddOfv/s15YkSZI6dgABKlDe:FE9A^FO352,64^GFA,06144,06144,00048,:Z64:\neJzt10uOnDAQBmBbLFhyBF8kCleaZRZRY2kOkqPEN8gVmBuQnaVBVOovmzYPQyCaTtIS1sht4IP2YLvKrdRVnqxUdLj0l7/8v/WqUc38mKsWrjzuHVxx3NuTXp3zw0nvH+zbB3v7WB9e5+O8//veq7ESP6ga1lbiu7W3ymCWl9G3aOG54t3KDzjiSkdv0cKw1jT2zk+9B0U3G/GDtPDcyqnQtblHDxtUtfheWlglZd6jhzVmlRHfSQvfUuQ9Johx0oZvpYWLOu/xYXBTKd5Jq0teBiH5QWmvaqVwLniyBfvKFhue+3HjR1ot3pbUFvw6yZdZ3/M5h6pT4vmU1+Q09VXWez7+2cvJ4Gu+Qo7HmN9XTRlP9I6qF32TGSSz51uMV3PfYfS5B6ym3sT5ufbcDBW/pUZ9jfO03vItZmOHyorXR7xU1oze3sLMzHosAalc8p8P+y9F8PRR3i28LL89b4TKTXf/6azXf+qxMNQzebx/6n/jWzMbL8zoTZ8Z37Uvd+fDGa+Db+a+2p3/Ex/HN3lZWov1SLRcX83u+t316/hAP1bxgbbjDz/5VeLP9w3f0Ns0vnHw12N8+wDfM3BS3eMt4ifibfJl8gPyBOK5ivEcwZ+zTNOVyZvkOb90yBcvKV/wH+cLOc54jPgkH7VqzK86+XrpnRrzHTJXEfJd3uOBk3zq5Zskn+Z9Jl+HrJn+33eaeNkP4CDuH+ROZHGT94Ps1mULEvcbGJ027CfGSTTx/CiDatw6dbiTr2qal7RfwpX+fjnul9zyp8cT/N65/OX/L3+Vq1zlKtnyC7+HEQk=:C478^BY4,3,160^FT50,1068^BCN,,Y,N^FD>;8900>60JX>553713012^FS^FT31,390^A0N,51,50^FH\^FDNRHT^FS^FT193,455^A0N,28,28^FH\^FDNN4 5EL^FS^FT96,764^A0N,28,28^FH\^FDStorekeeper instruction: GIVE TO DRIVER^FS^FT578,668^A0N,51,50^FH\^FD72 HR^FS^FT94,682^A0N,28,28^FH\^FDParcel label for ECPABCDEFGH^FS^FT33,439^A0N,20,19^FH\^FDCreation Date: ^FS^FT33,463^A0N,20,19^FH\^FD06-06-2019^FS^FT589,556^A0N,102,100^FH\^FD72^FS^FT560,328^A0N,102,100^FH\^FD02A^FS^FT93,517^A0N,25,24^FH\^FDClick & Collect your online purchases ^FS^FT93,548^A0N,25,24^FH\^FD      to your local Collect+ store^FS^FT93,610^A0N,25,24^FH\^FDwww.collectplus.co.uk/services^FS^FT42,303^A0N,102,100^FH\^FD12^FS^FT190,225^A0N,28,28^FH\^FDJohn Lewis^FS^FT190,259^A0N,28,28^FH\^FDClipper Logistics^FS^FT190,293^A0N,28,28^FH\^FDUnit 1, Saxon Avenue,^FS^FT190,327^A0N,28,28^FH\^FDGrange Park^FS^FT190,361^A0N,28,28^FH\^FDNorthampton^FS^FT190,395^A0N,28,28^FH\^FDNorthamptonshire^FS^PQ1,0,1,Y^XZ";
        _writeCharacteristic = characteristic;
        self.writeCharacteristic = characteristic;
        NSLog(@"write characteristic: %@ %@",self.writeCharacteristic,_writeCharacteristic);
            
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:READ_FROM_ZPRINTER_CHARACTERISTIC_UUID]]) {
            NSLog(@"read characteristic called");
            // Set up notification for value update on "From Printer Data" characteristic, i.e. READ_FROM_ZPRINTER_CHARACTERISTIC_UUID.
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];

        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_MODEL_NAME]] ||
                   [characteristic.UUID isEqual:[CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_SERIAL_NUMBER]] ||
                   [characteristic.UUID isEqual:[CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_FIRMWARE_REVISION]] ||
                   [characteristic.UUID isEqual:[CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_HARDWARE_REVISION]] ||
                   [characteristic.UUID isEqual:[CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_SOFTWARE_REVISION]] ||
                   [characteristic.UUID isEqual:[CBUUID UUIDWithString:ZPRINTER_DIS_CHARAC_MANUFACTURER_NAME]]) {
            
            // These characteristics are read-only characteristics.
            // Read value for these DIS characteristics
            NSLog(@"otherwise called");
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in or to send ZPL to printer.
}


/*!
 *  @method peripheral:didDiscoverCharacteristicsForService:error:
 *
 *  @param peripheral    The peripheral providing this information.
 *  @param service        The <code>CBService</code> object containing the characteristic(s).
 *    @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion            This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully,
 *                        they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
 */

/*!
 *  @method peripheral:didWriteValueForCharacteristic:error:
 *
 *  @param peripheral        The peripheral providing this information.
 *  @param characteristic    A <code>CBCharacteristic</code> object.
 *    @param error            If an error occurred, the cause of the failure.
 *
 *  @discussion                This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    if (error) {
        NSLog(@"Error in writing bluetooth: %@",error);
        _printerSuccess=false;
        self.printerSuccess=false;
      if (self.printRejectBlock) {
        self.printRejectBlock(@"",@"",error);
        self.printRejectBlock=nil;
        self.printResolveBlock=nil;
      }
        if (writeDataDelegate) {
            [writeDataDelegate didWriteDataToBle:false];
        }
    }
    else {
        NSLog(@"print resolved");
        _printerSuccess=true;
        self.printerSuccess=true;
      if (printCompleted == YES && self.printResolveBlock) {
        NSLog(@"print resloved");  
        RCTPromiseResolveBlock rsBlock = self.printResolveBlock;
        rsBlock(@"true");
        self.printResolveBlock = nil;
        self.printRejectBlock=nil;
        printCompleted= NO;
      }
    
    }
    if (writeDataDelegate) {
        [writeDataDelegate didWriteDataToBle:true];
    }
}
// This callback retrieves the values of the characteristics when they are updated.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Deal with errors (if any)
  NSLog(@"didUpdateValueForCharacteristic");
  NSLog(@"print resolved done");
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    // Send read notification
    if ([characteristic.UUID.UUIDString isEqual:READ_FROM_ZPRINTER_CHARACTERISTIC_UUID]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ZPRINTER_READ_NOTIFICATION object:self
                                                          userInfo:@{@"Value":characteristic.value}];
    }
    // Check the UUID of characteristic is equial to the UUID of DIS characteristics
    else if ([characteristic.UUID.UUIDString isEqual:ZPRINTER_DIS_CHARAC_MODEL_NAME] ||
             [characteristic.UUID.UUIDString isEqual:ZPRINTER_DIS_CHARAC_SERIAL_NUMBER] ||
             [characteristic.UUID.UUIDString isEqual:ZPRINTER_DIS_CHARAC_FIRMWARE_REVISION] ||
             [characteristic.UUID.UUIDString isEqual:ZPRINTER_DIS_CHARAC_HARDWARE_REVISION] ||
             [characteristic.UUID.UUIDString isEqual:ZPRINTER_DIS_CHARAC_SOFTWARE_REVISION] ||
             [characteristic.UUID.UUIDString isEqual:ZPRINTER_DIS_CHARAC_MANUFACTURER_NAME]) {
     
        // Send DIS notification
        [[NSNotificationCenter defaultCenter] postNotificationName:ZPRINTER_DIS_NOTIFICATION object:self
                                                          userInfo:@{@"Characteristic":characteristic.UUID.UUIDString,
                                                                     @"Value":characteristic.value}];
    }
    
}


// The peripheral letting us know whether our subscribe/unsubscribe happened or not
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Deal with errors
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
        return;
    }
    // Exit if it's not the TRANSFER_CHARACTERISTIC_UUID characteristic, as it's our only interest at this time.
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:READ_FROM_ZPRINTER_CHARACTERISTIC_UUID]]) {
        return;
    }
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

 
@end
