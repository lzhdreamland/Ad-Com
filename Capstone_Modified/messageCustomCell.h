//
//  messageCustomCell.h
//  Capstone_Modified
//
//  Created by ZihaoLin on 3/19/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface messageCustomCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *checkbox;
@property (weak, nonatomic) IBOutlet UILabel *messageIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageDetailLabel;

@end
