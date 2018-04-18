//
//  AXRequestGenerator.h
//  RTNetworking
//
//  Created by casa on 14-5-14.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

typedef id<NSCoding> ParamType;

#import "CTService.h"

@protocol CTRequestGenerator <NSObject>

- (nullable NSURLRequest *)generateGETRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary <NSString*, ParamType>*)requestParams methodName:(nonnull NSString *)methodName;

- (nullable NSURLRequest *)generatePOSTRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary <NSString*, ParamType>*)requestParams methodName:(nonnull NSString *)methodName;

- (nullable NSURLRequest *)generatePutRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary <NSString*, ParamType>*)requestParams methodName:(nonnull NSString *)methodName;

- (nullable NSURLRequest *)generateDeleteRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary <NSString*, ParamType>*)requestParams methodName:(nonnull NSString *)methodName;

@end
