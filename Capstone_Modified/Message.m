//
//  Message.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/24/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "Message.h"

@implementation Message
#pragma mark - 'Coder' methods
- (id)initWithCoder:(NSCoder *)aDecoder{
  NSLog(@"Message initWithCoder");
  
  self = [super init];
  if (self) {
    self.messageId = [aDecoder decodeObjectForKey:@"messageId"];
    self.textContent = [aDecoder decodeObjectForKey:@"textContent"];
    self.protocolType = [aDecoder decodeObjectForKey:@"protocolType"];
    self.destPeerName = [aDecoder decodeObjectForKey:@"destPeerName"];
    self.hopList = [aDecoder decodeObjectForKey:@"hopList"];
  }
  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
  NSLog(@"Message encodeWithCoder");
  
  [aCoder encodeObject:self.messageId forKey:@"messageId"];
  [aCoder encodeObject:self.textContent forKey:@"textContent"];
  [aCoder encodeObject:self.protocolType forKey:@"protocolType"];
  [aCoder encodeObject:self.destPeerName forKey:@"destPeerName"];
  [aCoder encodeObject:self.hopList forKey:@"hopList"];
}

@end//Message
