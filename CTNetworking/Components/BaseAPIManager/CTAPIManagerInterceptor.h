//
//  CTAPIManagerInterceptor.h
//  CTNetworking
//
//  Created by CharlieLiao on 2017/12/13.
//  Copyright © 2017年 Charlie. All rights reserved.
//

#import <Foundation/Foundation.h>

/*************************************************************************************************/
/*                                    CTAPIManagerInterceptor                                    */
/*************************************************************************************************/
/// CTAPIBaseManager的派生类必须符合这些protocal
@protocol CTAPIManagerInterceptor <NSObject>

@optional
- (BOOL)manager:(CTAPIBaseManager * _Nonnull)manager beforePerformSuccessWithResponse:(CTURLResponse *_Nonnull)response;
- (void)manager:(CTAPIBaseManager * _Nonnull)manager afterPerformSuccessWithResponse:(CTURLResponse *_Nonnull)response;

- (BOOL)manager:(CTAPIBaseManager * _Nonnull)manager beforePerformFailWithResponse:(CTURLResponse *_Nonnull)response;
- (void)manager:(CTAPIBaseManager * _Nonnull)manager afterPerformFailWithResponse:(CTURLResponse *_Nonnull)response;

- (BOOL)manager:(CTAPIBaseManager * _Nonnull)manager shouldCallAPIWithParams:(NSDictionary * _Nullable)params;
- (void)manager:(CTAPIBaseManager * _Nonnull)manager afterCallingAPIWithParams:(NSDictionary * _Nullable)params;

@end
