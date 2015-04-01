//
//  locationGetter.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 2/26/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "addressManager.h"


@implementation addressManager

+ (NSString *)retrieveAddress :(CLLocation *)location{
  NSLog(@"Resolving the Address");
  CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
  NSMutableString *address = [NSMutableString stringWithCapacity:10];
  [address setString:@"not found"];
  [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
  {
//    NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
    if (error == nil && [placemarks count] > 0)
    {
      CLPlacemark *placeMark = [placemarks lastObject];
      NSString *getAddress = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@",
                                placeMark.subThoroughfare, placeMark.thoroughfare,
                                placeMark.postalCode, placeMark.locality,
                                placeMark.administrativeArea,
                                placeMark.country];
      
      //get address
      [address setString:getAddress];
    } else
    {
      [address setString:@"not found"];
      NSLog(@"%@", error.debugDescription);
    }
  } ];
  
  return address;
}

@end
