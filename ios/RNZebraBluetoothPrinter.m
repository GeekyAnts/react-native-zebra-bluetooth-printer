//
//  ZebraAPI.m
//  CollectPlusStoreScan
//
//  Created by Anmol Jain on 26/08/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

// #import "ZebraAPI.h"
// #import <React/RCTLog.h>

// @implementation ZebraAPI

// RCT_EXPORT_MODULE();

// RCT_EXPORT_METHOD(addEvent:(NSString *)name location:(NSString *)location)
// {
 
//   RCTLogInfo(@"Pretending to createan event %@ at %@", name, location);
// }

// @end
#import <Foundation/Foundation.h>
#import "RNZebraBluetoothPrinter.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "ZPrinterLEService.h"
#import "React/RCTEventDispatcher.h"

@implementation RNZebraBluetoothPrinter;
NSString *EVENT_DEVICE_ALREADY_PAIRED = @"EVENT_DEVICE_ALREADY_PAIRED";
NSString *EVENT_DEVICE_DISCOVER_DONE = @"EVENT_DEVICE_DISCOVER_DONE";
NSString *EVENT_DEVICE_FOUND = @"EVENT_DEVICE_FOUND";
NSString *EVENT_CONNECTION_LOST = @"EVENT_CONNECTION_LOST";
NSString *EVENT_UNABLE_CONNECT=@"EVENT_UNABLE_CONNECT";
NSString *EVENT_CONNECTED=@"EVENT_CONNECTED";

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


RCT_EXPORT_MODULE(RNZebraBluetoothPrinter);

RCT_EXPORT_METHOD(print:(NSString*)zpl
                  zplArrayLength:(NSUInteger*)zplArrayLength
                  index:(NSUInteger*)index
                  findEventsWithResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"print called %@",_writeCharacteristic);
    NSLog(@"print calles %@",_printer);
