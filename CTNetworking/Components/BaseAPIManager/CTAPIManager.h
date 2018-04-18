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

/**
 调用API之前额外添加一些参数,但不应该在这个函数里面修改已有的参数。
 所以这里返回的参数字典还是会被后面的验证函数去验证的。
 
 假设同一个翻页Manager，ManagerA的paramSource提供page_size=15参数，ManagerB的paramSource提供page_size=2参数
 如果在这个函数里面将page_size改成10，那么最终调用API的时候，page_size就变成10了。然而外面却觉察不到这一点，因此这个函数要慎用。
 
 这个函数的适用场景：
 当两类数据走的是同一个API时，为了避免不必要的判断，我们将这一个API当作两个API来处理。
 那么在传递参数要求不同的返回时，可以在这里给返回参数指定类型。
 */
- (NSDictionary <NSString*, id<NSCoding>>* _Nullable)reformParams:(NSDictionary <NSString*, id<NSCoding>>* _Nullable)params;

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
