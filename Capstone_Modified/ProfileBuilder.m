//
//  ProfileBuilder.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 2/14/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "ProfileBuilder.h"

@implementation ProfileBuilder
+ (Profile *)profileFromJsonArray:(NSArray *)jsonArry{
  /*
   jsonArry[0] --> profileName;
   jsonArry[1] --> contactList(* NSArray);
   */
  Profile *profile = [[Profile alloc] init];
  profile.profileName = [jsonArry objectAtIndex:0];
  profile.contactList = [jsonArry objectAtIndex:1];
  
  return profile;
}
@end
