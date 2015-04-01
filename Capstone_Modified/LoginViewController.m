//
//  LoginViewController.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 3/9/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "LoginViewController.h"
#import "ServiceConnector.h"
#import "networkCheckManager.h"
#import "DBManager.h"

@interface LoginViewController ()<ServiceConnectorDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation LoginViewController{
  BOOL valid;
  AppDelegate *appDelegate;
  DBManager *dbManager;
  NSTimer *updateDbTimer;
}

#pragma mark - Private Methods
- (IBAction)loginFun:(id)sender {
  /*
   if(hasConnectivity)
   {
      login from cloud;
   }else{
      login from local DB;
   }
   */
  if (self.usernameField.text.length>0 && self.passwordField.text.length>0)
  {
    NSString *userName = self.usernameField.text;
    NSString *password = self.passwordField.text;
    if ([networkCheckManager hasConnectivity])
    {
      //login via web service
      ServiceConnector *serviceConn = [[ServiceConnector alloc] init];
      serviceConn.delegate = self;
      
      //utilize input username && password to login
      [serviceConn loginFunUseUserName:userName andPassword:password];
    }else
    {
      //login via local db
      NSString *query = [NSString stringWithFormat:@"select user_name,user_password from userInfo where user_name = '%@'",userName];
      NSArray *userInfo = [dbManager loadDataFromDB:query];
      if (userInfo.count > 0)
      {
        if ([userInfo[0][1] isEqualToString:password] && [userInfo[0][0] isEqualToString:userName])
        {
          valid = YES;
          [appDelegate.defaults setObject:userName forKey:@"displayName"];
          [self performSegueWithIdentifier:@"mainView" sender:self];
        }else{
          NSLog(@"fail to login");
          valid = NO;
        }
      }
    }
  }else{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"User name connot be empty" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
    [alert show];
  }
}

- (void)synchronizingDatabase{
  NSLog(@"synchronizingDatabase");
  BOOL hasConnectivity = [networkCheckManager hasConnectivity];
  if (hasConnectivity)
  {
    //update all user_name && user_password in local db from cloud db
    ServiceConnector *serviceConn = [[ServiceConnector alloc] init];
    serviceConn.delegate = self;

    NSArray *user_names = [dbManager loadDataFromDB:@"select user_name from userInfo"];
   
    if (user_names.count > 0)
    {
      for (int i = 0; i < user_names.count; i++)
      {
        NSLog(@"selected user_name from loacl Db : %@",user_names[i][0]);
        NSString *user_name = [user_names[i][0] copy];
        [serviceConn requestUserInfoWithUserName:user_name];
      }
    }else{
      NSLog(@"table userInfo is empty");
    }
  }else{
    NSLog(@"Please check network connectivity");
  }
}

//method for getting user_name && user_password for local database
#pragma mark - ServiceConnectorDelegate Methods
-(void)requestReturnedDataToLogin:(NSData *)data{ //activated when data is returned
  NSError *error;
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
  NSLog(@"JSON Dic : %@",dictionary);
  /*
   if(login success)
   {
      look up current user_name in local database;
      synchronizing user_name && user_password from cloud into local DB
   }
   */
  if ([[dictionary objectForKey:@"function"] isEqualToString:@"login"] && [[dictionary objectForKey:@"validate"] isEqualToString:@"true"])
  {
    valid = YES;
    //update user displayName
    [appDelegate.defaults setObject:self.usernameField.text forKey:@"displayName"];
    [appDelegate.defaults synchronize];
    NSLog(@"login with user name : %@",[appDelegate.defaults objectForKey:@"displayName"]);
    
    //store current user_name && user_password into local database
    NSString *user_name = [dictionary objectForKey:@"user_name"];
    NSString *user_password = [dictionary objectForKey:@"user_password"];
    //update returned user_name && password to local database
    if (user_name.length != 0)
    {
      /*
       if(user_name existed)
       {
       update local database with derived user_name && user_password;
       }else{
       insert derived user_name && user_password into local db;
       }
       */
      BOOL existed = [self searchUserInfoExistedWithUserName:user_name];
      if (existed)
      {
        NSString *updateDb = [NSString stringWithFormat:@"update userInfo SET user_password = '%@' WHERE user_name= '%@' ",user_name,user_password];
        [dbManager executeQuery:updateDb];
        NSLog(@"%@",updateDb);
      }else
      {
        NSString *insertDb = [NSString stringWithFormat:@"insert into userInfo(user_name,user_password) values('%@','%@')",user_name,user_password];
        [dbManager executeQuery:insertDb];
        NSLog(@"%@",insertDb);
      }
    }else
    {
      NSLog(@"failed to synchronize local db");
    }
    [self performSegueWithIdentifier:@"mainView" sender:self];
    
  }else{
    valid = NO;
    UIAlertView *loginFailed = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Please check information!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [loginFailed show];
    NSLog(@"information invalide");
  }
}

- (void)requestReturnedDataToUpdateLocalDb:(NSData *)data{
  NSError *error;
  
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
  NSLog(@"requestReturnedDataToUpdateLocalDb : %@",dictionary);
  
  if ([[dictionary objectForKey:@"function"] isEqualToString:@"requestUserInfo"] &&
      [[dictionary objectForKey:@"validate"] isEqualToString:@"true"])
  {
    NSString *user_name = [dictionary objectForKey:@"user_name"];
    NSString *user_password = [dictionary objectForKey:@"user_password"];
  
    NSString *updateDb = [NSString stringWithFormat:@"update userInfo SET user_password = '%@' WHERE user_name = '%@'",user_password,user_name];
    [dbManager executeQuery:updateDb];
    NSLog(@"%@",updateDb);
  }else{
    NSLog(@"User doesn't exist in cloud database");
  }
}

- (BOOL)searchUserInfoExistedWithUserName:(NSString *)user_name{
  NSString *queryUser = [NSString stringWithFormat:@"select user_name from userInfo where user_name = '%@'",user_name];
  NSArray *names = [dbManager loadDataFromDB:queryUser];
  NSLog(@"search existed user_name : %@",names);
  if (names.count == 0)
  {
    return NO;
  }else{
    return YES;
  }
}

#pragma mark - prepareForSegue Methods
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
  if ([identifier isEqualToString:@"mainView"]) {
    return valid;
  }else{
    return YES;
  }
}

#pragma mark - view loading Methods
- (void)viewDidLoad {
  [super viewDidLoad];
  
  if (!appDelegate) {
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  }
  
  if (!dbManager) {
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
  }
  
  self.usernameField.delegate = self;
  self.passwordField.delegate = self;
  //set up a timer to keep updating userInfo table
  updateDbTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(synchronizingDatabase) userInfo:nil repeats:NO];
  [[NSRunLoop currentRunLoop] addTimer:updateDbTimer forMode:NSDefaultRunLoopMode];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
  valid = NO;
  //set up a timer to keep updating userInfo table
  updateDbTimer = [NSTimer timerWithTimeInterval:3 target:self selector:@selector(synchronizingDatabase) userInfo:nil repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:updateDbTimer forMode:NSDefaultRunLoopMode];
}

- (void)viewWillDisappear:(BOOL)animated{
  NSLog(@"login viewWillDisappear");
  //clean timer for updating userInfo table from web service
  if ([updateDbTimer isValid])
  {
    [updateDbTimer invalidate];
    updateDbTimer = nil;
  }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - uitextfield delegate method
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
  [textField resignFirstResponder];
  
  return YES;
}
@end
