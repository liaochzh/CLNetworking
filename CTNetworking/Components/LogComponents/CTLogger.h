//
//  AXLogger.h
//  RTNetworking
//
//  Created by casa on 14-5-6.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTService.h"
//#import "CTLoggerConfiguration.h"
#import "CTURLResponse.h"


@interface CTLogger : NSObject

//@property (nonatomic, strong, readonly) CTLoggerConfiguration *configParams;
@property (nonatomic, assign) BOOL isDebug;

+ (instancetype)sharedInstance;

+ (void)logDebugInfoWithRequest:(NSURLRequest *)request apiName:(NSString *)apiName service:(CTService *)service requestParams:(id)requestParams httpMethod:(NSString *)httpMethod;

+ (void)logDebugInfoWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data request:(NSURLRequest *)request error:(NSError *)error;

+ (void)logDebugInfoWithCachedResponse:(CTURLResponse *)response methodName:(NSString *)methodName serviceIdentifier:(CTService *)service;

//- (void)logWithActionCode:(NSString *)actionCode params:(NSDictionary *)params;

@end
