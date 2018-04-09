//
//  CLONNBluetoothClientService.m
//  CLONearNetworking
//
//  Created by Cc on 2018/4/9.
//

#import "CLONNBluetoothClientService.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "CLONNSendDataWriter.h"
#import "CLONNReceiveDataReader.h"

@interface CLONNBluetoothClientService()
<
    CBPeripheralManagerDelegate
>

@property (strong, nonatomic) CBUUID *pServiceUUID;
@property (strong, nonatomic) CBUUID *pCharacteristicUUID;
@property (strong, nonatomic) CBUUID *pCharacteristicWriteUUID;

@property (strong, nonatomic) CBPeripheralManager *pPeripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *pMutableCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *pMutableCharacteristicRR;

/// 这个是正在发送的对象，当有值时就开始发送它，如果它为nil表示已经完成
@property (strong, nonatomic) CLONNSendDataWriter *pSendDataWriter;

/// 收到的消息
@property (strong, nonatomic) CLONNReceiveDataReader *pReceiveDataReader;

@property (assign, nonatomic) int kLenSize;

@end
@implementation CLONNBluetoothClientService


- (instancetype)initWithServiceUUID:(CBUUID *)serviceUUID withCharacteristicUUID:(CBUUID *)characteristicUUID withCharacteristicWriteUUID:(CBUUID *)characteristicWriteUUID
{
    self = [super init];
    if (self) {
        
        _pServiceUUID = serviceUUID;
        _pCharacteristicUUID = characteristicUUID;
        _pCharacteristicWriteUUID = characteristicWriteUUID;
        
        _kLenSize = 64;
    }
    return self;
}


- (void)dealloc
{
    [self fReleaseBluetoothClient];
}


