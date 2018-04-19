//
//  CTAPIManagerCallBackDelegate.h
//  CTNetworking
//
//  Created by CharlieLiao on 2017/12/13.
//  Copyright © 2017年 Charlie. All rights reserved.
//

#import <Foundation/Foundation.h>

/*************************************************************************************************/
/*                               CTAPIManagerApiCallBackDelegate                                 */
/*************************************************************************************************/
@class CTAPIBaseManager;
//api回调
NS_SWIFT_UNAVAILABLE("")
@protocol CTAPIManagerCallBackDelegate
@required
- (void)managerCallAPIDidSuccess:(CTAPIBaseManager * _Nonnull)manager;
- (void)managerCallAPIDidFailed:(CTAPIBaseManager * _Nonnull)manager;
@end
