//
//  locationGetter.h
//  Capstone_Modified
//
//  Created by ZihaoLin on 2/26/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface addressManager : NSObject
+ (NSString *)retrieveAddress :(CLLocation *)location;
@end
