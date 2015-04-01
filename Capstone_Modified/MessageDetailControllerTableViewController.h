//
//  MessageDetailControllerTableViewController.h
//  Capstone_Modified
//
//  Created by ZihaoLin on 2/16/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol messageDetailDisappearProtocol
- (void)messageDetailDisappearTransmissionDidFinish:(BOOL) receivedOrSend;
@end

@interface MessageDetailControllerTableViewController : UITableViewController
@property (strong,nonatomic) NSString *messageId;
@property (assign,nonatomic) BOOL receivedOrSent;
@end
