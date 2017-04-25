//
//  AJKBaseManager.m
//  casatwy2
//
//  Created by casa on 13-12-2.
//  Copyright (c) 2013年 casatwy inc. All rights reserved.
//

#import "CTAPIBaseManager.h"
#import "CTCache.h"
#import "CTLogger.h"
#import "CTApiProxy.h"
#import <AFNetworking/AFNetworking.h>
#import "NSURLRequest+CTNetworkingMethods.h"
#import "NSDictionary+AXNetworkingMethods.h"
#import "NSString+AXNetworkingMethods.h"

//NSString * const kBSUserTokenNotificationUserInfoKeyRequestToContinue = @"kBSUserTokenNotificationUserInfoKeyRequestToContinue";
//NSString * const kBSUserTokenNotificationUserInfoKeyManagerToContinue = @"kBSUserTokenNotificationUserInfoKeyManagerToContinue";

// 在调用成功之后的params字典里面，用这个key可以取出requestID
NSString * const kCTAPIBaseManagerRequestID = @"kCTAPIBaseManagerRequestID";


@interface CTAPIBaseManager ()

@property (nonatomic, strong, readwrite) id fetchedRawData;
@property (nonatomic, assign, readwrite) BOOL isLoading;
//@property (nonatomic, assign) BOOL isNativeDataEmpty;

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
        
        if ([self conformsToProtocol:@protocol(CTAPIManager)]) {
            self.child = (id <CTAPIManager>)self;
        } else {
            NSException *exception = [[NSException alloc] init];
            @throw exception;
        }
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

