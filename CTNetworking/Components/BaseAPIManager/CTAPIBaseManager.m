//
//  AJKBaseManager.m
//  casatwy2
//
//  Created by casa on 13-12-2.
//  Copyright (c) 2013年 casatwy inc. All rights reserved.
//

#import "CTAPIBaseManager.h"
#import "CTCache+CTApiExt.h"
#import "CTLogger.h"
#import "CTApiProxy.h"
#import <AFNetworking/AFNetworking.h>
#import "NSDictionary+AXNetworkingMethods.h"
#import "NSString+AXNetworkingMethods.h"

// 在调用成功之后的params字典里面，用这个key可以取出requestID
NSString * const kCTAPIBaseManagerRequestID = @"kCTAPIBaseManagerRequestID";


@interface CTAPIBaseManager ()

@property (nonatomic, strong, readwrite) id fetchedRawData;
//@property (nonatomic, assign, readwrite) BOOL isLoading;

@property (nonatomic, copy, readwrite) NSString *errorMessage;
@property (nonatomic, readwrite) CTAPIManagerErrorType errorType;
@property (nonatomic, strong) NSMutableArray *requestIdList;
@property (nonatomic, strong) CTCache *cache;

@end

@implementation CTAPIBaseManager

#pragma mark - life cycle
- (instancetype)init
{
    self = [super init];
    if (self) {
        _delegate = nil;
        _validator = nil;
        _paramSource = nil;
        
        _fetchedRawData = nil;
        
        _errorMessage = nil;
        _errorType = CTAPIManagerErrorTypeDefault;
        
        self.child = (id <CTAPIManager>)self;
    }
    return self;
}

- (void)dealloc
{
    [self cancelAllRequests];
    self.requestIdList = nil;
}

#pragma mark - public methods
- (void)cancelAllRequests
{
    [[CTApiProxy sharedInstance] cancelRequestWithRequestIDList:self.requestIdList];
    [self.requestIdList removeAllObjects];
}

- (void)cancelRequestWithRequestId:(NSUInteger)requestID
{
    [self removeRequestIdWithRequestID:requestID];
    [[CTApiProxy sharedInstance] cancelRequestWithRequestID:requestID];
}

- (id)fetchDataWithReformer:(id<CTAPIManagerDataReformer>)reformer
{
    id resultData = nil;
    if ([reformer respondsToSelector:@selector(manager:reformData:)]) {
        resultData = [reformer manager:self reformData:self.fetchedRawData];
    } else {
        resultData = [self.fetchedRawData mutableCopy];
    }
    return resultData;
}

#pragma mark - calling api
- (NSUInteger)loadData
{
    NSDictionary *params = [self.paramSource paramsForApi:self];
    NSUInteger requestId = [self loadDataWithParams:params];
    return requestId;
}

- (NSUInteger)loadDataWithParams:(NSDictionary *)params
{
    NSObject<CTAPIManager>* child = self.child;
    if (!child) return kNilRequestID;
    
    NSDictionary *apiParams = [child respondsToSelector:@selector(reformParams:)] ? [child reformParams:params] : params;
    
    if ([self shouldCallAPIWithParams:apiParams]) {
        if (!self.validator || [self.validator manager:self isCorrectWithParamsData:apiParams]) {
            
            // 先检查一下是否需要读取缓存数据
            BOOL shouldCache = [child respondsToSelector:@selector(shouldCache)] ? [child shouldCache] : false;
            if (shouldCache) {
                // 读取缓存数据
                if ([self loadCacheWithParams:apiParams]) {
                    return kNilRequestID;
                }
            }
            
            // 本地缓存
            BOOL shouldNative = [child respondsToSelector:@selector(shouldLoadFromNative)] ?
            [child shouldLoadFromNative] : false;
            if (shouldNative)
                [self loadDataFromNative:apiParams];
            
            // 实际的网络请求
            if ([self isReachable])
            {
                // 构建请求
                NSURLRequest *request;
                switch (child.requestType)
                {
                    case CTAPIManagerRequestTypeGet:
                        request = [child.requestGenerator generateGETRequestWithServiceIdentifier:child.service requestParams:apiParams methodName:child.methodName];
                        break;
                        
                    case CTAPIManagerRequestTypePost:
                        request = [child.requestGenerator generatePOSTRequestWithServiceIdentifier:child.service requestParams:apiParams methodName:child.methodName];
                        break;
                        
                    case CTAPIManagerRequestTypePut:
                        request = [child.requestGenerator generatePutRequestWithServiceIdentifier:child.service requestParams:apiParams methodName:child.methodName];
                        break;
                        
                    case CTAPIManagerRequestTypeDelete:
                        request = [child.requestGenerator generateDeleteRequestWithServiceIdentifier:child.service requestParams:apiParams methodName:child.methodName];
                        break;
                        
                    default:
                        break;
                }
                
                if (request == nil) {
                    [self failedOnCallingAPI:nil withErrorType:CTAPIManagerErrorTypeNoRequest];
                    return kNilRequestID;
                }

                [CTLogger logDebugInfoWithRequest:request apiName:nil service:child.service requestParams:apiParams httpMethod:request.HTTPMethod];
                
                __weak typeof(self) weakSelf = self;
                __weak typeof(child) weakChild = child;
                
                NSUInteger requestId = [[CTApiProxy sharedInstance] callApiWithRequest:request params:apiParams decrypt:
                                        // 解密回调
                                        ^NSData *(NSData *content)
                                        {
                                            __strong typeof(weakChild) strongChild = weakChild;
                                            
                                            BOOL flag = [strongChild respondsToSelector:@selector(decryptResponse:)];
                                            
                                            return flag ? [strongChild decryptResponse:content] : content;
                                            
                                        } success:
                                        // 成功回调
                                        ^(CTURLResponse *response)
                                        {
                                            __strong typeof(weakSelf) strongSelf = weakSelf;
                                            [strongSelf successedOnCallingAPI:response];
                                            
                                        } fail:
                                        // 失败回调
                                        ^(CTURLResponse *response)
                                        {
                                            __strong typeof(weakSelf) strongSelf = weakSelf;
                                            strongSelf.errorMessage = response.error.localizedDescription;
                                            if (response.error.code == NSURLErrorTimedOut)
                                                [strongSelf failedOnCallingAPI:response withErrorType:CTAPIManagerErrorTypeTimeout];
                                            else
                                                [strongSelf failedOnCallingAPI:response withErrorType:CTAPIManagerErrorTypeDefault];
                                        }];
                
                [self.requestIdList addObject:@(requestId)];
                
                NSMutableDictionary *params = [apiParams mutableCopy];
                params[kCTAPIBaseManagerRequestID] = @(requestId);
                [self afterCallingAPIWithParams:params];
                return requestId;
                
            } else {
                [self failedOnCallingAPI:nil withErrorType:CTAPIManagerErrorTypeNoNetWork];
                return kNilRequestID;
            }
        } else {
            [self failedOnCallingAPI:nil withErrorType:CTAPIManagerErrorTypeParamsError];
            return kNilRequestID;
        }
    }
    return kNilRequestID;
}

