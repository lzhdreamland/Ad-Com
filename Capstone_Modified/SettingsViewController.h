//
//  MeViewController.h
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/16/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import <UIKit/UIKit.h>

//@protocol SettingsChangedDelegateProtocol
//- (void) advertiserStatusChanged:(id) sender;
//@end

@protocol SettingsLogoutProtocol
- (void) logoutCurrentUser: (id) sender;
@end

@interface SettingsViewController : UITableViewController
@property (weak,nonatomic) id <SettingsLogoutProtocol> delegate;
@property (strong,nonatomic) NSNumber *advertiseStatus;

@end
