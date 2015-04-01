//
//  CreateMessageViewController.h
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/20/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//
@import MultipeerConnectivity;

#import <UIKit/UIKit.h>
#import "SessionManager.h"
#import <CoreLocation/CoreLocation.h>

@protocol CreateMessageDidFinishProtocol
- (void) createMessageDidFinish:(id) sender;
@end

@interface CreateMessageViewController : UIViewController
@property (strong,nonatomic) id <SessionClientProtocol,CreateMessageDidFinishProtocol> delegate;
@property (strong,nonatomic) SessionManager *sessionMngr;
@end