//   NSString *zpl= @"CT~~CD,~CC^~CT~\n^XA~TA000~JSN^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR6,6~SD15^JUS^LRN^CI0^XZ\n^XA\n^MMT\n^PW734\n^LL1231\n^LS0\n^FO0,768^GFA,38272,38272,00092,:Z64:\neJzs0aERADAIADEG6/AM1rvWIjAIXH6AmI+QJEmSVHtrXXZj59rJw2az2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZo/sDwAA///t3SEBAAAAwrD+rQmARrEHWIWz2Ww2m81ms7/s5ced3bYkSZK+CxLzLNk=:2676\n^FO544,384^GFA,08448,08448,00024,:Z64:\neJzt2bENACAMA8F0LMVwDI4EC6SJFKjuy2s8gCOk/sbJ2n2+stXJOeecc84555xzzjnnnHPOOa/4419P+tkF6t+Orw==:613B\n^FO0,384^GFA,03072,03072,00024,:Z64:\neJxjYBgFo4B88B8reEA18QfYLGUcFR8VHxUfFR8VHxVHFad1fTQKRsFwAgDs9Soi:881A\n^FO0,64^GFA,11776,11776,00092,:Z64:\neJzt2kENACAQA8HzrxIJOAAB8LqkISGzAubTb6skdVqxJvtij9iSbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2W/s5NeCfdqSJP3SBqioe54=:6F90\n^FO160,384^GFA,06656,06656,00052,:Z64:\neJzt16ENACAMRNEyAftvxyZgcU1NQ8j7/omTFyFJnzZ2refNKs2fDMMwDMMwDMMwTGK6/lyTkSTp6gCtY7SA:79AF\n^FO160,160^GFA,13312,13312,00052,:Z64:\neJzt2rENACAMA8F0rM3I2QDECGkiBPf9Fe4dIZ1WrXm7ydL6wTAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzBfm66/f5d5qw1iM9Ft:54B5\n^FO0,160^GFA,23552,23552,00092,:Z64:\neJzt3DENACAUQ8EvDP86EEICAmAiKSz3BNzSvVWSbpqxBvtg99iSjc1ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZn+wk3+m7N3W2xZx7Nny:39B6\n^FO0,448^GFA,13824,13824,00072,:Z64:\neJzt2jENADAMA8EwKH+WZdBS6OBIVXQP4AbPrpIkSertJBrs7MDGi8PhcDgcDofD4XA4HA6Hw+FwOBwOh8PhcDgcDofD4XA4HA6Hw3l0Uj/Yqc5vXbfZvV8=:185D\n^FO0,608^GFA,09216,09216,00072,:Z64:\neJzt2DEVACAMQ8Fu2EYqTkBEs9B3X8ANGVMlSZK63UR7rnMCGy8Oh8PhcDgcDofD4XA4HA7nUyf1s011JElSvwcBgIlT:9B3D\n^FO0,704^GFA,11776,11776,00092,:Z64:\neJzt2aERACAQA8Evm7KRODA4sBE/s1fAmshU9WzHWuyPPWNLDjabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2ddOfv/s15YkSZI6dgABKlDe:FE9A\n^FO352,64^GFA,06144,06144,00048,:Z64:\neJzt10uOnDAQBmBbLFhyBF8kCleaZRZRY2kOkqPEN8gVmBuQnaVBVOovmzYPQyCaTtIS1sht4IP2YLvKrdRVnqxUdLj0l7/8v/WqUc38mKsWrjzuHVxx3NuTXp3zw0nvH+zbB3v7WB9e5+O8//veq7ESP6ga1lbiu7W3ymCWl9G3aOG54t3KDzjiSkdv0cKw1jT2zk+9B0U3G/GDtPDcyqnQtblHDxtUtfheWlglZd6jhzVmlRHfSQvfUuQ9Johx0oZvpYWLOu/xYXBTKd5Jq0teBiH5QWmvaqVwLniyBfvKFhue+3HjR1ot3pbUFvw6yZdZ3/M5h6pT4vmU1+Q09VXWez7+2cvJ4Gu+Qo7HmN9XTRlP9I6qF32TGSSz51uMV3PfYfS5B6ym3sT5ufbcDBW/pUZ9jfO03vItZmOHyorXR7xU1oze3sLMzHosAalc8p8P+y9F8PRR3i28LL89b4TKTXf/6azXf+qxMNQzebx/6n/jWzMbL8zoTZ8Z37Uvd+fDGa+Db+a+2p3/Ex/HN3lZWov1SLRcX83u+t316/hAP1bxgbbjDz/5VeLP9w3f0Ns0vnHw12N8+wDfM3BS3eMt4ifibfJl8gPyBOK5ivEcwZ+zTNOVyZvkOb90yBcvKV/wH+cLOc54jPgkH7VqzK86+XrpnRrzHTJXEfJd3uOBk3zq5Zskn+Z9Jl+HrJn+33eaeNkP4CDuH+ROZHGT94Ps1mULEvcbGJ027CfGSTTx/CiDatw6dbiTr2qal7RfwpX+fjnul9zyp8cT/N65/OX/L3+Vq1zlKtnyC7+HEQk=:C478\n^BY4,3,160^FT50,1068^BCN,,Y,N\n^FD>;8900>60JX>553713012^FS\n^FT31,390^A0N,51,50^FH\^FDNRHT^FS\n^FT193,455^A0N,28,28^FH\^FDNN4 5EL^FS\n^FT96,764^A0N,28,28^FH\^FDStorekeeper instruction: GIVE TO DRIVER^FS\n^FT578,668^A0N,51,50^FH\^FD72 HR^FS\n^FT94,682^A0N,28,28^FH\^FDParcel label for ECPABCDEFGH^FS\n^FT33,439^A0N,20,19^FH\^FDCreation Date: ^FS\n^FT33,463^A0N,20,19^FH\^FD06-06-2019^FS\n^FT589,556^A0N,102,100^FH\^FD72^FS\n^FT560,328^A0N,102,100^FH\^FD02A^FS\n^FT93,517^A0N,25,24^FH\^FDClick & Collect your online purchases ^FS\n^FT93,548^A0N,25,24^FH\^FD      to your local Collect+ store^FS\n^FT93,610^A0N,25,24^FH\^FDwww.collectplus.co.uk/services^FS\n^FT42,303^A0N,102,100^FH\^FD12^FS\n^FT190,225^A0N,28,28^FH\^FDJohn Lewis^FS\n^FT190,259^A0N,28,28^FH\^FDClipper Logistics^FS\n^FT190,293^A0N,28,28^FH\^FDUnit 1, Saxon Avenue,^FS\n^FT190,327^A0N,28,28^FH\^FDGrange Park^FS\n^FT190,361^A0N,28,28^FH\^FDNorthampton^FS\n^FT190,395^A0N,28,28^FH\^FDNorthamptonshire^FS\n^PQ1,0,1,Y^XZ";

    // NSString *zpl=@"^XA ^LT120^FX Top section^CFB,25^FO50,173^FDFROM:^FS^FO200,173^FDTest sender^FS^FO200,228^FD10 MOUNTAIN PKWY^FS^FO200,283^FDTN, COLLIERVILLE, 38017^FS^FO50,343^GB706,1,3^FS^FX Second section with recipient address^CFB,25^FO50,363^FDTO:^FS^FO200,363^FDJohn Smith^FS^FO200,423^FDAccounts Payable Dept.^FS^FO200,473^FD123 Market Street^FS^FO200,523^FDTX, Dallas, 75270^FS^FO50,4830^GB706,1,3^FS^FX Third section with shipment numbers^CFB,25^FO60,593^FDPO#^FS^FO230,593^FB542,1,0,N,0^FD0001234^FS^FO60,623^FDDept.^FS^FO230,653^FB542,1,0,N,0^FD^FS^FO60,723^FDStore^FS^FO230,723^FB542,1,0,N,0^FDMAIN BRANCH^FS^FO60,823^FDDuns#^FS^FO230,823^FB542,1,0,N,0^FD123123123^FS^FO50,873^GB706,1,3^FS^FX Fourth section with package description^CFB,25^FO60,893^FB692,5,4,N,0^FDPRODUCT A x 1, PRODUCT B x 4\&^FS^FX Fifth section with Box counter^CFB,25^FO60,1000^FB692,1,0,C,0^FDBox 1 of 1^FS^FO60,1000^FB692,1,0,C,0^FD__________^FS^FO60,1000^FB692,1,0,C,0^FD__________^FS^XZ";      
