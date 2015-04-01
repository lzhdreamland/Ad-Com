//
//  SecondViewController.h
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/4/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//
@import MultipeerConnectivity;

#import <UIKit/UIKit.h>
#import "SessionManager.h"
#import "SettingsViewController.h"

@protocol ConnectivityDelegateProtocol
- (void) connectivityControllerDidFinish: (id) sender;
@end

@interface ConnectivityViewController : UIViewController<SettingsLogoutProtocol>
@property (strong,nonatomic) id<SessionClientProtocol> delegate;
@property (strong,nonatomic) SessionManager *sessionMngr;
@end

