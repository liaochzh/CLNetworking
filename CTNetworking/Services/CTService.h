//
//  AXService.h
//  RTNetworking
//
//  Created by casa on 14-5-15.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import <Foundation/Foundation.h>

// 所有CTService的派生类都要符合这个protocol
@protocol CTServiceProtocol 

@property (nonatomic, readonly, nonnull) NSString *offlineApiBaseUrl;
@property (nonatomic, readonly, nonnull) NSString *onlineApiBaseUrl;

@optional

@property (nonatomic, readonly) BOOL isOnline;

@property (nonatomic, readonly, nonnull) NSString *offlineApiVersion;
@property (nonatomic, readonly, nonnull) NSString *onlineApiVersion;

@property (nonatomic, readonly, nonnull) NSString *onlinePublicKey;
@property (nonatomic, readonly, nonnull) NSString *offlinePublicKey;

@property (nonatomic, readonly, nonnull) NSString *onlinePrivateKey;
@property (nonatomic, readonly, nonnull) NSString *offlinePrivateKey;

@end

@interface CTService : NSObject

@property (nonatomic, readonly, nonnull) NSString *serviceIdentifier;
@property (nonatomic, strong, readonly, nonnull) NSString *publicKey;
@property (nonatomic, strong, readonly, nonnull) NSString *privateKey;
@property (nonatomic, strong, readonly, nonnull) NSString *apiBaseUrl;
@property (nonatomic, strong, readonly, nonnull) NSString *apiVersion;

@property (nonatomic, weak, nullable) id<CTServiceProtocol> child;

@end