//   NSString * zpl=@"^XA\n^FX Top section with company logo, name and address.\n^CF0,60\n^FO50,50^GB100,100,100^FS\n^FO75,75^FR^GB100,100,100^FS\n^FO88,88^GB50,50,50^FS\n^FO220,50^FDInternational Shipping, Inc.^FS\n^CF0,40\n^FO220,100^FD1000 Shipping Lane^FS\n^FO220,135^FDShelbyville TN 38102^FS\n^FO220,170^FDUnited States (USA)^FS\n^FO50,250^GB700,1,3^FS\n^FX Third section with barcode.\n^BY5,2,270\n^FO100,550^BC^FD12345678^FS\n^FO100,60^A0N,25,25^FB400,2,10,C,0^FDAlex Kuzmenya.Hello World !!!! Alex Kuzmenya. long ling 231^FS^\n^FX Fourth section (the two boxes on the bottom).^FO50,900^GB700,250,3^FS^FO400,900^GB1,250,3^FS^CF0,40^FO100,960^FDShipping Ctr. X34B-1^FS^FO100,1010^FDREF1 F00B47^FS^FO100,1060^FDREF2 BL4H8^FS^CF0,190^FO485,965^FDCA^FS\n^XZ";
//   NSString * zpl=@"^XA^FO100,60^A0N,25,25^FB400,2,10,C,0^FDAlex Kuzmenya. Hello World !!!! Alex Kuzmenya. long ling 231^FS^XZ";
// NSString *zpl =@"CT~~CD,~CC^~CT~\n^XA~TA000~JSN^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR6,6~SD15^JUS^LRN^CI0\n^MMT\n^PW734\n ^LL1231\n^LS0\n^BY4,3,160^FT50,1068^BCN,,Y,N\n^FT190,225^A0N,28,28^FH\^FDJohn Lewis^FS\n^FT190,259^A0N,28,28^FH\^FDClipper Logistics^FS\n^FT190,293^A0N,28,28^FH\^FDUnit 1, Saxon Avenue,^FS\n^FT190,327^A0N,28,28^FH\^FDGrange Park^FS\n^FT190,361^A0N,28,28^FH\^FDNorthampton^FS\n^FT190,395^A0N,28,28^FH\^FDNorthamptonshire^FS\n^PQ1,0,1,Y^XZ";
// NSString *zpl =@"CT~~CD,~CC^~CT~\n^XA~TA000~JSN^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR6,6~SD15^JUS^LRN^CI0\n^MMT\n^PW734\n ^LL1231\n^LS0\n^BY4,3,160^FT50,1068^BCN,,Y,N\n^FT190,225^A0N,28,28^FH\^FDJohn Lewis^FS\n^FT190,259^A0N,28,28^FH\^FDClipper Logistics^FS\n^FT190,293^A0N,28,28^FH\^FDUnit 1, Saxon Avenue,^FS\n^FT190,327^A0N,28,28^FH\^FDGrange Park^FS\n^FT190,361^A0N,28,28^FH\^FDNorthampton^FS\n^FT190,395^A0N,28,28^FH\^FDNorthamptonshire^FS\n^PQ1,0,1,Y^XZ";
// NSString *zpl =@"CT~~CD,~CC^~CT~^XA~TA000~JSN^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR6,6~SD15^JUS^LRN^CI0^MMT^PW734 ^LL1231^LS0^BY4,3,160^FT50,1068^BCN,,Y,N^FT190,225^A0N,28,28^FH\^FDJohn Lewis^FS^FT190,259^A0N,28,28^FH\^FDClipper Logistics^FS^FT190,293^A0N,28,28^FH\^FDUnit 1, Saxon Avenue,^FS^FT190,327^A0N,28,28^FH\^FDGrange Park^FS^FT190,361^A0N,28,28^FH\^FDNorthampton^FS^FT190,395^A0N,28,28^FH\^FDNorthamptonshire^FS^PQ1,0,1,Y^XZ";


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
 
   NSLog(@"chunk:%@",chunk);
   NSLog(@"chunk:%@",chunk);
   NSLog(@"chunk:%@",chunk);
   NSLog(@"chunk:%@",chunk);
} while (offset < length);
    // NSData *payload =[[NSData alloc] initWithBase64EncodedString:zpl options:NSDataBase64DecodingIgnoreUnknownCharacters];
 NSLog(@"Writing payload: %@ length of %zu", payload, length);
   NSLog(@"inde is %zd and zp is %zd",index,zplArrayLength);

     NSLog(@"index is %zd and zpl is %zd",index,zplArrayLength);
  printCompleted=YES;

