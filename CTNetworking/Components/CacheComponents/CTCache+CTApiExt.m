//
//  CTCache+CTApiExt.m
//  CTNetworking
//
//  Created by 廖朝瑞 on 2018/4/18.
//  Copyright © 2018年 Charlie. All rights reserved.
//

#import "CTCache+CTApiExt.h"
#import "NSDictionary+AXNetworkingMethods.h"
#import "NSString+AXNetworkingMethods.h"

@implementation CTCache (CTApiExt)

- (NSString *)keyWithServiceIdentifier:(NSString *)serviceIdentifier methodName:(NSString *)methodName requestParams:(id)requestParams
{
    NSString *paramsStr;
    if (requestParams != nil) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:requestParams];
        paramsStr = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        
        NSLog(@"requestParams--->\n%@\ndata--->\n%@\nparamsStr--->\n%@\n", requestParams, data, paramsStr);
    }
    
    if (paramsStr == nil) paramsStr = @"";
    
    return [NSString stringWithFormat:@"%@%@%@", serviceIdentifier, methodName, paramsStr].AX_md5;
}

- (NSData *)fetchCachedDataWithServiceIdentifier:(NSString *)serviceIdentifier
                                      methodName:(NSString *)methodName
                                   requestParams:(id)requestParams
                                outdatedInterval:(NSTimeInterval)interval
{
    return [self fetchCachedDataWithKey:[self keyWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:requestParams] outdatedInterval:interval];
}

- (void)saveCacheWithData:(NSData *)cachedData
        serviceIdentifier:(NSString *)serviceIdentifier
               methodName:(NSString *)methodName
            requestParams:(id)requestParams
             inMemoryOnly:(BOOL)memoryOnly
{
    [self saveCacheWithData:cachedData key:[self keyWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:requestParams] inMemoryOnly:memoryOnly];
}

- (void)deleteCacheWithServiceIdentifier:(NSString *)serviceIdentifier
                              methodName:(NSString *)methodName
                           requestParams:(id)requestParams
{
    [self deleteCacheWithKey:[self keyWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:requestParams]];
}

@end
