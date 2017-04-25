//
//  CTCache.m
//  RTNetworking
//
//  Created by casa on 14-5-26.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import "CTCache.h"
#import "NSDictionary+AXNetworkingMethods.h"
#import "NSString+AXNetworkingMethods.h"

@interface CTCache ()

@property (nonatomic, strong) NSCache *cache;

@end

@implementation CTCache

#pragma mark - getters and setters
- (NSCache *)cache
{
    if (_cache == nil) {
        _cache = [[NSCache alloc] init];
        _cache.countLimit = 500;
    }
    return _cache;
}

#pragma mark - life cycle
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static CTCache *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CTCache alloc] init];
    });
    return sharedInstance;
}

#pragma mark - public method

- (NSData *)fetchCachedDataWithServiceIdentifier:(NSString *)serviceIdentifier
                                      methodName:(NSString *)methodName
                                   requestParams:(NSDictionary *)requestParams
                                outdatedInterval:(NSTimeInterval)interval
{
    NSLog(@"fetchCachedDataWithServiceIdentifier->%@ %@ %@", serviceIdentifier, methodName, requestParams);
    
    return [self fetchCachedDataWithKey:[self keyWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:requestParams] outdatedInterval:interval];
}

- (void)saveCacheWithData:(NSData *)cachedData
        serviceIdentifier:(NSString *)serviceIdentifier
               methodName:(NSString *)methodName
            requestParams:(NSDictionary *)requestParams
             inMemoryOnly:(BOOL)memoryOnly
{
    NSLog(@"fetchCachedDataWithServiceIdentifier->%@ %@ %@", serviceIdentifier, methodName, requestParams);
    [self saveCacheWithData:cachedData key:[self keyWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:requestParams] inMemoryOnly:memoryOnly];
}

- (void)deleteCacheWithServiceIdentifier:(NSString *)serviceIdentifier
                              methodName:(NSString *)methodName
                           requestParams:(NSDictionary *)requestParams
{
    [self deleteCacheWithKey:[self keyWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:requestParams]];
}

- (NSData *)fetchCachedDataWithKey:(NSString *)key outdatedInterval:(NSTimeInterval)interval
{
    CTCachedObject *cachedObject = [self.cache objectForKey:key];
    
    if (cachedObject == nil) { //
        NSString *filePath = [CTCache cacheFilePath:key];
        
        cachedObject = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }
    
    if (cachedObject) {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:cachedObject.lastUpdateTime];
        if (timeInterval < interval) {
            return cachedObject.content;
        }
    }
    return nil;
}

- (void)saveCacheWithData:(NSData *)cachedData key:(NSString *)key inMemoryOnly:(BOOL)memoryOnly
{
    CTCachedObject *cachedObject = [self.cache objectForKey:key];
    
    if (cachedObject == nil) {
        cachedObject = [[CTCachedObject alloc] initWithContent:cachedData];
    } else {
        [cachedObject updateContent:cachedData];
    }
    
    [self.cache setObject:cachedObject forKey:key];
    
    if (memoryOnly == false) {
        // 本地存储
        NSString *cacheFolderPath = [CTCache cacheFolderPath];
        // 文件夹未存在，先创建文件夹
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFolderPath] == false)
            [[NSFileManager defaultManager] createDirectoryAtPath:cacheFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
        // 保存缓存
        NSString *filePath = [cacheFolderPath stringByAppendingPathComponent:key];
        [NSKeyedArchiver archiveRootObject:cachedObject toFile:filePath];
    }
}

- (void)deleteCacheWithKey:(NSString *)key
{
    [self.cache removeObjectForKey:key];
}

- (void)clean
{
    [self.cache removeAllObjects];
}

- (NSString *)keyWithServiceIdentifier:(NSString *)serviceIdentifier methodName:(NSString *)methodName requestParams:(NSDictionary *)requestParams
{
    return [NSString stringWithFormat:@"%@%@%@", serviceIdentifier, methodName, [requestParams CT_urlParamsStringSignature:NO]].AX_md5;
}

#pragma mark - private method

+ (NSString *)cacheFolderPath
{
    NSString *cachesDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    
    return [cachesDirectoryPath stringByAppendingPathComponent:@"CTCache"];
}

+ (NSString *)cacheFilePath:(NSString*)key
{
    NSString *cachePath = [[CTCache cacheFolderPath] stringByAppendingPathComponent:key];
    return cachePath;
}

@end
