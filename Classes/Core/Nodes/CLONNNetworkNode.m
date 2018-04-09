//
//  CLONNNetworkNode.m
//  CLOCommon
//
//  Created by Cc on 2018/4/9.
//

#import "CLONNNetworkNode.h"
#import "CLONNSendDataWriter.h"

@interface CLONNNetworkNode()

@property (strong, nonatomic) NSMutableArray<CLONNSendDataWriter *> *pArrDataPackages;
@property (strong, nonatomic) NSConditionLock *mLock;

@end
@implementation CLONNNetworkNode

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _pArrDataPackages = [[NSMutableArray alloc] init];
        _mLock = [[NSConditionLock alloc] init];
    }
    return self;
}


- (void)fBeginMsg:(UInt32)identifier withBlock:(void (^)(CLONNSendDataWriter *writer))block
{
    CLONNSendDataWriter *wri = [[CLONNSendDataWriter alloc] init];
    [wri fWriteInt32:identifier];
    block(wri);
    [self.pArrDataPackages addObject:wri];
    [self fSendAllMsg];
}


- (void)fSendAllMsg
{
    if (self.pArrDataPackages.count > 0) {
        
        CLONNSendDataWriter *tmpW = self.pArrDataPackages.firstObject;
        if ([tmpW isKindOfClass:[CLONNSendDataWriter class]]) {
            
            if (tmpW.pSendState == eCLSNNSendDataWriterState_Init) {
                
                tmpW.pSendState = eCLSNNSendDataWriterState_BeginSendHead;
                [self fOnSendMsgToOther:tmpW];
            }
            
            if (tmpW.pSendState == eCLSNNSendDataWriterState_SendEnd) {
                
                [self.pArrDataPackages removeObject:tmpW];
                [self fSendAllMsg];
            }
        }
    }
}


- (void)fOnSendMsgToOther:(CLONNSendDataWriter *)writer
{
    NSAssert(false, @"子类实现");
    writer.pSendState = eCLSNNSendDataWriterState_SendEnd;
}


@end