#pragma mark - api callbacks

///
- (void)successedOnCallingAPI:(CTURLResponse *)response
{
    self.response = response;
    
    if (response.content)
        self.fetchedRawData = [response.content copy];
    else
        self.fetchedRawData = [response.responseData copy];
    
    
    if (!self.validator || [self.validator manager:self isCorrectWithCallBackData:self.fetchedRawData]) { /// 验证回调数据
        
        if (!response.isCache) {  // 不是缓存数据
            
            [self removeRequestIdWithRequestID:response.requestId];
            
            NSObject<CTAPIManager>* child = self.child;
            if (child) {
                BOOL shouldCache = [child respondsToSelector:@selector(shouldCache)] ? [child shouldCache] : false;
                BOOL shouldNative = [child respondsToSelector:@selector(shouldLoadFromNative)] ? [child shouldLoadFromNative] : false;
                
                if (shouldCache || shouldNative) { // 需要缓存
                    BOOL memoryOnly = !shouldNative; // 不需要本地缓存
                    
                    NSData *cacheData;
                    if ([child respondsToSelector:@selector(encryptCache:)])
                        cacheData = [child encryptCache:response.responseData];
                    else
                        cacheData = response.responseData;
                    
                    [self.cache saveCacheWithData:cacheData serviceIdentifier:child.service.serviceIdentifier methodName:child.methodName requestParams:response.requestParams inMemoryOnly:memoryOnly];
                }
            }
        }
        
        if ([self beforePerformSuccessWithResponse:response]) {
            [self.delegate managerCallAPIDidSuccess:self];
        }
        [self afterPerformSuccessWithResponse:response];
        
    } else {
        [self failedOnCallingAPI:response withErrorType:CTAPIManagerErrorTypeNoContent];
    }
}

///
- (void)failedOnCallingAPI:(CTURLResponse *)response withErrorType:(CTAPIManagerErrorType)errorType
{
    // 先移除请求id
    if (response && response.requestId != kNilRequestID) {
        [self removeRequestIdWithRequestID:response.requestId];
    }
    
    // 错误的信息
    // 响应数据是缓存 报了没数据错误，但还有请求未完成，就不处理了
    if (!response.isCache || errorType != CTAPIManagerErrorTypeNoContent || !self.isLoading) {
        self.response = response;
        
        // 错误
        self.errorType = errorType;
        
        if ([self beforePerformFailWithResponse:response]) {
            [self.delegate managerCallAPIDidFailed:self];
        }
        [self afterPerformFailWithResponse:response];
    }
}

#pragma mark - method for interceptor

