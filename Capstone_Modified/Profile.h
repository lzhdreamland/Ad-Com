//
//  Profile.h
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/16/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Profile : NSObject<NSCoding>
@property (assign,nonatomic) NSString *profileName;
@property (strong,nonatomic) NSArray *contactList;
@end
