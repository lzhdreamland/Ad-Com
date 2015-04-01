//
//  ServiceConnector.h
//  workWithServerTemplate
//
//  Created by ZihaoLin on 3/8/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol ServiceConnectorDelegate <NSObject>
-(void)requestReturnedDataToLogin:(NSData*)data;
-(void)requestReturnedDataToRegister:(NSData *)data;
-(void)requestReturnedDataToUpdateLocalDb:(NSData *)data;
-(void)requestReturnedDataToUploadMessages:(NSData *)data;
-(void)requestReturnedDataToDownloadMessages:(NSData *)data;
@end


@interface ServiceConnector : NSObject<NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (strong,nonatomic) id<ServiceConnectorDelegate> delegate;

- (void)loginFunUseUserName:(NSString *)username andPassword:(NSString *)password;
- (void)registerFunUserName:(NSString *)userName andPassword:(NSString *)password;
- (void)requestUserInfoWithUserName:(NSString *)user_name;
- (void)uploadMessagesToCloud:(NSArray *)messages withMessageType:(NSString *)message_type;
- (void)downloadMessagesFromCloudDbWithUserName:(NSString *)user_name;
@end