//   NSString*zpl= @"CT~~CD,~CC^~CT~\n^XA~TA000~JSN^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR6,6~SD15^JUS^LRN^CI0^XZ\n^XA\n^MMT\n^PW734\n^LL1231\n^LS0\n^FO0,768^GFA,38272,38272,00092,:Z64:\neJzs0aERADAIADEG6/AM1rvWIjAIXH6AmI+QJEmSVHtrXXZj59rJw2az2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZo/sDwAA///t3SEBAAAAwrD+rQmARrEHWIWz2Ww2m81ms7/s5ced3bYkSZK+CxLzLNk=:2676\n^FO544,384^GFA,08448,08448,00024,:Z64:\neJzt2bENACAMA8F0LMVwDI4EC6SJFKjuy2s8gCOk/sbJ2n2+stXJOeecc84555xzzjnnnHPOOa/4419P+tkF6t+Orw==:613B\n^FO0,384^GFA,03072,03072,00024,:Z64:\neJxjYBgFo4B88B8reEA18QfYLGUcFR8VHxUfFR8VHxVHFad1fTQKRsFwAgDs9Soi:881A\n^FO0,64^GFA,11776,11776,00092,:Z64:\neJzt2kENACAQA8HzrxIJOAAB8LqkISGzAubTb6skdVqxJvtij9iSbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2W/s5NeCfdqSJP3SBqioe54=:6F90\n^FO160,384^GFA,06656,06656,00052,:Z64:\neJzt16ENACAMRNEyAftvxyZgcU1NQ8j7/omTFyFJnzZ2refNKs2fDMMwDMMwDMMwTGK6/lyTkSTp6gCtY7SA:79AF\n^FO160,160^GFA,13312,13312,00052,:Z64:\neJzt2rENACAMA8F0rM3I2QDECGkiBPf9Fe4dIZ1WrXm7ydL6wTAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzAMwzBfm66/f5d5qw1iM9Ft:54B5\n^FO0,160^GFA,23552,23552,00092,:Z64:\neJzt3DENACAUQ8EvDP86EEICAmAiKSz3BNzSvVWSbpqxBvtg99iSjc1ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2Ww2m81ms9lsNpvNZn+wk3+m7N3W2xZx7Nny:39B6\n^FO0,448^GFA,13824,13824,00072,:Z64:\neJzt2jENADAMA8EwKH+WZdBS6OBIVXQP4AbPrpIkSertJBrs7MDGi8PhcDgcDofD4XA4HA6Hw+FwOBwOh8PhcDgcDofD4XA4HA6Hw3l0Uj/Yqc5vXbfZvV8=:185D\n^FO0,608^GFA,09216,09216,00072,:Z64:\neJzt2DEVACAMQ8Fu2EYqTkBEs9B3X8ANGVMlSZK63UR7rnMCGy8Oh8PhcDgcDofD4XA4HA7nUyf1s011JElSvwcBgIlT:9B3D\n^FO0,704^GFA,11776,11776,00092,:Z64:\neJzt2aERACAQA8Evm7KRODA4sBE/s1fAmshU9WzHWuyPPWNLDjabzWaz2Ww2m81ms9lsNpvNZrPZbDabzWaz2ddOfv/s15YkSZI6dgABKlDe:FE9A\n^FO352,64^GFA,06144,06144,00048,:Z64:\neJzt10uOnDAQBmBbLFhyBF8kCleaZRZRY2kOkqPEN8gVmBuQnaVBVOovmzYPQyCaTtIS1sht4IP2YLvKrdRVnqxUdLj0l7/8v/WqUc38mKsWrjzuHVxx3NuTXp3zw0nvH+zbB3v7WB9e5+O8//veq7ESP6ga1lbiu7W3ymCWl9G3aOG54t3KDzjiSkdv0cKw1jT2zk+9B0U3G/GDtPDcyqnQtblHDxtUtfheWlglZd6jhzVmlRHfSQvfUuQ9Johx0oZvpYWLOu/xYXBTKd5Jq0teBiH5QWmvaqVwLniyBfvKFhue+3HjR1ot3pbUFvw6yZdZ3/M5h6pT4vmU1+Q09VXWez7+2cvJ4Gu+Qo7HmN9XTRlP9I6qF32TGSSz51uMV3PfYfS5B6ym3sT5ufbcDBW/pUZ9jfO03vItZmOHyorXR7xU1oze3sLMzHosAalc8p8P+y9F8PRR3i28LL89b4TKTXf/6azXf+qxMNQzebx/6n/jWzMbL8zoTZ8Z37Uvd+fDGa+Db+a+2p3/Ex/HN3lZWov1SLRcX83u+t316/hAP1bxgbbjDz/5VeLP9w3f0Ns0vnHw12N8+wDfM3BS3eMt4ifibfJl8gPyBOK5ivEcwZ+zTNOVyZvkOb90yBcvKV/wH+cLOc54jPgkH7VqzK86+XrpnRrzHTJXEfJd3uOBk3zq5Zskn+Z9Jl+HrJn+33eaeNkP4CDuH+ROZHGT94Ps1mULEvcbGJ027CfGSTTx/CiDatw6dbiTr2qal7RfwpX+fjnul9zyp8cT/N65/OX/L3+Vq1zlKtnyC7+HEQk=:C478\n^BY4,3,160^FT50,1068^BCN,,Y,N\n^FD>;8900>60JX>553713012^FS\n^FT31,390^A0N,51,50^FH\^FDNRHT^FS\n^FT193,455^A0N,28,28^FH\^FDNN4 5EL^FS\n^FT96,764^A0N,28,28^FH\^FDStorekeeper instruction: GIVE TO DRIVER^FS\n^FT578,668^A0N,51,50^FH\^FD72 HR^FS\n^FT94,682^A0N,28,28^FH\^FDParcel label for ECPABCDEFGH^FS\n^FT33,439^A0N,20,19^FH\^FDCreation Date: ^FS\n^FT33,463^A0N,20,19^FH\^FD06-06-2019^FS\n^FT589,556^A0N,102,100^FH\^FD72^FS\n^FT560,328^A0N,102,100^FH\^FD02A^FS\n^FT93,517^A0N,25,24^FH\^FDClick & Collect your online purchases ^FS\n^FT93,548^A0N,25,24^FH\^FD      to your local Collect+ store^FS\n^FT93,610^A0N,25,24^FH\^FDwww.collectplus.co.uk/services^FS\n^FT42,303^A0N,102,100^FH\^FD12^FS\n^FT190,225^A0N,28,28^FH\^FDJohn Lewis^FS\n^FT190,259^A0N,28,28^FH\^FDClipper Logistics^FS\n^FT190,293^A0N,28,28^FH\^FDUnit 1, Saxon Avenue,^FS\n^FT190,327^A0N,28,28^FH\^FDGrange Park^FS\n^FT190,361^A0N,28,28^FH\^FDNorthampton^FS\n^FT190,395^A0N,28,28^FH\^FDNorthamptonshire^FS\n^PQ1,0,1,Y^XZ";
 
}


