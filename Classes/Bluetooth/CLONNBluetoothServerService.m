//
//  CLONNBluetoothServerService.m
//  CLOCommon
//
//  Created by Cc on 2018/4/9.
//

#import "CLONNBluetoothServerService.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "CLONNSendDataWriter.h"
#import "CLONNReceiveDataReader.h"

@interface CLONNBluetoothServerService ()
<
    CBCentralManagerDelegate
    , CBPeripheralDelegate
>

@property (strong, nonatomic) CBUUID *pServiceUUID;
@property (strong, nonatomic) CBUUID *pCharacteristicUUID;
@property (strong, nonatomic) CBUUID *pCharacteristicWriteUUID;
@property (assign, nonatomic) NSInteger *pMaxConnections;

@property (strong, nonatomic) CBCentralManager *pCentralManager;
@property (strong, nonatomic) CBPeripheral *pPeripheral;
@property (strong, nonatomic) CBCharacteristic *pCharacteristic;
@property (strong, nonatomic) CBCharacteristic *pCharacteristicRR;


/// 这个是正在发送的对象，当有值时就开始发送它，如果它为nil表示已经完成
@property (strong, nonatomic) CLONNSendDataWriter *pSendDataWriter;

/// 收到的消息
@property (strong, nonatomic) CLONNReceiveDataReader *pReceiveDataReader;


@property (assign, nonatomic) int kLenSize;

@end
@implementation CLONNBluetoothServerService

- (instancetype)initWithServiceUUID:(CBUUID *)serviceUUID withCharacteristicUUID:(CBUUID *)characteristicUUID withCharachteristicWriteUUID:(CBUUID *)charachteristicWriteUUID withMaxConnections:(NSInteger)maxConnections
{
    self = [super init];
    if (self) {
        
        _pServiceUUID = serviceUUID;
        _pCharacteristicUUID = characteristicUUID;
        _pCharacteristicWriteUUID = charachteristicWriteUUID;
        _pMaxConnections = maxConnections;
        _kLenSize = 64;
    }
    return self;
}


- (void)dealloc
{
    [self fReleaseCentralManager];
}


