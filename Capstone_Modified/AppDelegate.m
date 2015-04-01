//
//  AppDelegate.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/4/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "AppDelegate.h"
#import "DBManager.h"

@interface AppDelegate ()
@property (strong,nonatomic) DBManager *dbManager;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  
  //Check database exists 'contactInfo' && 'profiles'
  if (!self.dbManager)
  {
    self.dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
  }
  
//  self.defaults = nil;

  //Store the bool "NO" by utilizing NSUserDefaults  
//  if (!self.defaults) {
  self.defaults = [NSUserDefaults standardUserDefaults];
  NSNumber *advertiseSwitch = [NSNumber numberWithBool:YES];
  [self.defaults setObject:advertiseSwitch forKey:@"advertiseSwitch"];
  [self.defaults setObject:[NSNumber numberWithBool:YES] forKey:@"receiveOrSend"];
  if ([self.defaults objectForKey:@"first Run"])
  {
    NSLog(@"not first time running");
  }else{
    [self.defaults setObject:@"firstRun" forKey:@"first Run"];
    [self runForFirstTime];
  }
  
  //init device name as displayName;
  [self.defaults setObject:[[UIDevice currentDevice] name] forKey:@"displayName"];
    
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - check first running of app
- (void)runForFirstTime{
    //app running for the first time ,create tables
  [self resetTableProfiles];//table 'profiles'
  [self resetTableContactInfo];//table 'contact Info'
  [self resetTableReceivedMessage];//table 'received message'
  [self resetTableSendMessage];//table 'received message';
  [self resetTableUserInfo];//table 'userInfo'
}

#pragma mark - reset database methods
//reset table receivedmessage
- (void)resetTableReceivedMessage{
  NSLog(@"reset table 'receivedMessage'");
  [self.dbManager executeQuery:@"drop table receivedMessage"];
  NSString *createTableReceivedMessages = @"CREATE TABLE receivedMessage(messageid text,receiver_name text,protocol text,sendtime text,sendname text,textcontent text,hoplist text,longitude text,latitude text,address text)";
  [self.dbManager executeQuery:createTableReceivedMessages];
  NSLog(@"%@",createTableReceivedMessages);
}

//reset table sendMessage
- (void)resetTableSendMessage{
  NSLog(@"reset table 'sendMessage'");
  [self.dbManager executeQuery:@"drop table sendMessage"];
  NSString *createSentMessageTable = @"CREATE TABLE sendMessage(messageid text primary key,send_name text,sendtime text,protocoltype text,destpeer text,textcontent text, longitude text,latitude text, address text)";
  [self.dbManager executeQuery:createSentMessageTable];
  NSLog(@"%@",createSentMessageTable);
}

- (void)resetTableUserInfo{
  NSLog(@"reset table 'userInfo'");
  [self.dbManager executeQuery:@"drop table userInfo"];
  NSString *createUserInfoTable = @"CREATE TABLE userInfo(user_name text primary key,user_password text)";
  [self.dbManager executeQuery:createUserInfoTable];
  NSLog(@"%@",createUserInfoTable);
}
////reset table messageTrack
//- (void)resetTableMessageTrack{
//  NSString *dropTableMessageTrack = @"drop table messageTrack";
//  [self.dbManager executeQuery:dropTableMessageTrack];
//  NSString *createTableMessageTrack = @"CREATE TABLE messageTrack(messageid text,sendtime text,sendname text)";
//  [self.dbManager executeQuery:createTableMessageTrack];
//  NSLog(@"%@",createsTableMessageTrack);
//}

//reset table profiles
- (void)resetTableProfiles{
  NSLog(@"reset table 'profiles'");
  [self.dbManager executeQuery:@"drop table profiles"];
  [self.dbManager executeQuery:@"CREATE TABLE profiles(receiver_name text,profilename text,connectedname text,connectedtime text)"];
}

- (void)resetTableContactInfo{
  NSLog(@"reset table 'contactInfo'");
  [self.dbManager executeQuery:@"drop table contactInfo"];
  [self.dbManager executeQuery:@"CREATE TABLE contactInfo(contact_name text,displayname text,connectedtime text);"];
  NSLog(@"CREATE TABLE contactInfo(contact_name text,displayname text,connectedtime text);");
}

@end
