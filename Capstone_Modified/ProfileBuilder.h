//
//  ProfileBuilder.h
//  Capstone_Modified
//
//  Created by ZihaoLin on 2/14/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Profile.h"

@interface ProfileBuilder : NSObject
+ (Profile *)profileFromJsonArray:(NSArray *)jsonArry;
@end
