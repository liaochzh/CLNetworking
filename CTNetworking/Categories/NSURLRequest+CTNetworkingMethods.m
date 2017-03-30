//
//  NSURLRequest+CTNetworkingMethods.m
//  RTNetworking
//
//  Created by casa on 14-5-26.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import "NSURLRequest+CTNetworkingMethods.h"
#import <objc/runtime.h>

static void *CTNetworkingRequestParams;
static void *CTNetworkingDecryptRespContent;

@implementation NSURLRequest (CTNetworkingMethods)

- (void)setRequestParams:(NSDictionary *)requestParams
{
    objc_setAssociatedObject(self, &CTNetworkingRequestParams, requestParams, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *)requestParams
{
    return objc_getAssociatedObject(self, &CTNetworkingRequestParams);
}

- (void)setDecryptResponseContent:(NSData *(^)(NSData *))decryptResponseContent
{
    objc_setAssociatedObject(self, &CTNetworkingDecryptRespContent, decryptResponseContent, OBJC_ASSOCIATION_COPY);
}

- (NSData *(^)(NSData *))decryptResponseContent
{
    return objc_getAssociatedObject(self, &CTNetworkingDecryptRespContent);
}

@end
