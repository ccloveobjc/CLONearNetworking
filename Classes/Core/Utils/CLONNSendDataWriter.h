//
//  CLONNSendDataWriter.h
//  CLONearNetworking
//
//  Created by Cc on 2018/4/9.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, eCLSNNSendDataWriterState) {
    /// 0 = 初始化
    eCLSNNSendDataWriterState_Init =             0,
    /// 1=开始发送开始
    eCLSNNSendDataWriterState_BeginSendHead =    1,
    /// 2=开始发送结束并且开始发送身体
    eCLSNNSendDataWriterState_BeginSendBody =    2,
    /// 3=开始发送结束
    eCLSNNSendDataWriterState_BeginSendEnd =     3,
    /// 4=发送结束完成
    eCLSNNSendDataWriterState_SendEnd =          4,
};

@interface CLONNSendDataWriter : NSObject

@property (assign, nonatomic) NSUInteger pSendDataIndex;
@property (strong, nonatomic) NSMutableData *pData;
@property (assign, nonatomic) eCLSNNSendDataWriterState pSendState;

- (void)fWriteInt32:(UInt32)source;

- (void)fWriteData:(NSData *)source;

- (void)fWriteString:(NSString *)source;

@end
