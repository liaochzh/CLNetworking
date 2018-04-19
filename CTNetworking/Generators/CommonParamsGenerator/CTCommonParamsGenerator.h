//
//  AXPublicURLParamsGenerator.h
//  RTNetworking
//
//  Created by casa on 14-5-6.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_SWIFT_UNAVAILABLE("")
@interface CTCommonParamsGenerator : NSObject

+ (NSDictionary <NSString*,id>*)commonParamsDictionary;
+ (NSDictionary <NSString*,id>*)commonParamsDictionaryForLog;

@end
