//
//  CTAPIManagerParamSource.h
//  CTNetworking
//
//  Created by CharlieLiao on 2017/12/13.
//  Copyright © 2017年 Charlie. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CTAPIBaseManager;

/*************************************************************************************************/
/*                                CTAPIManagerParamSourceDelegate                                */
/*************************************************************************************************/
/// 让manager能够获取调用API所需要的数据
NS_SWIFT_UNAVAILABLE("")
@protocol CTAPIManagerParamSource

@required
- (NSDictionary <NSString*, id<NSCoding>>* _Nullable)paramsForApi:(CTAPIBaseManager * _Nonnull)manager;


@end
