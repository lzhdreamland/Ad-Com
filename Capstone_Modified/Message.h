//
//  Message.h
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/24/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject<NSCoding>
@property (strong,nonatomic) NSString *messageId;
@property (strong,nonatomic) NSString *textContent;
@property (strong,nonatomic) NSString *protocolType;
@property (strong,nonatomic) NSString *destPeerName;
@property (strong,nonatomic) NSMutableDictionary *hopList;
@end
