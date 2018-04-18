//
//  CTCache+CTApiExt.h
//  CTNetworking
//
//  Created by 廖朝瑞 on 2018/4/18.
//  Copyright © 2018年 Charlie. All rights reserved.
//

#import "CTCache.h"

@interface CTCache (CTApiExt)

- (NSString *)keyWithServiceIdentifier:(NSString *)serviceIdentifier
                            methodName:(NSString *)methodName
                         requestParams:(NSDictionary *)requestParams;


- (NSData *)fetchCachedDataWithServiceIdentifier:(NSString *)serviceIdentifier
                                      methodName:(NSString *)methodName
                                   requestParams:(NSDictionary *)requestParams
                                outdatedInterval:(NSTimeInterval)interval;

- (void)saveCacheWithData:(NSData *)cachedData
        serviceIdentifier:(NSString *)serviceIdentifier
               methodName:(NSString *)methodName
            requestParams:(NSDictionary *)requestParams
             inMemoryOnly:(BOOL)memoryOnly;

- (void)deleteCacheWithServiceIdentifier:(NSString *)serviceIdentifier
                              methodName:(NSString *)methodName
                           requestParams:(NSDictionary *)requestParams;

@end