- (void)cancelRequestWithRequestId:(NSInteger)requestID
{
    [self removeRequestIdWithRequestID:requestID];
    [[CTApiProxy sharedInstance] cancelRequestWithRequestID:@(requestID)];
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
- (NSInteger)loadData
{
    NSDictionary *params = [self.paramSource paramsForApi:self];
    NSInteger requestId = [self loadDataWithParams:params];
    return requestId;
}

- (NSInteger)loadDataWithParams:(NSDictionary *)params
{
    NSInteger requestId = 0;
    NSDictionary *apiParams = [self reformParams:params];
    if ([self shouldCallAPIWithParams:apiParams]) {
        if ([self.validator manager:self isCorrectWithParamsData:apiParams]) {
            
            // 先检查一下是否需要读取缓存数据
            if ([self.child shouldCache]) {
                // 读取缓存数据
                if ([self loadDataWithParams:apiParams]) {
                    return 0;
                }
            }
            
            if ([self.child shouldLoadFromNative]) { // 本地缓存
                [self loadDataFromNative:apiParams];
            }
            
            // 实际的网络请求
            if ([self isReachable])
            {
                // 构建请求
                NSURLRequest *request;
                switch (self.child.requestType)
                {
                    case CTAPIManagerRequestTypeGet:
                        request = [self.child.requestGenerator generateGETRequestWithServiceIdentifier:self.child.service requestParams:apiParams methodName:self.child.methodName];
                        break;
                        
                    case CTAPIManagerRequestTypePost:
                        request = [self.child.requestGenerator generatePOSTRequestWithServiceIdentifier:self.child.service requestParams:apiParams methodName:self.child.methodName];
                        break;
                        
                    case CTAPIManagerRequestTypePut:
                        request = [self.child.requestGenerator generatePutRequestWithServiceIdentifier:self.child.service requestParams:apiParams methodName:self.child.methodName];
                        break;
                        
                    case CTAPIManagerRequestTypeDelete:
                        request = [self.child.requestGenerator generateDeleteRequestWithServiceIdentifier:self.child.service requestParams:apiParams methodName:self.child.methodName];
                        break;
                        
                    default:
                        break;
                }
                
                if (request == nil) {
                    [self failedOnCallingAPI:nil withErrorType:CTAPIManagerErrorTypeNoRequest];
                    return requestId;
                }
                
                if ([self.child.requestGenerator respondsToSelector:@selector(decryptResponseContent)]) {
                    request.decryptResponseContent = [self.child.requestGenerator decryptResponseContent];
                }
                request.requestParams = apiParams;
                
                self.isLoading = YES;
                
                __weak typeof(self) weakSelf = self;
                requestId = [[CTApiProxy sharedInstance] callApiWithRequest:request success:^(CTURLResponse *response) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf successedOnCallingAPI:response];
                } fail:^(CTURLResponse *response) {
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
                return requestId;
            }
        } else {
            [self failedOnCallingAPI:nil withErrorType:CTAPIManagerErrorTypeParamsError];
            return requestId;
        }
    }
    return requestId;
}

#pragma mark - api callbacks
- (void)successedOnCallingAPI:(CTURLResponse *)response
{
    self.response = response;
    
    if (response.content) {
        self.fetchedRawData = [response.content copy];
    } else {
        self.fetchedRawData = [response.responseData copy];
    }
    
    if ([self.validator manager:self isCorrectWithCallBackData:response.content]) {
        
        if (response.isCache == NO) {  // 不是缓存数据
            
            self.isLoading = NO;
            [self removeRequestIdWithRequestID:response.requestId];
            
            BOOL sc = [self.child shouldCache];
            BOOL sn = [self.child shouldLoadFromNative];
            
            if (sc || sn) { // 需要缓存
                BOOL memoryOnly = (sn == false); // 不需要本地缓存
                NSData *cacheData = [self.child decryptCache:response.responseData];
                [self.cache saveCacheWithData:cacheData serviceIdentifier:self.child.service.serviceIdentifier methodName:self.child.methodName requestParams:response.requestParams inMemoryOnly:memoryOnly];
            }
        }
        
        if ([self beforePerformSuccessWithResponse:response]) {
            if (response.isCache == YES) {
                [self.delegate managerCallAPIDidSuccess:self];
            } else {
                [self.delegate managerCallAPIDidSuccess:self];
            }
        }
        [self afterPerformSuccessWithResponse:response];
        
    } else {
        [self failedOnCallingAPI:response withErrorType:CTAPIManagerErrorTypeNoContent];
    }
}

- (void)failedOnCallingAPI:(CTURLResponse *)response withErrorType:(CTAPIManagerErrorType)errorType
{
    // 错误的信息
    // 没有请求服务器，就处理缓存数据
    // 正在请求服务器，就不处理缓存数据
    if ((self.isLoading && !response.isCache) ||
        !self.isLoading)
    {
        self.isLoading = NO;
        self.response = response;
        
        // 错误
        self.errorType = errorType;
        [self removeRequestIdWithRequestID:response.requestId];
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

//只有返回YES才会继续调用API
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

#pragma mark - method for child
- (void)cleanData
{
    [self.cache clean];
    self.fetchedRawData = nil;
    self.errorMessage = nil;
    self.errorType = CTAPIManagerErrorTypeDefault;
    self.response = nil;
}

//如果需要在调用API之前额外添加一些参数，比如pageNumber和pageSize之类的就在这里添加
//子类中覆盖这个函数的时候就不需要调用[super reformParams:params]了
- (NSDictionary *)reformParams:(NSDictionary *)params
{
    IMP childIMP = [self.child methodForSelector:@selector(reformParams:)];
    IMP selfIMP = [self methodForSelector:@selector(reformParams:)];
    
    if (childIMP == selfIMP) {
        return params;
    } else {
        // 如果child是继承得来的，那么这里就不会跑到，会直接跑子类中的IMP。
        // 如果child是另一个对象，就会跑到这里
        NSDictionary *result = nil;
        result = [self.child reformParams:params];
        if (result) {
            return result;
        } else {
            return params;
        }
    }
}

#pragma mark - private methods
- (void)removeRequestIdWithRequestID:(NSInteger)requestId
{
    NSNumber *requestIDToRemove = nil;
    for (NSNumber *storedRequestId in self.requestIdList) {
        if ([storedRequestId integerValue] == requestId) {
            requestIDToRemove = storedRequestId;
        }
    }
    if (requestIDToRemove) {
        [self.requestIdList removeObject:requestIDToRemove];
    }
}

- (BOOL)loadCacheWithParams:(NSDictionary *)params
{
    NSString *serviceIdentifier = self.child.service.serviceIdentifier;
    NSString *methodName = self.child.methodName;
    CTService *service = self.child.service;
    NSData *result = [self.cache fetchCachedDataWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:params outdatedInterval:self.child.cacheOutdatedInterval];
    result = [self.child decryptCache:result];
    
    if (result == nil) {
        return NO;
    }
    
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
    NSString *serviceIdentifier = self.child.service.serviceIdentifier;
    NSString *methodName = self.child.methodName;
    NSData *result = [self.cache fetchCachedDataWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:params outdatedInterval:31536000]; // 本地数据，最多就是一年
    result = [self.child decryptCache:result];
    
    if (result == nil) {
        return NO;
    }
    
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

- (BOOL)isLoading
{
    if (self.requestIdList.count == 0) {
        _isLoading = NO;
    }
    return _isLoading;
}

- (BOOL)shouldLoadFromNative
{
    return NO;
}

- (NSData*)decryptCache:(NSData*)cache
{
    return cache;
}

- (NSData*)encryptCache:(NSData*)cache
{
    return cache;
}

- (BOOL)shouldCache
{
    return NO;
}

- (NSTimeInterval)cacheOutdatedInterval
{
    return 300;
}

@end
