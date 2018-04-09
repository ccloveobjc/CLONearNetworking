//
//  CLONNSendDataWriter.m
//  CLONearNetworking
//
//  Created by Cc on 2018/4/9.
//

#import "CLONNSendDataWriter.h"

@implementation CLONNSendDataWriter

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _pSendDataIndex = 0;
        _pData = [[NSMutableData alloc] init];
        _pSendState = eCLSNNSendDataWriterState_Init;
    }
    return self;
}


- (void)fWriteInt32:(UInt32)source
{
    UInt32 ss = source;
    int len = sizeof(UInt32);
    [self.pData appendBytes:&ss length:len];
}


- (void)fWriteData:(NSData *)source
{
    NSUInteger count = source.length;
    [self fWriteInt32:(UInt32)count];
    [self.pData appendData:source];
}


- (void)fWriteString:(NSString *)source
{
    NSUInteger count = source.length;
    [self fWriteInt32:(UInt32)count];
    NSData *tempD = [source dataUsingEncoding:NSUTF8StringEncoding];
    [self fWriteData:tempD];
}


@end