/*
 拦截器的功能可以由子类通过继承实现，也可以由其它对象实现,两种做法可以共存
 当两种情况共存的时候，子类重载的方法一定要调用一下super
 然后它们的调用顺序是BaseManager会先调用子类重载的实现，再调用外部interceptor的实现
 
 notes:
 正常情况下，拦截器是通过代理的方式实现的，因此可以不需要以下这些代码
 但是为了将来拓展方便，如果在调用拦截器之前manager又希望自己能够先做一些事情，所以这些方法还是需要能够被继承重载的
 所有重载的方法，都要调用一下super,这样才能保证外部interceptor能够被调到
 这就是decorate pattern
 */

/// 只有返回YES才会继续调用API
- (BOOL)shouldCallAPIWithParams:(NSDictionary *)params
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager:shouldCallAPIWithParams:)]) {
        return [self.interceptor manager:self shouldCallAPIWithParams:params];
    } else {
        return YES;
    }
}

- (void)afterCallingAPIWithParams:(NSDictionary *)params
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager:afterCallingAPIWithParams:)]) {
        [self.interceptor manager:self afterCallingAPIWithParams:params];
    }
}

- (BOOL)beforePerformSuccessWithResponse:(CTURLResponse *)response
{
    BOOL result = YES;
    
    self.errorType = CTAPIManagerErrorTypeSuccess;
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager: beforePerformSuccessWithResponse:)]) {
        result = [self.interceptor manager:self beforePerformSuccessWithResponse:response];
    }
    return result;
}

- (void)afterPerformSuccessWithResponse:(CTURLResponse *)response
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager:afterPerformSuccessWithResponse:)]) {
        [self.interceptor manager:self afterPerformSuccessWithResponse:response];
    }
}

- (BOOL)beforePerformFailWithResponse:(CTURLResponse *)response
{
    BOOL result = YES;
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager:beforePerformFailWithResponse:)]) {
        result = [self.interceptor manager:self beforePerformFailWithResponse:response];
    }
    return result;
}

- (void)afterPerformFailWithResponse:(CTURLResponse *)response
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(manager:afterPerformFailWithResponse:)]) {
        [self.interceptor manager:self afterPerformFailWithResponse:response];
    }
}

#pragma mark - private methods
- (void)removeRequestIdWithRequestID:(NSUInteger)requestId
{
    [self.requestIdList removeObject:@(requestId)];
    //    NSNumber *requestIDToRemove = nil;
    //    for (NSNumber *storedRequestId in self.requestIdList) {
    //        if ([storedRequestId unsignedIntegerValue] == requestId) {
    //            requestIDToRemove = storedRequestId;
    //        }
    //    }
    //    if (requestIDToRemove) {
    //        [self.requestIdList removeObject:requestIDToRemove];
    //    }
}

- (BOOL)loadCacheWithParams:(NSDictionary *)params
{
    NSObject<CTAPIManager> *child = self.child;
    if (!child) return false;
    
    NSString *serviceIdentifier = child.service.serviceIdentifier;
    NSString *methodName = child.methodName;
    CTService *service = child.service;
    
    NSTimeInterval outdatedInterva = [child respondsToSelector:@selector(cacheOutdatedInterval)] ? child.cacheOutdatedInterval : 300;
    
    NSData *result = [self.cache fetchCachedDataWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:params outdatedInterval:outdatedInterva];
    
    if (result == nil)
        return NO;
    
    if ([child respondsToSelector:@selector(decryptCache:)])
        result = [child decryptCache:result];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        CTURLResponse *response = [[CTURLResponse alloc] initWithData:result];
        response.requestParams = params;
        
        [CTLogger logDebugInfoWithCachedResponse:response methodName:methodName serviceIdentifier:service];
        [strongSelf successedOnCallingAPI:response];
    });
    return YES;
}

- (BOOL)loadDataFromNative:(NSDictionary *)params
{
    NSObject<CTAPIManager> *child = self.child;
    if (!child) return false;
    
    NSString *serviceIdentifier = child.service.serviceIdentifier;
    NSString *methodName = child.methodName;
    NSData *result = [self.cache fetchCachedDataWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:params outdatedInterval:2592000]; // 本地数据，最多就是一个月
    
    if (result == nil) return NO;
    
    if ([child respondsToSelector:@selector(decryptCache:)])
        result = [child decryptCache:result];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        CTURLResponse *response = [[CTURLResponse alloc] initWithData:result];
        response.requestParams = params;
        
        [strongSelf successedOnCallingAPI:response];
    });
    return YES;
}

#pragma mark - getters and setters

- (BOOL)isLoading {
    return self.requestIdList.count > 0;
}

- (CTCache *)cache
{
    if (_cache == nil) {
        _cache = [CTCache sharedInstance];
    }
    return _cache;
}

- (NSMutableArray *)requestIdList
{
    if (_requestIdList == nil) {
        _requestIdList = [[NSMutableArray alloc] init];
    }
    return _requestIdList;
}

- (BOOL)isReachable
{
    BOOL isReachability = [[AFNetworkReachabilityManager sharedManager] isReachable] || [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus == AFNetworkReachabilityStatusUnknown;
    if (!isReachability) {
        self.errorType = CTAPIManagerErrorTypeNoNetWork;
    }
    return isReachability;
}


@end
