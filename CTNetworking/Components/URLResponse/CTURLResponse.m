//
//  AXURLResponse.m
//  RTNetworking
//
//  Created by casa on 14-5-18.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import "CTURLResponse.h"
#import "NSObject+AXNetworkingMethods.h"
#import "NSURLRequest+CTNetworkingMethods.h"

@interface CTURLResponse () {
    NSString *_contentString;
    id _content;
}

@property (nonatomic, assign, readwrite) CTURLResponseStatus status;
//@property (nonatomic, copy, readwrite) NSString *contentString;
//@property (nonatomic, copy, readwrite) id content;
@property (nonatomic, copy, readwrite) NSURLRequest *request;
@property (nonatomic, assign, readwrite) NSInteger requestId;
@property (nonatomic, copy, readwrite) NSData *responseData;
@property (nonatomic, assign, readwrite) BOOL isCache;
@property (nonatomic, copy, readwrite) NSError *error;

@end

@implementation CTURLResponse

#pragma mark - life cycle
- (instancetype)initWithRequestId:(NSNumber *)requestId request:(NSURLRequest *)request responseData:(NSData *)responseData status:(CTURLResponseStatus)status
{
    self = [super init];
    if (self) {
        self.status = status;
        self.requestId = [requestId integerValue];
        self.request = request;
        self.responseData = responseData;
        self.requestParams = request.requestParams;
        self.isCache = NO;
    }
    return self;
}

- (instancetype)initWithRequestId:(NSNumber *)requestId request:(NSURLRequest *)request responseData:(NSData *)responseData error:(NSError *)error
{
    CTURLResponseStatus status = [[self class] responseStatusWithError:error];
    if (self = [self initWithRequestId:requestId request:request responseData:responseData status:status])
        self.error = error;
    return self;
}

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        self.status = CTURLResponseStatusSuccess;
        self.requestId = 0;
        self.request = nil;
        self.responseData = data;
        self.isCache = YES;
    }
    return self;
}

#pragma mark - private methods
+ (CTURLResponseStatus)responseStatusWithError:(NSError *)error
{
    if (error) {
        CTURLResponseStatus result;
        // 除了超时以外，所有错误都当成是无网络
        if (error.code == NSURLErrorTimedOut)
            result = CTURLResponseStatusErrorNoNetwork;
        else
            result = CTURLResponseStatusErrorNoNetwork;
        return result;
    } else {
        return CTURLResponseStatusSuccess;
    }
}

#pragma mark - get / set 

- (NSString *)contentString {
    if (_responseData != nil && _contentString == nil) {
        _contentString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    }
    return _contentString;
}

- (id)content {
    if (_responseData != nil && _content == nil) {
        _content = [NSJSONSerialization JSONObjectWithData:_responseData options:NSJSONReadingMutableContainers error:NULL];
    }
    return _content;
}

@end
