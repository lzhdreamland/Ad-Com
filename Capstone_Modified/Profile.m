//
//  Profile.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/16/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "Profile.h"

@implementation Profile
#pragma mark - 'Coder' methods
- (id)initWithCoder:(NSCoder *)aDecoder{
  NSLog(@"Profile initWithCoder");
  
  self = [super init];
  if (self) {
    self.profileName = [aDecoder decodeObjectForKey:@"profileName"];
    self.contactList = [aDecoder decodeObjectForKey:@"contactList"];
  }
  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
  NSLog(@"Profile encodeWithCoder");
  
  [aCoder encodeObject:self.profileName forKey:@"profileName"];
  [aCoder encodeObject:self.contactList forKey:@"contactList"];
}
@end//Profile
