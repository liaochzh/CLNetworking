//
//  AXURLResponse.h
//  RTNetworking
//
//  Created by casa on 14-5-18.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CTURLResponseStatus)
{
    CTURLResponseStatusSuccess, //作为底层，请求是否成功只考虑是否成功收到服务器反馈。至于签名是否正确，返回的数据是否完整，由上层的CTAPIBaseManager来决定。
    CTURLResponseStatusErrorTimeout,
    CTURLResponseStatusErrorNoNetwork // 默认除了超时以外的错误都是无网络错误。
};

@interface CTURLResponse : NSObject

@property (nonatomic, assign, readonly) CTURLResponseStatus status;

@property (nonatomic, assign, readonly) NSInteger requestId;
@property (nonatomic, copy, readonly) NSURLRequest *request;
@property (nonatomic, copy) NSDictionary <NSString*, id>*requestParams;

@property (nonatomic, assign, readonly) BOOL isCache;

@property (nonatomic, copy, readonly) NSData *responseData;
@property (nonatomic, copy, readonly) id content NS_SWIFT_UNAVAILABLE("");

@property (nonatomic, copy, readonly) NSError *error;

- (instancetype)initWithRequestId:(NSInteger)requestId request:(NSURLRequest *)request responseData:(NSData *)responseData status:(CTURLResponseStatus)status;
- (instancetype)initWithRequestId:(NSInteger)requestId request:(NSURLRequest *)request responseData:(NSData *)responseData error:(NSError *)error;

// 使用initWithData的response，它的isCache是YES，上面两个函数生成的response的isCache是NO
- (instancetype)initWithData:(NSData *)data;

@end
