//
//  AXRequestGenerator.h
//  RTNetworking
//
//  Created by casa on 14-5-14.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

typedef id<NSCoding> ParamValue NS_SWIFT_UNAVAILABLE("");

#import "CTService.h"

NS_SWIFT_UNAVAILABLE("")
@protocol CTRequestGenerator <NSObject>

- (nullable NSURLRequest *)generateGETRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary <NSString*, ParamValue>*)requestParams methodName:(nonnull NSString *)methodName;

- (nullable NSURLRequest *)generatePOSTRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary <NSString*, ParamValue>*)requestParams methodName:(nonnull NSString *)methodName;

- (nullable NSURLRequest *)generatePutRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary <NSString*, ParamValue>*)requestParams methodName:(nonnull NSString *)methodName;

- (nullable NSURLRequest *)generateDeleteRequestWithServiceIdentifier:(nonnull CTService*)service requestParams:(nullable NSDictionary <NSString*, ParamValue>*)requestParams methodName:(nonnull NSString *)methodName;

@end
