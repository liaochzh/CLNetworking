//
//  CTCache.m
//  RTNetworking
//
//  Created by casa on 14-5-26.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import "CTCache.h"
#import "CTCachedObject.h"

@interface CTCache () {
    NSCache *_cache;
}

@property (nonatomic, readonly) NSCache *cache;

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

- (NSData *)fetchCachedDataWithKey:(NSString *)key outdatedInterval:(NSTimeInterval)interval
{
    CTCachedObject *cachedObject = [self.cache objectForKey:key];
    
    if (cachedObject == nil) { //
        NSString *filePath = [CTCache cacheFilePath:key];
        cachedObject = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }
    
    if (cachedObject) {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:cachedObject.lastUpdateTime];
        if (timeInterval < interval)
            return cachedObject.content;
        else
            [self deleteCacheWithKey:key];
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
//        // 本地存储
//        NSString *cacheFolderPath = [CTCache cacheFolderPath];
//
//        // 文件夹未存在，先创建文件夹
//        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFolderPath] == false)
//            [[NSFileManager defaultManager] createDirectoryAtPath:cacheFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        // 保存缓存
        NSString *filePath = [CTCache cacheFilePath:key];
        if ([NSKeyedArchiver archiveRootObject:cachedObject toFile:filePath]) {
            NSLog(@"cache archive 成功");
        } else {
            NSLog(@"cache archive 失败 -->%@", filePath);
        }
    }
}

- (void)deleteCacheWithKey:(NSString *)key
{
    [self.cache removeObjectForKey:key];
    [[NSFileManager defaultManager] removeItemAtPath:[CTCache cacheFilePath:key] error:nil];
}

- (void)clean
{
    [self.cache removeAllObjects];
    NSString *cacheFolderPath = [CTCache cacheFolderPath];
    [[NSFileManager defaultManager] removeItemAtPath:cacheFolderPath error:nil];
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
