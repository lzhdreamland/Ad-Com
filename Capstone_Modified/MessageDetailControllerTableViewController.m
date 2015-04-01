//
//  MessageDetailControllerTableViewController.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 2/16/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "MessageDetailControllerTableViewController.h"
#import "AppDelegate.h"
#import "DBManager.h"

@interface MessageDetailControllerTableViewController ()

@end

@implementation MessageDetailControllerTableViewController{
  DBManager *dbManager;
  AppDelegate *appDelegate;
  NSArray *sendInfo;
  NSArray *messageInfo;
  NSArray *hopList;
  NSString *hopListText;
}

- (void)viewDidLoad {
  NSLog(@"viewDidLoad(messageDetail)");
    [super viewDidLoad];
  
  //custom title
  UILabel *lblTitle = [[UILabel alloc] init];
  lblTitle.text = @"Messages";
  lblTitle.backgroundColor = [UIColor clearColor];
  lblTitle.textColor = [UIColor whiteColor];
  lblTitle.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
  [lblTitle sizeToFit];
  self.navigationItem.titleView = lblTitle;

  
  if (!dbManager) {
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
  }
  
  if (!appDelegate) {
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  }
  
  //
  if (self.receivedOrSent)
  {
    NSString *queryMessageInfo = [NSString stringWithFormat:@"select protocol,sendtime,sendname,textcontent,hoplist,longitude,latitude,address from receivedMessage where messageid = '%@'",self.messageId];
    messageInfo = [[dbManager loadDataFromDB:queryMessageInfo] copy];
    hopListText = (NSString *)[messageInfo[0][4] copy];
    NSLog(@"print messageInfo : %@",messageInfo[0][0]);
  }
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillDisappear:(BOOL)animated{
  NSLog(@"viewWillDisappear");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
  /*
   if(display received messages)
   {
      create two sections:
      1.display information except list of jumped hops
      2.display list of jumped hops
   }else{
      display send message;
   }
   */
  if (self.receivedOrSent) {
    return 2;
  }else{
    return 1;
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
  if (section == 0)
  {
    return 8;
  }else{
    return 1;
  }
}

//Height for specific cell
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
//  if (indexPath.row == 4) {
//    return 100.0;
//  }else return 44.0;
  return 100.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
  if (section == 0) {
    return @"Basic Info";
  }else{
    return @"Hop List";
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageDetail" forIndexPath:indexPath];
  
  if (!dbManager) {
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
  }
  /*
   if(receivedOrSent)
   {
      load received messages;
   }else{
      load sent messages;
   }
   */
  if (self.receivedOrSent) {
    //section 0 , displaying received message information except list of jumped hops
    if ([indexPath section] == 0)
    {
      if (indexPath.row == 0) {
        cell.textLabel.text =[@"Message ID: " stringByAppendingString:self.messageId];
      }else if (indexPath.row == 1)
      {
        cell.textLabel.text = [@"Prototype: " stringByAppendingString:messageInfo[0][0]];
      }else if (indexPath.row == 2)
      {
        cell.textLabel.text = [@"Transmit Time: " stringByAppendingString:messageInfo[0][1]];
      }else if(indexPath.row == 3){
        cell.textLabel.text = [@"Sender Name: " stringByAppendingString:messageInfo[0][2]];
      }else if(indexPath.row == 4){
        cell.textLabel.text = [@"Text Content: " stringByAppendingString:messageInfo[0][3]];
      }else if (indexPath.row == 5){
        cell.textLabel.text = [@"Longitude: " stringByAppendingString:messageInfo[0][5]];
      }else if (indexPath.row == 6){
        cell.textLabel.text = [@"Latitude: " stringByAppendingString:messageInfo[0][6]];
      }else{
        cell.textLabel.text = [@"Address: " stringByAppendingString:messageInfo[0][7]];
      }
    }else{
      cell.textLabel.text = [@"Hop List: " stringByAppendingString:hopListText];
    }
  }else{
    NSString *querySentMessageInfo = [NSString stringWithFormat:@"select sendtime,protocoltype,destpeer,textcontent,longitude,latitude,address from sendMessage where messageid = '%@'",self.messageId];
    NSArray *sentMessageInfo = [[dbManager loadDataFromDB:querySentMessageInfo] copy];
    if (indexPath.row == 0) {
      cell.textLabel.text =[@"Message ID: " stringByAppendingString:self.messageId];
    }else if(indexPath.row == 1){
      cell.textLabel.text =[@"Transmit Time: " stringByAppendingString:sentMessageInfo[0][0]];
    }else if (indexPath.row == 2){
      cell.textLabel.text = [@"Protocol Type: " stringByAppendingString:sentMessageInfo[0][1]];
    }else if (indexPath.row == 3){
      cell.textLabel.text = [@"Dest Peer: " stringByAppendingString:sentMessageInfo[0][2]];
    }else if (indexPath.row == 4){
      cell.textLabel.text = [@"Text Content: " stringByAppendingString:sentMessageInfo[0][3]];
    }else if (indexPath.row == 5){
      cell.textLabel.text = [@"Longitude : " stringByAppendingString:sentMessageInfo[0][4]];
    }else if (indexPath.row == 6){
      cell.textLabel.text = [@"Latitude : " stringByAppendingString:sentMessageInfo[0][5]];
    }else{
      cell.textLabel.text = [@"Addres : " stringByAppendingString:sentMessageInfo[0][6]];
    }
  }
    return cell;
}

@end
