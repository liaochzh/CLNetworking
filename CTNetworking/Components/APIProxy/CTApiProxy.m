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

@interface CTApiProxy ()

@property (nonatomic, strong) NSMutableDictionary *dispatchTable;
//@property (nonatomic, strong) NSNumber *recordedRequestId;

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
        //        _sessionManager.securityPolicy.allowInvalidCertificates = YES;
        //        _sessionManager.securityPolicy.validatesDomainName = NO;
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

- (void)cancelRequestWithRequestID:(NSUInteger)requestID
{
    NSNumber *reqID = @(requestID);
    [self.dispatchTable[reqID] cancel];
    [self.dispatchTable removeObjectForKey:reqID];
}

- (void)cancelRequestWithRequestIDList:(NSArray *)requestIDList
{
    for (NSNumber *requestId in requestIDList) {
        [self cancelRequestWithRequestID:requestId.unsignedIntegerValue];
    }
}

/** 这个函数存在的意义在于，如果将来要把AFNetworking换掉，只要修改这个函数的实现即可。 */
- (NSUInteger)callApiWithRequest:(NSURLRequest *)request params:(NSDictionary<NSString*, id<NSCoding>>*)params decrypt:(DecryptContent)decrypt success:(AXCallback)success fail:(AXCallback)fail
{
    // 跑到这里的block的时候，就已经是主线程了。
    NSURLSessionDataTask *dataTask = nil;
    __block NSUInteger requestID;
    
    dataTask = [self.sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *response, NSData *responseObject, NSError *error) {
        // 队列移除
        [self.dispatchTable removeObjectForKey:@(requestID)];
        
        // 没错误 和 实现解密block 就进行解密
        NSData *responseData = (error==nil && decrypt!=nil) ? decrypt(responseObject):responseObject;
        
        // 输出Log
        [CTLogger logDebugInfoWithResponse:(NSHTTPURLResponse*)response data:responseData request:request error:error];
        
        // 检查http response是否成立。
        // 构建Response
        CTURLResponse *CTResponse = [[CTURLResponse alloc] initWithRequestId:requestID request:request responseData:responseData error:error];

        
        if (error) // 失败回调
            fail?fail(CTResponse):nil;
        else // 成功回调
            success?success(CTResponse):nil;
    }];
    
    requestID = dataTask.taskIdentifier;
    
    self.dispatchTable[@(requestID)] = dataTask;
    [dataTask resume];
    
    return requestID;
}

@end
