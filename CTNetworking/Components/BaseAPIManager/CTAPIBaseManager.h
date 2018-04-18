//
//  AJKBaseManager.h
//  casatwy2
//
//  Created by casa on 13-12-2.
//  Copyright (c) 2013年 casatwy inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTURLResponse.h"
#import "CTAPIManagerCallBackDelegate.h"
#import "CTAPIManagerDataReformer.h"
#import "CTAPIManagerValidator.h"
#import "CTAPIManagerParamSource.h"
#import "CTAPIManager.h"
#import "CTAPIManagerInterceptor.h"

/*
 当产品要求返回数据不正确或者为空的时候显示一套UI，请求超时和网络不通的时候显示另一套UI时，使用这个enum来决定使用哪种UI。（安居客PAD就有这样的需求，sigh～）
 你不应该在回调数据验证函数里面设置这些值，事实上，在任何派生的子类里面你都不应该自己设置manager的这个状态，baseManager已经帮你搞定了。
 强行修改manager的这个状态有可能会造成程序流程的改变，容易造成混乱。
 */
typedef NS_ENUM (NSUInteger, CTAPIManagerErrorType) {
    CTAPIManagerErrorTypeDefault,       //没有产生过API请求，这个是manager的默认状态。
    CTAPIManagerErrorTypeSuccess,       //API请求成功且返回数据正确，此时manager的数据是可以直接拿来使用的。
    CTAPIManagerErrorTypeNoContent,     //API请求成功但返回数据不正确。如果回调数据验证函数返回值为NO，manager的状态就会是这个。
    CTAPIManagerErrorTypeParamsError,   //参数错误，此时manager不会调用API，因为参数验证是在调用API之前做的。
    CTAPIManagerErrorTypeNoRequest,     //生成请求错误，此时manager不会调用API
    CTAPIManagerErrorTypeTimeout,       //请求超时。CTAPIProxy设置的是20秒超时，具体超时时间的设置请自己去看CTAPIProxy的相关代码。
    CTAPIManagerErrorTypeNoNetWork      //网络不通。在调用API之前会判断一下当前网络是否通畅，这个也是在调用API之前验证的，和上面超时的状态是有区别的。
};


enum {
    kNilRequestID = 0
};


/*************************************************************************************************/
/*                                       CTAPIBaseManager                                        */
/*************************************************************************************************/
/**
 总述：
 这个base manager是用于给外部访问API的时候做的一个基类。
 外界在使用manager的时候，如果需要调api，只要调用loadData即可。manager会去找paramSource来获得调用api的参数。调用成功或失败，则会调用delegate的回调函数。
 继承的子类manager可以重载basemanager提供的一些方法，来实现一些扩展功能。具体的可以看m文件里面对应方法的注释。
 */
@interface CTAPIBaseManager : NSObject

@property (nonatomic, weak, nullable) id<CTAPIManagerCallBackDelegate> delegate;
@property (nonatomic, weak, nullable) id<CTAPIManagerParamSource> paramSource;
///
@property (nonatomic, weak, nullable) id<CTAPIManagerValidator> validator;
/// 里面会调用到NSObject的方法，所以这里不用id
@property (nonatomic, weak, nullable) NSObject<CTAPIManager> *child;
/// 拦截器，拦截后不会进入成功或失败回调
@property (nonatomic, weak, nullable) id<CTAPIManagerInterceptor> interceptor;

/**
 baseManager是不会去设置errorMessage的，派生的子类manager可能需要给controller提供错误信息。所以为了统一外部调用的入口，设置了这个变量。
 派生的子类需要通过extension来在保证errorMessage在对外只读的情况下使派生的manager子类对errorMessage具有写权限。
 */
@property (nonatomic, copy, readonly, nullable) NSString *errorMessage;
@property (nonatomic, readonly) CTAPIManagerErrorType errorType;
@property (nonatomic, strong, nullable) CTURLResponse *response;

@property (nonatomic, assign, readonly) BOOL isReachable;
@property (nonatomic, assign, readonly) BOOL isLoading;

- (id _Nullable)fetchDataWithReformer:(id<CTAPIManagerDataReformer> _Nullable)reformer;

/// 尽量使用loadData这个方法,这个方法会通过param source来获得参数，这使得参数的生成逻辑位于controller中的固定位置
- (NSUInteger)loadData;
- (NSUInteger)loadDataWithParams:(NSDictionary <NSString*, id<NSCoding>>* _Nullable)params;

- (void)cancelAllRequests;
- (void)cancelRequestWithRequestId:(NSUInteger)requestID;

// 拦截器方法，继承之后需要调用一下super

- (BOOL)shouldCallAPIWithParams:(NSDictionary <NSString*,id<NSCoding>>* _Nullable)params;
- (void)afterCallingAPIWithParams:(NSDictionary <NSString*,id<NSCoding>>* _Nullable)params;

- (BOOL)beforePerformSuccessWithResponse:(CTURLResponse *_Nonnull)response;
- (void)afterPerformSuccessWithResponse:(CTURLResponse *_Nonnull)response;

- (BOOL)beforePerformFailWithResponse:(CTURLResponse *_Nonnull)response;
- (void)afterPerformFailWithResponse:(CTURLResponse *_Nonnull)response;


@end


/// 在调用成功之后的params字典里面，用这个key可以取出requestID
extern NSString * _Nonnull const kCTAPIBaseManagerRequestID;

