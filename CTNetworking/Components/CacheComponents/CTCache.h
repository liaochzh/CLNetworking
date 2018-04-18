//
//  CTCache.h
//  RTNetworking
//
//  Created by casa on 14-5-26.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTCache : NSObject

+ (instancetype)sharedInstance;

- (NSData *)fetchCachedDataWithKey:(NSString *)key outdatedInterval:(NSTimeInterval)interval;

- (void)saveCacheWithData:(NSData *)cachedData key:(NSString *)key inMemoryOnly:(BOOL)memoryOnly;

- (void)deleteCacheWithKey:(NSString *)key;

- (void)clean;

@end
