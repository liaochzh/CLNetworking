//
//  CTLogConfig.h
//  CTLogTrackCenter
//
//  Created by Softwind.Tang on 14-5-15.
//  Copyright (c) 2014年 casatwy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTService.h"
#import "CTRequestGenerator.h"

@interface CTLoggerConfiguration : NSObject

/** 渠道ID */
@property (nonatomic, strong) NSString *channelID;

/** app标志 */
@property (nonatomic, strong) NSString *appKey;

/** app名字 */
@property (nonatomic, strong) NSString *logAppName;

/** 服务器 */
@property (nonatomic, strong) CTService *service;

/** 服务器 */
@property (nonatomic, strong) id<CTRequestGenerator> requestGenerator;

/** 记录log用到的webapi方法名 */
@property (nonatomic, strong) NSString *sendLogMethod;

/** 记录action用到的webapi方法名 */
@property (nonatomic, strong) NSString *sendActionMethod;

/** 发送log时使用的key */
@property (nonatomic, strong) NSString *sendLogKey;

/** 发送Action记录时使用的key */
@property (nonatomic, strong) NSString *sendActionKey;


@end