- (void)fInitCentralManager
{
    if (!self.pCentralManager) {
        
        self.pCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
}


- (void)fReleaseCentralManager
{
    if (self.pCentralManager) {
        
        if (self.pPeripheral) {
            
            [self.pCentralManager cancelPeripheralConnection:self.pPeripheral];
        }
        
        [self.pCentralManager stopScan];
        self.pCentralManager.delegate = nil;
        self.pCentralManager = nil;
    }
    
    [self fReleasePeripheral];
    
    if (self.pCharacteristic) {
        
        self.pCharacteristic = nil;
    }
}


- (void)fReleasePeripheral
{
    if (self.pPeripheral) {
        
        self.pPeripheral.delegate = nil;
        self.pPeripheral = nil;
    }
}


- (void)fStartListening
{
    [self fInitCentralManager];
}


- (void)fStopListening
{
    [self fReleaseCentralManager];
}


- (void)fOnSendMsgToOther:(CLONNSendDataWriter *)writer
{
    self.pSendDataWriter = writer;
    [self fSendData];
}


- (void)fSendStartDataMsg
{
    if (self.pSendDataWriter.pSendState == eCLSNNSendDataWriterState_BeginSendHead) {
        
        NSData *sData = [@"S|" dataUsingEncoding:NSUTF8StringEncoding];
        [self.pPeripheral writeValue:sData forCharacteristic:self.pCharacteristicRR type:CBCharacteristicWriteWithResponse];
        
        self.pSendDataWriter.pSendState = eCLSNNSendDataWriterState_BeginSendBody;
    }
}


- (void)fSendEndDataMsg
{
    if (self.pSendDataWriter.pSendState == eCLSNNSendDataWriterState_BeginSendEnd) {
        
        NSData *sData = [@"|E" dataUsingEncoding:NSUTF8StringEncoding];
        [self.pPeripheral writeValue:sData forCharacteristic:self.pCharacteristicRR type:CBCharacteristicWriteWithResponse];
        
        self.pSendDataWriter.pSendState = eCLSNNSendDataWriterState_SendEnd;
        [self.pDelegate dgClient_EndSendMsgToServer:self.pSendDataWriter];
        self.pSendDataWriter = nil;
    }
}


- (void)fSendData
{
    if (self.pSendDataWriter) {
        
        [self fSendStartDataMsg];
        
        if (self.pSendDataWriter.pSendState == eCLSNNSendDataWriterState_BeginSendBody) {
            
            while (YES) {
                
                NSUInteger amountToSend = self.pSendDataWriter.pData.length - self.pSendDataWriter.pSendDataIndex;
                
                if (amountToSend > self.kLenSize) {
                    
                    amountToSend = self.kLenSize;
                }
                
                NSData *chunk = [[NSData alloc] initWithBytes:self.pSendDataWriter.pData.bytes + self.pSendDataWriter.pSendDataIndex length:amountToSend];
                
                [self.pPeripheral writeValue:chunk forCharacteristic:self.pCharacteristicRR type:CBCharacteristicWriteWithResponse];
                
                self.pSendDataWriter.pSendDataIndex += amountToSend;
                
                if (self.pSendDataWriter.pSendDataIndex >= self.pSendDataWriter.pData.length) {
                    
                    self.pSendDataWriter.pSendState = eCLSNNSendDataWriterState_BeginSendEnd;
                    break;
                }
            }
        }
        
        [self fSendEndDataMsg];
    }
}


#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"[Server] 启动搜索");
            [self.pCentralManager scanForPeripheralsWithServices:@[self.pServiceUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            break;
            
        default:
            NSLog(@"[Server] 此设备不支持 BLE 4.0");
            break;
    }
}


// 成功连接
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // 发现服务
    NSLog(@"[Server] 成功连接到 peripheral   开始搜索服务");
    self.pPeripheral = peripheral;
    self.pPeripheral.delegate = self;
    [self.pPeripheral discoverServices:@[self.pServiceUUID]];
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"[Server] 连接丢失");
    [self fReleasePeripheral];
    
    [self centralManagerDidUpdateState:central];
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    [central stopScan];
    if (peripheral.state == CBPeripheralStateConnected) {
        
        [central retrieveConnectedPeripheralsWithServices:@[self.pServiceUUID]];
    }
    else {
        
        self.pPeripheral = peripheral;
        NSLog(@"[Server] 找到 peripheral  开始连接");
        [central connectPeripheral:peripheral options:nil];
    }
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接失败");
    [self fReleasePeripheral];
    
    [self centralManagerDidUpdateState:central];
}


#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        
        NSAssert(NO, @"");
        return;
    }
    
    if (peripheral.services == nil) {
        
        NSAssert(NO, @"");
        return;
    }
    
    for (CBService *service in peripheral.services) {
        
        if (service.UUID == self.pServiceUUID && peripheral == self.pPeripheral) {
            
            NSLog(@"[Server] 一个一个响应 peripheral 的服务");
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        
        NSAssert(NO, @"");
        return;
    }
    
    if (service.UUID == self.pServiceUUID && peripheral == self.pPeripheral) {
        
        if (service.characteristics == nil) {
            
            NSAssert(NO, @"");
            return;
        }
        
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if (characteristic.UUID == self.pCharacteristicUUID) {
                
                NSLog(@"[Server] 服务已经加载上   %@", characteristic);
                self.pCharacteristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            else if (characteristic.UUID == self.pCharacteristicWriteUUID) {
                
                NSLog(@"[Server] 服务已经加载上   %@", characteristic);
                self.pCharacteristicRR = characteristic;
            }
        }
        
        [self.pDelegate dgNode_Connected];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        
        NSAssert(NO, @"");
        return;
    }
    
    if (characteristic.UUID == self.pCharacteristicUUID && peripheral == self.pPeripheral) {
        
        [peripheral readValueForCharacteristic:characteristic];
        NSLog(@"[Server] 开始读取数据");
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (characteristic.value) {
        
        NSString *str = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        
        if ([str isEqualToString:@"S|"]) {
            
            self.pReceiveDataReader = [[CLONNReceiveDataReader alloc] init];
        }
        else if ([str isEqualToString:@"|E"]) {
            
            [self.pDelegate dgServer_ReceiveMsgFromClient:[self.pReceiveDataReader fReadInt32] withReader:self.pReceiveDataReader];
        }
        else if (characteristic.value.length > 0) {
            
            [self.pReceiveDataReader.pData appendData:characteristic.value];
        }
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
    NSLog(@"[Server] didModifyServices");
    [self fStartListening];
}


@end