//isBluetoothEnabled
RCT_EXPORT_METHOD(isBluetoothEnabled:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    CBManagerState state = [self.centralManager  state];
    resolve(state == CBManagerStatePoweredOn?@"true":@"false");//canot pass boolean or int value to resolve directly.
}
RCT_EXPORT_METHOD(printSuccess:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    resolve(self.printerSuccess == true?@"true":@"false");//canot pass boolean or int value to resolve directly.
}
//enableBluetooth
RCT_EXPORT_METHOD(enableBluetooth:(RCTPromiseResolveBlock)resolve
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


//scanDevices
RCT_EXPORT_METHOD(scanDevices:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{

    @try{
        CBUUID *deviceInfoUUID = [CBUUID UUIDWithString: @"0C347F9F-2881-9CCB-43B0-205976944626"];
         NSArray<CBPeripheral*> *connectedDevices=[self.centralManager retrieveConnectedPeripheralsWithServices:@[deviceInfoUUID]];
         NSLog(@"arrayOf %d",[connectedDevices count]);
     for(CBPeripheral *p in connectedDevices) {
          NSLog(@"ggg");
        }
        if (!self.centralManager || self.centralManager.state!=CBManagerStatePoweredOn) {
            reject(@"BLUETOOTCH_INVALID_STATE",@"BLUETOOTCH_INVALID_STATE",nil);
            return;
        }
        if (self.centralManager.isScanning) {
            [self.centralManager stopScan];
        }
        self.scanResolveBlock = resolve;
        self.scanRejectBlock = reject;
        NSLog(@"devices:");
        NSLog(@"connectedValue %@",connected);
        if (connected && connected.identifier) {
            NSLog(@"values%@",connected);
            BOOL state= connected.state;
            NSString *status;
            if (state) {
                status=@"connected";
            }
            else
            {
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

//stop scan
RCT_EXPORT_METHOD(stopScan:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self callStop];
    resolve(nil);
}
RCT_EXPORT_METHOD(getPairedDevices:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSMutableArray *serviceUUIDs = [NSMutableArray new];
    CBUUID *serviceUUID =[CBUUID UUIDWithString:@"38EB4A82-C570-11E3-9507-0002A5D5C51B"];
    [serviceUUIDs addObject:serviceUUID];
     NSArray *connectedPeripherals = [self.centralManager retrieveConnectedPeripheralsWithServices:serviceUUIDs];
     NSLog(@"PairedD: %zd",[connectedPeripherals count]);
    resolve(nil);
}
//connect(address)
RCT_EXPORT_METHOD(connect:(NSString *)address
                  findEventsWithResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Trying to connect....%@",address);
    [self callStop];
    // if(connected){
    //     NSString *connectedAddress =connected.identifier.UUIDString;
    //     NSLog(@"String is:%@",connectedAddress);
    //     if([address isEqualToString:connectedAddress]){
    //         NSLog(@"peripheralConnected %@",connected.name);
    //         resolve(nil);
    //         return;
    //     }else{
    //         NSLog(@"peripheralConnectionCanceled");
    //         [self.centralManager cancelPeripheralConnection:connected];
    //         //Callbacks:
    //         //entralManager:didDisconnectPeripheral:error:
    //     }
    // }
    CBPeripheral *peripheral = [self.foundDevices objectForKey:address];
    self.connectResolveBlock = resolve;
    self.connectRejectBlock = reject;
    if(peripheral){
          _waitingConnect = address;
          NSLog(@"Trying to connectPeripheral....%@",address);
        [self.centralManager connectPeripheral:peripheral options:nil];
         [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(discoverWriteCharacteristic:)
                                                 name:ZPRINTER_WRITE_NOTIFICATION
                                               object:nil];

    // Register for notification on data received from Read Characteristic
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedDataFromReadCharacteristic:)
                                                 name:ZPRINTER_READ_NOTIFICATION
                                               object:nil];

    //////////////////////////////////////////////////////////
    // Register for notification on DIS values received from DIS Characteristic
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedDataFromDISCharacteristic:)
                                                 name:ZPRINTER_DIS_NOTIFICATION
                                               object:nil];
   
    
        // Callbacks:
        //    centralManager:didConnectPeripheral:
        //    centralManager:didFailToConnectPeripheral:error:
    }else{
          //starts the scan.
        _waitingConnect = address;
         NSLog(@"Scan to find ....%@",address);
        [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        //Callbacks:
        //centralManager:didDiscoverPeripheral:advertisementData:RSSI:
    }
}
//unpaire(address)
- (void)discoverWriteCharacteristic:(NSNotification *) notification {
    NSLog(@"called write function");
    // Set the writeCharacteristic
    self.writeCharacteristic = [notification userInfo][@"Characteristic"];

    // Update the title to connected
    // self.title = @"Connected";

    // Enable the send button
  
}

// This callback is called when data from READ_FROM_ZPRINTER_CHARACTERISTIC_UUID is received.
- (void)receivedDataFromReadCharacteristic:(NSNotification *) notification {
    
    // Extract the data from notification
    [self.data appendData:[notification userInfo][@"Value"]];

    // Display data in statusTextview
    // [self.statusTextview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];

    // Scroll the textview to the bottom.
    // NSRange bottom = NSMakeRange(self.statusTextview.text.length - 1, 1);
    // [self.statusTextview scrollRangeToVisible:bottom];
}

// This callback is called when data from DIS is received.
- (void)receivedDataFromDISCharacteristic:(NSNotification *) notification {

    // Extract Characteristic UUID & text
    NSString *uuid = [notification userInfo][@"Characteristic"];
    NSData *value = [notification userInfo][@"Value"];
    NSString *text = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];

    // Set the corresponding fields
    if ([uuid isEqual:ZPRINTER_DIS_CHARAC_MODEL_NAME]) {
        self.disName.text = text;
    } else if ([uuid isEqual:ZPRINTER_DIS_CHARAC_SERIAL_NUMBER]) {
        self.disSerialNumber.text = text;
    } else if ([uuid isEqual:ZPRINTER_DIS_CHARAC_FIRMWARE_REVISION]) {
        self.disFirmwareRevision.text = text;
    } else if ([uuid isEqual:ZPRINTER_DIS_CHARAC_HARDWARE_REVISION]) {
        self.disHardwareRevision.text = text;
    } else if ([uuid isEqual:ZPRINTER_DIS_CHARAC_SOFTWARE_REVISION]) {
        self.disSoftwareRevision.text = text;
    } else if ([uuid isEqual:ZPRINTER_DIS_CHARAC_MANUFACTURER_NAME]) {
        self.disManufacturerName.text = text;
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
            } else
            {
                
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

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"did connected: %@",peripheral);
    connected = peripheral;
    NSString *pId = peripheral.identifier.UUIDString;
    if(_waitingConnect && [_waitingConnect isEqualToString: pId] && self.connectResolveBlock){
        NSLog(@"Predefined the support services, stop to looking up services.");
      //  peripheral.delegate=self;
//        [peripheral discoverServices:nil];
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

/**
 * END OF CBCentralManagerDelegate
 **/

/*!
 *  @method peripheral:didDiscoverServices:
 *
 *  @param peripheral    The peripheral providing this information.
 *    @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion            This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
 *                        <i>peripheral</i>'s @link services @/link property.
 *
 */

// The Zebra Printer Service was discovered
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
        _writeCharacteristic=characteristic;
        self.writeCharacteristic=characteristic;
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
    else
    {
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
