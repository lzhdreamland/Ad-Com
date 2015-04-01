//
//  Created by ZihaoLin on 3/1/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface networkCheckManager : NSObject
+ (BOOL)hasConnectivity;
@end
