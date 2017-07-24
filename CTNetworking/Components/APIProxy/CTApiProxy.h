//
//  AXApiProxy.h
//  RTNetworking
//
//  Created by casa on 14-5-12.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTURLResponse.h"
#import "CTService.h"

typedef void(^AXCallback)(CTURLResponse *response);
typedef NSData* (^DecryptContent)(NSData*);

@interface CTApiProxy : NSObject

+ (instancetype)sharedInstance;

/** 这个函数存在的意义在于，如果将来要把AFNetworking换掉，只要修改这个函数的实现即可。 */
- (NSUInteger)callApiWithRequest:(NSURLRequest *)request decrypt:(DecryptContent)decrypt success:(AXCallback)success fail:(AXCallback)fail;

- (void)cancelRequestWithRequestID:(NSNumber *)requestID;
- (void)cancelRequestWithRequestIDList:(NSArray *)requestIDList;

@end
