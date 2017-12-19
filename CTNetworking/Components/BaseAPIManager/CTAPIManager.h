//
//  CTAPIManager.h
//  CTNetworking
//
//  Created by CharlieLiao on 2017/12/13.
//  Copyright © 2017年 Charlie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTService.h"
#import "CTRequestGenerator.h"

typedef NS_ENUM (NSUInteger, CTAPIManagerRequestType){
    CTAPIManagerRequestTypeGet,
    CTAPIManagerRequestTypePost,
    CTAPIManagerRequestTypePut,
    CTAPIManagerRequestTypeDelete
};

/*************************************************************************************************/
/*                                         CTAPIManager                                          */
/*************************************************************************************************/
@protocol CTAPIManager <NSObject>

@required
- (NSString * _Nonnull)methodName;
- (CTAPIManagerRequestType)requestType;
- (CTService * _Nonnull)service;
- (id<CTRequestGenerator> _Nonnull)requestGenerator;

// used for pagable API Managers mainly
@optional

/**
 是否加载缓存数据（加载缓存将不再请求服务器）
 */
- (BOOL)shouldCache;

/**
 缓存超时间隔(默认300秒)
 */
- (NSTimeInterval)cacheOutdatedInterval;

- (void)cleanData;

- (NSDictionary <NSString*,id>* _Nullable)reformParams:(NSDictionary <NSString*,id>* _Nullable)params;

/**
 是否需要加载本地数据
 */
- (BOOL)shouldLoadFromNative;

/**
 解密Response 内容
 @param response 待解密的Response
 @return 返回已解密的Response
 */
- (NSData *_Nullable)decryptResponse:(NSData* _Nullable)response;

/**
 本地存储解密cache
 @param cache 待解密的cache
 @return 返回已解密的cache
 */
- (NSData* _Nullable)decryptCache:(NSData* _Nullable)cache;

/**
 本地存储加密cache(确保数据存储的安全性)
 @param cache 待加密的cache
 @return 返回已加密的cache
 */
- (NSData* _Nullable)encryptCache:(NSData* _Nullable)cache;

@end
