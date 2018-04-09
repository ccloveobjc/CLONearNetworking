//
//  CLONNReceiveDataReader.h
//  CLONearNetworking
//
//  Created by Cc on 2018/4/9.
//

#import <Foundation/Foundation.h>

@interface CLONNReceiveDataReader : NSObject

@property (strong, nonatomic) NSMutableData *pData;


- (UInt32)fReadInt32;

- (NSData *)fReadData;

- (NSString *)fReadString;

@end
