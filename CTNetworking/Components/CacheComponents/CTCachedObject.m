//
//  CTCachedObject.m
//  RTNetworking
//
//  Created by casa on 14-5-26.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import "CTCachedObject.h"

@interface CTCachedObject ()

@property (nonatomic, copy, readwrite) NSData *content;
@property (nonatomic, copy, readwrite) NSDate *lastUpdateTime;

@end

@implementation CTCachedObject

#pragma mark - getters and setters
- (BOOL)isEmpty
{
    return self.content == nil;
}

- (void)setContent:(NSData *)content
{
    _content = [content copy];
    self.lastUpdateTime = [NSDate dateWithTimeIntervalSinceNow:0];
}

#pragma mark - life cycle

- (instancetype)initWithContent:(NSData *)content
{
    self = [super init];
    if (self) {
        self.content = content;
    }
    return self;
}

#pragma mark -

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_content forKey:@"content"];
    [aCoder encodeObject:_lastUpdateTime forKey:@"lastUpdateTime"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _content = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"content"];
        _lastUpdateTime = [aDecoder decodeObjectOfClass:NSDate.class forKey:@"lastUpdateTime"];
    }
    return self;
}

#pragma mark - public method

- (void)updateContent:(NSData *)content
{
    self.content = content;
}

@end
