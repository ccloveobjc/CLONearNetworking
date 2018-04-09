//
//  CLONNReceiveDataReader.m
//  CLONearNetworking
//
//  Created by Cc on 2018/4/9.
//

#import "CLONNReceiveDataReader.h"

@interface CLONNReceiveDataReader ()


@property (assign, nonatomic) NSUInteger pReadDataIndex;

@end
@implementation CLONNReceiveDataReader

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _pData = [[NSMutableData alloc] init];
        _pReadDataIndex = 0;
    }
    return self;
}


- (UInt32)fReadInt32
{
    NSRange range = NSMakeRange(self.pReadDataIndex, sizeof(UInt32));
    self.pReadDataIndex += range.length;
    UInt32 i = 0;
    [self.pData getBytes:&i range:range];
    return i;
}


- (NSData *)fReadData
{
    UInt32 lenght = [self fReadInt32];
    NSRange range = NSMakeRange(self.pReadDataIndex, lenght);
    self.pReadDataIndex += range.length;
    NSData *chunk = [[NSData alloc] initWithBytes:self.pData.bytes + range.location length:range.length];
    return chunk;
}


- (NSString *)fReadString
{
    NSData *chunk = [self fReadData];
    NSString *str = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
    return str;
}


@end
