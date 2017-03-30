//
//  AXRequestGenerator.h
//  RTNetworking
//
//  Created by casa on 14-5-14.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import "CTService.h"

@protocol CTRequestGenerator <NSObject>

- (nullable NSURLRequest *)generateGETRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary *)requestParams methodName:(nonnull NSString *)methodName;

- (nullable NSURLRequest *)generatePOSTRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary *)requestParams methodName:(nonnull NSString *)methodName;

- (nullable NSURLRequest *)generatePutRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary *)requestParams methodName:(nonnull NSString *)methodName;

- (nullable NSURLRequest *)generateDeleteRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary *)requestParams methodName:(nonnull NSString *)methodName;

@optional
- (NSData* _Nullable(^ _Nullable)( NSData* _Nullable))decryptResponseContent;

@end
