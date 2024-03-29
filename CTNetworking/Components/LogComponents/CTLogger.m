//
//  AXLogger.m
//  RTNetworking
//
//  Created by casa on 14-5-6.
//  Copyright (c) 2014年 casatwy. All rights reserved.
//

#import "CTLogger.h"
#import "NSObject+AXNetworkingMethods.h"
#import "NSMutableString+AXNetworkingMethods.h"
//#import "CTCommonParamsGenerator.h"
#import "NSArray+AXNetworkingMethods.h"
//#import "CTApiProxy.h"

@interface CTLogger ()

//@property (nonatomic, strong, readwrite) CTLoggerConfiguration *configParams;

@end

@implementation CTLogger

+ (void)logDebugInfoWithRequest:(NSURLRequest *)request apiName:(NSString *)apiName service:(CTService *)service requestParams:(id)requestParams httpMethod:(NSString *)httpMethod
{
    if (CTLogger.sharedInstance.isDebug) {
        BOOL isOnline = NO;
        if ([service respondsToSelector:@selector(isOnline)]) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[service methodSignatureForSelector:@selector(isOnline)]];
            invocation.target = service;
            invocation.selector = @selector(isOnline);
            [invocation invoke];
            [invocation getReturnValue:&isOnline];
        }
        
        NSMutableString *logString = [NSMutableString stringWithString:@"\n\n**************************************************************\n*                       Request Start                        *\n**************************************************************\n\n"];
        
        [logString appendFormat:@"API Name:\t\t%@\n", [apiName CT_defaultValue:@"N/A"]];
        [logString appendFormat:@"Method:\t\t\t%@\n", [httpMethod CT_defaultValue:@"N/A"]];
        [logString appendFormat:@"Version:\t\t%@\n", [service.apiVersion CT_defaultValue:@"N/A"]];
        [logString appendFormat:@"Service:\t\t%@\n", [service class]];
        [logString appendFormat:@"Status:\t\t\t%@\n", isOnline ? @"online" : @"offline"];
        [logString appendFormat:@"Public Key:\t\t%@\n", [service.publicKey CT_defaultValue:@"N/A"]];
        [logString appendFormat:@"Private Key:\t%@\n", [service.privateKey CT_defaultValue:@"N/A"]];
        [logString appendFormat:@"Params:\n%@", requestParams];
        
        [logString appendURLRequest:request];
        
        [logString appendFormat:@"\n\n**************************************************************\n*                         Request End                        *\n**************************************************************\n\n\n\n"];
        NSLog(@"%@", logString);
    }
}

+ (void)logDebugInfoWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data request:(NSURLRequest *)request error:(NSError *)error
{
    if (CTLogger.sharedInstance.isDebug) {
        BOOL shouldLogError = error ? YES : NO;
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSMutableString *logString = [NSMutableString stringWithString:@"\n\n==============================================================\n=                        API Response                        =\n==============================================================\n\n"];
        
        [logString appendFormat:@"Status:\t%ld\t(%@)\n\n", (long)response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];
        [logString appendFormat:@"Content:\n\t%@\n\n", responseString];
        if (shouldLogError) {
            [logString appendFormat:@"Error Domain:\t\t\t\t\t\t\t%@\n", error.domain];
            [logString appendFormat:@"Error Domain Code:\t\t\t\t\t\t%ld\n", (long)error.code];
            [logString appendFormat:@"Error Localized Description:\t\t\t%@\n", error.localizedDescription];
            [logString appendFormat:@"Error Localized Failure Reason:\t\t\t%@\n", error.localizedFailureReason];
            [logString appendFormat:@"Error Localized Recovery Suggestion:\t%@\n\n", error.localizedRecoverySuggestion];
        }
        
        [logString appendString:@"\n---------------  Related Request Content  --------------\n"];
        
        [logString appendURLRequest:request];
        
        [logString appendFormat:@"\n\n==============================================================\n=                        Response End                        =\n==============================================================\n\n\n\n"];
        
        NSLog(@"%@", logString);
    }
}

+ (void)logDebugInfoWithCachedResponse:(CTURLResponse *)response methodName:(NSString *)methodName serviceIdentifier:(CTService *)service
{
    if (CTLogger.sharedInstance.isDebug) {
        NSString *responseString = [[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding];
        
        NSMutableString *logString = [NSMutableString stringWithString:@"\n\n==============================================================\n=                      Cached Response                       =\n==============================================================\n\n"];
        
        [logString appendFormat:@"API Name:\t\t%@\n", [methodName CT_defaultValue:@"N/A"]];
        [logString appendFormat:@"Version:\t\t%@\n", [service.apiVersion CT_defaultValue:@"N/A"]];
        [logString appendFormat:@"Service:\t\t%@\n", [service class]];
        [logString appendFormat:@"Public Key:\t\t%@\n", [service.publicKey CT_defaultValue:@"N/A"]];
        [logString appendFormat:@"Private Key:\t%@\n", [service.privateKey CT_defaultValue:@"N/A"]];
        [logString appendFormat:@"Method Name:\t%@\n", methodName];
        [logString appendFormat:@"Params:\n%@\n\n", response.requestParams];
        [logString appendFormat:@"Content:\n\t%@\n\n", responseString];
        
        [logString appendFormat:@"\n\n==============================================================\n=                        Response End                        =\n==============================================================\n\n\n\n"];
        NSLog(@"%@", logString);
    }
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static CTLogger *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.isDebug = YES;
    });
    return sharedInstance;
}

//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//        self.configParams = [[CTLoggerConfiguration alloc] init];
//    }
//    return self;
//}

//- (void)logWithActionCode:(NSString *)actionCode params:(NSDictionary *)params
//{
//    NSMutableDictionary *actionDict = [[NSMutableDictionary alloc] init];
//    actionDict[@"act"] = actionCode;
//    [actionDict addEntriesFromDictionary:params];
//    [actionDict addEntriesFromDictionary:[CTCommonParamsGenerator commonParamsDictionaryForLog]];
//    NSDictionary *logJsonDict = @{self.configParams.sendActionKey:[@[actionDict] AX_jsonString]};
//    NSURLRequest *request = [self.configParams.requestGenerator generatePOSTRequestWithServiceIdentifier:self.configParams.service requestParams:logJsonDict methodName:self.configParams.sendActionMethod];
//    [[CTApiProxy sharedInstance] callApiWithRequest:request decrypt:nil success:nil fail:nil];
//}

@end