- (void)fInitBluetoothClient
{
    if (!self.pPeripheralManager) {
        
        self.pPeripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
}


- (void)fReleaseBluetoothClient
{
    if (self.pPeripheralManager) {
        
        [self.pPeripheralManager stopAdvertising];
        self.pPeripheralManager.delegate = nil;
        self.pPeripheralManager = nil;
        
        self.pMutableCharacteristic = nil;
    }
}


- (void)fInitMutableCharacteristic
{
    if (!self.pMutableCharacteristic) {
        
        self.pMutableCharacteristic = [[CBMutableCharacteristic alloc] initWithType:self.pCharacteristicUUID
                                                                         properties:CBCharacteristicPropertyNotify
                                                                              value:nil
                                                                        permissions:CBAttributePermissionsWriteEncryptionRequired];
        
        self.pMutableCharacteristicRR = [[CBMutableCharacteristic alloc] initWithType:self.pCharacteristicWriteUUID
                                                                           properties:CBCharacteristicPropertyWrite
                                                                                value:nil
                                                                          permissions:CBAttributePermissionsWriteable];
        
        CBMutableService *customService = [[CBMutableService alloc] initWithType:self.pServiceUUID primary:YES];
        customService.characteristics = @[self.pMutableCharacteristic, self.pMutableCharacteristicRR];
        
        [self.pPeripheralManager addService:customService];
    }
}


- (void)fStartConnecting
{
    [self fInitBluetoothClient];
}


- (void)fStopConnecting
{
    [self fReleaseBluetoothClient];
}


- (void)fSendStartDataMsg
{
    if (self.pSendDataWriter.pSendState == eCLSNNSendDataWriterState_BeginSendHead) {
        
        NSData *sData = [@"S|" dataUsingEncoding:NSUTF8StringEncoding];
        BOOL didSend = [self.pPeripheralManager updateValue:sData forCharacteristic:self.pMutableCharacteristic onSubscribedCentrals:nil];
        if (didSend) {
            
            self.pSendDataWriter.pSendState = eCLSNNSendDataWriterState_BeginSendBody;
        }
    }
}


- (void)fSendEndDataMsg
{
    if (self.pSendDataWriter.pSendState == eCLSNNSendDataWriterState_BeginSendEnd) {
        
        NSData *sData = [@"|E" dataUsingEncoding:NSUTF8StringEncoding];
        BOOL didSend = [self.pPeripheralManager updateValue:sData forCharacteristic:self.pMutableCharacteristic onSubscribedCentrals:nil];
        if (didSend) {
            
            self.pSendDataWriter.pSendState = eCLSNNSendDataWriterState_SendEnd;
            [self.pDelegate dgClient_EndSendMsgToServer:self.pSendDataWriter];
            self.pSendDataWriter = nil;
        }
    }
}


- (void)fOnSendMsgToOther:(CLONNSendDataWriter *)writer
{
    self.pSendDataWriter = writer;
    [self fSendData];
}


- (void)fSendData
{
    if (!self.pSendDataWriter) {
        
        return;
    }
    
    [self fSendStartDataMsg];
    
    // send body
    if (self.pSendDataWriter.pSendState == eCLSNNSendDataWriterState_BeginSendBody) {
        // There's data left, so send until the callback fails, or we're done.
        BOOL didSend = YES;
        while (didSend) {
            
            // Work out how big it should be
            NSUInteger amountToSend = self.pSendDataWriter.pData.length - self.pSendDataWriter.pSendDataIndex;
            
            // Can't be longer than 32 bytes
            if (amountToSend > self.kLenSize) {
                
                amountToSend = self.kLenSize;
            }
            
            // Copy out the data we want
            NSData *chunk = [[NSData alloc] initWithBytes:self.pSendDataWriter.pData.bytes + self.pSendDataWriter.pSendDataIndex length:amountToSend];
            
            didSend = [self.pPeripheralManager updateValue:chunk forCharacteristic:self.pMutableCharacteristic onSubscribedCentrals:nil];
            
            // If it didn't work, drop out and wait for the callback
            if (!didSend) {
                
                break;
            }
            // It did send, so update our index
            self.pSendDataWriter.pSendDataIndex += amountToSend;
            
            // We're sending data
            // Is there any left to send?
            if (self.pSendDataWriter.pSendDataIndex >= self.pSendDataWriter.pData.length) {
                // No data left.  Do nothing
                self.pSendDataWriter.pSendState = eCLSNNSendDataWriterState_BeginSendEnd;
                break;
            }
        }
    }
    
    // 结束
    [self fSendEndDataMsg];
}



#pragma mark - 连接回调 CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    switch (peripheral.state) {
            case CBManagerStatePoweredOn:
                [self fInitMutableCharacteristic];
            break;
            
        default:
            NSLog(@"[Client] 此设备不支持 BLE 4.0");
            break;
    }
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error) {
        
        NSLog(@"[Client] peripheralManager:didAddService:error :%@", error.description);
        return;
    }
    
    [self.pPeripheralManager startAdvertising:@{
                                                CBAdvertisementDataLocalNameKey:@"ICServer",
                                                CBAdvertisementDataServiceUUIDsKey: @[self.pServiceUUID]
                                                }];
}


// 有设备连接
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"[Client] didSubscribeToCharacteristic 发现设备连接");
    [self.pDelegate dgNode_Connected];
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"[Client] 意外退出连接 didUnsubscribeFromCharacteristic");
    [self fStartConnecting];
}


- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    [self fSendData];
    NSLog(@"[Client] 以前没有完全发送完毕 peripheralManagerIsReady");
}


- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"[Client] 开始 advertising");
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"[Client] 开始 读取数据");
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    CBATTRequest *requ = requests.firstObject;
    if ([requ isKindOfClass:[CBATTRequest class]]) {
        
        if (requ.characteristic.UUID == self.pCharacteristicWriteUUID) {
            
            NSLog(@"[Client] 收到 %@", requ.value);
            if (requ.value) {
                
                NSString *str = [[NSString alloc] initWithData:requ.value encoding:NSUTF8StringEncoding];
                
                if ([str isEqualToString:@"S|"]) {
                    
                    self.pReceiveDataReader = [[CLONNReceiveDataReader alloc] init];
                }
                else if ([str isEqualToString:@"|E"]) {
                    
                    [self.pDelegate dgServer_ReceiveMsgFromClient:[self.pReceiveDataReader fReadInt32] withReader:self.pReceiveDataReader];
                }
                else if (requ.value.length > 0) {
                    
                    [self.pReceiveDataReader.pData appendData:requ.value];
                }
            }
        }
        
        [self.pPeripheralManager respondToRequest:requ withResult:CBATTErrorSuccess];
    }
}


@end
