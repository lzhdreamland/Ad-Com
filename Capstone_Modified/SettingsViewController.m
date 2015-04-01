//
//  MeViewController.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/16/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "LoginViewController.h"

@interface SettingsViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UISwitch *advertiseSwitch;
@end

@implementation SettingsViewController{
  AppDelegate *appDelegate;
  NSNumber *advertiseStatus;
  SessionManager *sessionMngr;
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  if ([indexPath section] == 2)
  {
    //Log out current user
    if (!appDelegate)
    {
      appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    //firstly reset display name as device name
    [appDelegate.defaults setObject:[[UIDevice currentDevice] name] forKey:@"displayName"];
    [appDelegate.defaults synchronize];
    
    LoginViewController *logVc = [self.storyboard instantiateViewControllerWithIdentifier:@"loginView"];
    [self presentViewController:logVc animated:YES completion:nil];
    [self.delegate logoutCurrentUser:self];
  }
}

- (IBAction)setAdvertise:(UISwitch *)sender {
  if (appDelegate) {
    //Updating status of 'advertiseSwitch' through 'appDelegate.defaults'
    //Enable other classes can take advantage of real-time bool value
    [appDelegate.defaults setObject:[NSNumber numberWithBool:[sender isOn]] forKey:@"advertiseSwitch"];
    [appDelegate.defaults synchronize];
    NSLog(@"Advertise Switch is : %@",[appDelegate.defaults objectForKey:@"advertiseSwitch"]);
  }else return;
  
  self.advertiseStatus = [NSNumber numberWithBool:[sender isOn]];
}

#pragma mark - 'Views' Methods
- (void)viewWillAppear:(BOOL)animated{
  //Keep status synchronized
  NSLog(@"viewWillAppear (SettingsViewController)");
  if (appDelegate) {
    advertiseStatus = [appDelegate.defaults objectForKey:@"advertiseSwitch"];
    [self.advertiseSwitch setOn:[advertiseStatus boolValue]];
  }else return;
}

- (void)viewWillDisappear:(BOOL)animated{
  //Update 'sessionMngr' of 'appDelegate'
  NSLog(@"viewWillDisappear (SettingsViewController)");
//  [self.delegate logoutCurrentUser:self];
}

- (void)viewDidLoad {
  NSLog(@"viewDidLoad (SettingsViewController)");
  [super viewDidLoad];
  //Get status of advertiseSwitch from "appDelegate" with key "advertiseSwitch"
  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  advertiseStatus = [appDelegate.defaults objectForKey:@"advertiseSwitch"];
  //Set 'advertiseSwitch' with bool value from 'appDelegate'
  [self.advertiseSwitch setOn:[advertiseStatus boolValue]];
  
  //let delegate knows about view controller of connectivityViewController
  NSArray *vcs = ((UITabBarController *)self.navigationController.parentViewController).viewControllers;
  NSUInteger otherindex = 0;
  UINavigationController *vcOfConnectivity = vcs[otherindex];
  NSArray *navcs = vcOfConnectivity.viewControllers;
  self.delegate = navcs[0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
