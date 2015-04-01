//
//  registerViewController.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 3/9/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "registerViewController.h"
#import "networkCheckManager.h"
#import "DBManager.h"

@interface registerViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation registerViewController{
  NSArray *userInfoArry;
  DBManager *dbManager;
}

#pragma mark - private Methods
- (IBAction)registerNewUser:(id)sender {
  /*
   if(hasConnectivity)
   {
      register new user;
   }else{
      connot register;
   }
   */
  if ([networkCheckManager hasConnectivity])
  {
    ServiceConnector *serviceConn = [[ServiceConnector alloc] init];
    serviceConn.delegate = self;
    
    //utilize input username && password to login
    if (self.userNameField.text.length>0 && self.passwordField.text.length>0 &&self.confirmPasswordField.text > 0) {
      NSString *userName = self.userNameField.text;
      NSString *password = self.passwordField.text;
      NSString *confirmPass = self.confirmPasswordField.text;
      
      if ([password isEqualToString:confirmPass])
      {
        [serviceConn registerFunUserName:userName andPassword:password];
        //store user_name && user_password into an array for future implementation
        userInfoArry = [[NSArray alloc] initWithObjects:userName,password, nil];
      }else{
        NSLog(@"confirm password please!!!");
        self.passwordField.text = @"";
        self.confirmPasswordField.text = @"";
      }
    }else{
      NSLog(@"Input cannot be nil");
    }
  }else{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"network issue" message:@"Please check your network connectivity" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
    [alertView show];
    //clean all input fields
    self.passwordField.text = @"";
    self.confirmPasswordField.text = @"";
    self.userNameField.text = @"";
  }
}

- (IBAction)cancelRegister:(id)sender {
  [self dismissViewControllerAnimated: YES completion: nil];
}

#pragma mark - ServiceConnectorDelegate -
-(void)requestReturnedDataToRegister:(NSData *)data{ //activated when data is returned
  NSError *error;
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
  NSLog(@"JSON Dic : %@",dictionary);
  
  /*
   if(register success)
   {
      synchronize new user_name && user_password(stored in arry 'userInfoArry') into local db;
   }else{
      clean array 'userInfoArry';
   }
   */
  if ([[dictionary objectForKey:@"validate"] isEqualToString:@"true"])
  {
    UIAlertView *registerSuccess = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Message was forwarded successfully!" delegate:self cancelButtonTitle:@"Confirm" otherButtonTitles: nil];
    [registerSuccess show];
    //synchronizing information of new user with local DB
    NSString *insertUserInfo = [NSString stringWithFormat:@"insert into userInfo(user_name,user_password) values('%@','%@')",(NSString *)userInfoArry[0],(NSString *)userInfoArry[1]];
    [dbManager executeQuery:insertUserInfo];
    NSLog(@"%@",insertUserInfo);
    //nil arry 'userInfoArry'
    userInfoArry = nil;
  }else{
    NSLog(@"register failed");
    userInfoArry = nil;
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  //init dbManager for purpose of synchronizing cloud db and local db
  if (!dbManager)
  {
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
  }
  
  //custom title
  UILabel *lblTitle = [[UILabel alloc] init];
  lblTitle.text = @"Register";
  lblTitle.backgroundColor = [UIColor clearColor];
  lblTitle.textColor = [UIColor whiteColor];
  lblTitle.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
  [lblTitle sizeToFit];
  self.navigationItem.titleView = lblTitle;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
