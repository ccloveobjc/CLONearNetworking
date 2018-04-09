//
//  CLONNNetworkNode.h
//  CLOCommon
//
//  Created by Cc on 2018/4/9.
//

#import <Foundation/Foundation.h>

@class CLONNSendDataWriter, CLONNReceiveDataReader;

@protocol CLONNNetworkNodeDelegate <NSObject>

- (void)dgClient_EndSendMsgToServer:(CLONNSendDataWriter *)writer;

- (void)dgServer_ReceiveMsgFromClient:(UInt32)identifier withReader:(CLONNReceiveDataReader *)reader;

- (void)dgNode_Connected;

@end

@interface CLONNNetworkNode : NSObject

@property (weak, nonatomic) id<CLONNNetworkNodeDelegate> pDelegate;


- (void)fBeginMsg:(UInt32)identifier withBlock:(void (^)(CLONNSendDataWriter *writer))block;

- (void)fSendAllMsg;

- (void)fOnSendMsgToOther:(CLONNSendDataWriter *)writer;

@end
