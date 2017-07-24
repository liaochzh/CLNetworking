//
//  AXApiProxy.m
//  RTNetworking
//
//  Created by casa on 14-5-12.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "CTApiProxy.h"
#import "CTLogger.h"
#import "NSURLRequest+CTNetworkingMethods.h"

//static NSString * const kAXApiProxyDispatchItemKeyCallbackSuccess = @"kAXApiProxyDispatchItemCallbackSuccess";
//static NSString * const kAXApiProxyDispatchItemKeyCallbackFail = @"kAXApiProxyDispatchItemCallbackFail";

@interface CTApiProxy ()

@property (nonatomic, strong) NSMutableDictionary *dispatchTable;
@property (nonatomic, strong) NSNumber *recordedRequestId;

//AFNetworking stuff
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation CTApiProxy
#pragma mark - getters and setters
- (NSMutableDictionary *)dispatchTable
{
    if (_dispatchTable == nil) {
        _dispatchTable = [[NSMutableDictionary alloc] init];
    }
    return _dispatchTable;
}

- (AFHTTPSessionManager *)sessionManager
{
    if (_sessionManager == nil) {
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _sessionManager.securityPolicy.allowInvalidCertificates = YES;
        _sessionManager.securityPolicy.validatesDomainName = NO;
    }
    return _sessionManager;
}

#pragma mark - life cycle
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static CTApiProxy *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CTApiProxy alloc] init];
    });
    return sharedInstance;
}

#pragma mark - public methods

- (void)cancelRequestWithRequestID:(NSNumber *)requestID
{
    NSURLSessionDataTask *requestOperation = self.dispatchTable[requestID];
    [requestOperation cancel];
    [self.dispatchTable removeObjectForKey:requestID];
}

- (void)cancelRequestWithRequestIDList:(NSArray *)requestIDList
{
    for (NSNumber *requestId in requestIDList) {
        [self cancelRequestWithRequestID:requestId];
    }
}

/** 这个函数存在的意义在于，如果将来要把AFNetworking换掉，只要修改这个函数的实现即可。 */
- (NSUInteger)callApiWithRequest:(NSURLRequest *)request decrypt:(DecryptContent)decrypt success:(AXCallback)success fail:(AXCallback)fail
{
    
    NSLog(@"\n==================================\n\nRequest Start: \n\n %@\n\n==================================", request.URL);
    
    // 跑到这里的block的时候，就已经是主线程了。
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self.sessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSNumber *requestID = @([dataTask taskIdentifier]);
        [self.dispatchTable removeObjectForKey:requestID];
        //        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // 检查http response是否成立。
        
        if (error) {
            //            NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            //            [CTLogger logDebugInfoWithResponse:httpResponse
            //                                  responseString:responseString
            //                                        request:request
            //                                          error:error];
            CTURLResponse *CTResponse = [[CTURLResponse alloc] initWithRequestId:requestID request:request responseData:responseObject error:error];
            fail?fail(CTResponse):nil;
            
        } else {
            
            NSData *responseData;
            if (decrypt) // 实现解密block，先解密
                responseData = decrypt(responseObject);
            else
                responseData = responseObject;
            
            //            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            //            [CTLogger logDebugInfoWithResponse:httpResponse
            //                                  responseString:responseString
            //                                        request:request
            //                                          error:NULL];
            CTURLResponse *CTResponse = [[CTURLResponse alloc] initWithRequestId:requestID request:request responseData:responseData status:CTURLResponseStatusSuccess];
            success?success(CTResponse):nil;
        }
    }];
    
    NSUInteger requestId = [dataTask taskIdentifier];
    
    self.dispatchTable[@(requestId)] = dataTask;
    [dataTask resume];
    
    return requestId;
}

@end
