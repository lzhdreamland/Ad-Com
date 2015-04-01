//
//  SecondViewController.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/4/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "ConnectivityViewController.h"
#import "SettingsViewController.h"
#import "CreateMessageViewController.h"
#import "LoginViewController.h"
#import "DBManager.h"
#import "ProfileBuilder.h"
#import "AppDelegate.h"
#import "Profile.h"
#import "Message.h"

@interface ConnectivityViewController ()<SessionClientProtocol,CreateMessageDidFinishProtocol,SettingsLogoutProtocol,UITableViewDataSource,UITableViewDelegate,UITabBarControllerDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@end

@implementation ConnectivityViewController{
  AppDelegate *appDelegate;
  DBManager *dbManager;
  NSNumber *acceptInvitation;
  NSString *displayName;
}

#pragma mark - 'SessionClientProtocol' methods
- (void)processData:(NSData *)data fromPeer:(MCPeerID *)peer{
  NSLog(@"processData");
  NSError *error = nil;
  //Get self.displayName
  if (!appDelegate) {
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  }
  
  //process json data
  if ([NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error])
  {
    NSDictionary *fetchedJson = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    NSLog(@"print out received message : %@",fetchedJson);
    //Process message object
    if ([[fetchedJson allKeys] containsObject:@"message"])
    {
      //parsing nsarray from fetchedJson dictionary
      NSArray *messageArry = (NSArray *)[fetchedJson objectForKey:@"message"];
      /*
       sequence of array contains message Info:
       [0] --> messageId
       [1] --> protocolType
       [2] --> destPeerName
       [3] --> messageContent
       [4] --> timeAndSender(* NSArray)
          [4][0] --> sendtime
          [4][1] --> sendname
       [5] --> jumpedHops(* NSArray)
       [6] --> longitude
       [7] --> latitude
       [8] --> address
      */
      NSArray *timeAndSender = [[messageArry objectAtIndex:4] copy];
      NSMutableArray *jumpedHops = [[NSMutableArray alloc] initWithArray:[[messageArry objectAtIndex:5] copy]];
      
      NSString *messageId = (NSString *)messageArry[0];
      NSString *protocolType = (NSString *)messageArry[1];
      NSString *destPeerName = (NSString *)messageArry[2];
      NSString *messageContent = (NSString *)messageArry[3];
      NSString *sendTime = (NSString *)timeAndSender[0][0];
      NSString *sendName = (NSString *)timeAndSender[0][1];
      NSString *longitude = (NSString *)messageArry[6];
      NSString *latitude = (NSString *)messageArry[7];
      NSString *address = (NSString *)messageArry[8];
      
      if (!appDelegate) {
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
      }
      NSString *receiver_name = [appDelegate.defaults objectForKey:@"displayName"];
      /*
       if(protocolType isEqualTo:@"route")
       {
          1.get destination peer;
          2.check whether destination peer is self
       if(destination peer != self)
       {
          check whether destination peer belongs to self.connectedPeers ?
          send message direct to destionation peer : broadcast message to connected peers except peers included in jumped hops
       }else{
          save received message
       }
      */
      if ([protocolType isEqualToString:@"route"] && ![destPeerName isEqualToString:@" "])
      {
        NSLog(@"received message direct to peer : %@",destPeerName);
        //check whether destination peer is self or not
        if(!appDelegate) appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *selfName = [appDelegate.defaults objectForKey:@"displayName"];
        if ([destPeerName isEqualToString:selfName])
        {
          NSLog(@"protocol type 'route' direct to self");
          //convert NSArray for list of jumped hops to NSString
          NSString *hopsStr;
          if (jumpedHops != nil) {
            NSError *error = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:jumpedHops options:kNilOptions error:&error];
            hopsStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          }
          
          //store received message into database
          NSString *insertReceivedMessage = [NSString stringWithFormat:@"insert into receivedMessage(messageid,receiver_name,protocol,sendtime,sendname,textcontent,hoplist,longitude,latitude,address) values('%@','%@','%@','%@','%@','%@','%@','%@','%@','%@')",messageId,receiver_name,protocolType,sendTime,sendName,messageContent,hopsStr,longitude,latitude,address];

          if (!dbManager)
          {
            dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
            [dbManager executeQuery:insertReceivedMessage];
            NSLog(@"%@",insertReceivedMessage);
          }else{
            [dbManager executeQuery:insertReceivedMessage];
            NSLog(@"%@",insertReceivedMessage);
          }
        }else
        {
          NSLog(@"protocol type 'route' not direct to self");
          //destinations peer is not selfs
          //check whether destination peer belongs to self.connectedPeers ?
          //send message direct to destionation peer : broadcast message
          
            //destination peer existed in list of connected peers, send data direct to dest peer
            //add self into list of jumped hops
            [jumpedHops addObject:selfName];
            
            NSMutableArray *newJsonArry = [[NSMutableArray alloc] init];
            NSMutableDictionary *newJsonDic = [[NSMutableDictionary alloc] init];
            
            [newJsonArry addObject:messageId];//[0] --> messageId
            [newJsonArry addObject:protocolType];//[1] --> protocolType
            [newJsonArry addObject:destPeerName];//[2] --> destPeerName
            [newJsonArry addObject:messageContent];//[3] --> messageContent
            [newJsonArry addObject:[timeAndSender copy]];//[4] --> timeAndSender(* NSArray)
            [newJsonArry addObject:[jumpedHops copy]];//[5] --> newJumpedHopsList (*NSArray)
            [newJsonArry addObject:longitude];//
            [newJsonArry addObject:latitude];//
            [newJsonArry addObject:address];//
          
            [newJsonDic setObject:newJsonArry forKey:@"message"];
            
            NSData *newJsonData = [NSJSONSerialization dataWithJSONObject:newJsonDic options:kNilOptions error:&error];
            
            [self.sessionMngr forwardMessage:newJsonData toDestPeer:destPeerName];
        }//end of route not 'self'
      }else
      {
        NSLog(@"received message's protocol type is 'epidemic'");
        //protocol type is @"epidemic", store message into database
        //convert NSArray for list of jumped hops to NSString
        NSString *hopsStr;
        if (jumpedHops != nil) {
          NSError *error = nil;
          NSData *data = [NSJSONSerialization dataWithJSONObject:jumpedHops options:kNilOptions error:&error];
          hopsStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        //store received message into database
        NSString *insertReceivedMessage = [NSString stringWithFormat:@"insert into receivedMessage(messageid,receiver_name,protocol,sendtime,sendname,textcontent,hoplist,longitude,latitude,address) values('%@','%@','%@','%@','%@','%@','%@','%@','%@','%@')",messageId,receiver_name,protocolType,sendTime,sendName,messageContent,hopsStr,longitude,latitude,address];

        if (!dbManager) {
          dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
          [dbManager executeQuery:insertReceivedMessage];
          NSLog(@"%@",insertReceivedMessage);
        }else{
          [dbManager executeQuery:insertReceivedMessage];
          NSLog(@"%@",insertReceivedMessage);
        }
      }
      /*
       profileList.sql ;
       TABLE receivedMessage(messageid text primary key,protocol text,textcontent text);
       TABLE messageTrack(messageid text primary key,sendtime text,sendname text);
       */
      //insert incoming message into database
    }
    
    //Process profile object
    if ([[fetchedJson allKeys] containsObject:@"profile"])
    {
      //parsing nsarray from fetchedJson dictionary
      NSArray *profileArry = (NSArray *)[[fetchedJson objectForKey:@"profile"] mutableCopy];
      /*
       sequence of array contains profile Info:
       [0] --> profileName;
       [1] --> contactList;
       */
      //utilize public method to transform jsonArry into Profile object
      Profile *receivedProfile = [ProfileBuilder profileFromJsonArray:profileArry];
      if (!([[receivedProfile.contactList objectAtIndex:0] isEqual: @" "]))
      {
        NSLog(@"received contact list is %@",receivedProfile.contactList[0]);
        NSString *peerName = receivedProfile.contactList[0][0];
        NSString *connectedTime = receivedProfile.contactList[0][1];
        NSString *receiver_name = [appDelegate.defaults objectForKey:@"displayName"];
        NSLog(@"%@ && %@",peerName,connectedTime);
        //detele rows from profiles where profilename = 'receivedProfile.profileName'
        //refresh table where profilename = 'receivedProfile.profileName' && receiver_name = 'receiver_name'
        NSString *deleteQuery = [NSString stringWithFormat:@"delete from profiles where profilename = '%@' AND receiver_name = '%@'",receivedProfile.profileName,receiver_name];
        if (!dbManager)
        {
          dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
          [dbManager executeQuery:deleteQuery];
          NSLog(@"%@",deleteQuery);
        }else
        {
          [dbManager executeQuery:deleteQuery];
          NSLog(@"%@",deleteQuery);
        }//delete previous data end
        
        //iterate all elements and insert these connected information into table 'profiles'
        for (NSArray *eachRow in receivedProfile.contactList)
        {
          //table 'profiles' columns 'profilename, connectedname,connectedtime'
          NSString *insertQuery = [NSString stringWithFormat:@"insert into profiles(receiver_name,profilename,connectedname,connectedtime) values('%@','%@','%@','%@')",receiver_name,receivedProfile.profileName,(NSString *)eachRow[0],(NSString *)eachRow[1]];
          if (!dbManager)
          {
            dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
            [dbManager executeQuery:insertQuery];
            NSLog(@"execute %@",insertQuery);
          }else
          {
            [dbManager executeQuery:insertQuery];
            NSLog(@"execute %@",insertQuery);
          }
        }
      }else{
        NSLog(@"received contact list is nil");
      }
    }
  }
//  NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
  
//  //Exchange 'Profile' with connected peers
//  //1. Receive 'profile' from others with key 'receivedProfile'
//  [unarchiver finishDecoding];
  NSLog(@"processData End");
}

- (void) exchangeProfileWithName:(NSString *)profileName andContactList:(NSArray *)contactList withDestPeerName:(NSString *)destPeerName{
  NSLog(@"exchangeProfile with peer :%@",destPeerName);
  NSMutableArray *jsonArry = [[NSMutableArray alloc] init];
  NSMutableDictionary *jsonDic = [[NSMutableDictionary alloc] init];
  
  [jsonArry addObject:profileName];//[0] --> profileName
  [jsonArry addObject:[contactList copy]];//[1] --> contactList
  
  [jsonDic setObject:jsonArry forKey:@"profile"];
  
  NSError *error = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:kNilOptions error:&error];
  if (!self.sessionMngr.hasPeers) return;

  NSLog(@"exchange profile via JSON :%@",[NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error]);
  [self.sessionMngr exchangeData:jsonData withDestPeerName:destPeerName];
  
  NSLog(@"finish exchangeProfile");
}

#pragma mark - UITabBarController Methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
  return NO;
}


#pragma makr - UITableView Delegate Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.sessionMngr.session.connectedPeers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"connectivityCell"];
  MCPeerID *peerID = self.sessionMngr.session.connectedPeers[indexPath.row];
  
  cell.textLabel.text = peerID.displayName;
  
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
  return @"Connected Peers";
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section{
  //Set the text color for header text
  UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
  [header.textLabel setTextColor:[UIColor whiteColor]];
  header.textLabel.font = [UIFont fontWithName:@"ChalkboardSE-Bold" size:20.0];
  
  // Set the background color of our header/footer.
  header.contentView.backgroundColor = [UIColor lightGrayColor];
}

#pragma mark - LifeCycle
- (void)reloadTableView{
  [self.tableView reloadData];
}

#pragma mark - 'ViewDidLoad' Methods
- (void)viewDidLoad {
  [super viewDidLoad];
  NSLog(@"viewDidLoad(Connectivity)");
  [self.tabBarController.tabBar setTintColor:[UIColor redColor]];
  
  //custom title
  UILabel *lblTitle = [[UILabel alloc] init];
  lblTitle.text = @"Connectivity";
  lblTitle.backgroundColor = [UIColor clearColor];
  lblTitle.textColor = [UIColor whiteColor];
  lblTitle.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
  [lblTitle sizeToFit];
  self.navigationItem.titleView = lblTitle;

  //Init 'sessionMngr' with 'acceptInviation' and 'displayName'
  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  acceptInvitation = [appDelegate.defaults objectForKey:@"advertiseSwitch"] ;
  //Init 'displayName' with current device name temporaryly
  displayName = [appDelegate.defaults objectForKey:@"displayName"];
  self.nameLabel.text = displayName;

  //set delegate && datasource for tableview
  [self.tableView setDataSource:self];
  [self.tableView setDelegate:self];
  
  //init 'sessionMngr' for apps
  if (!self.sessionMngr)
  {
    self.sessionMngr = [[SessionManager alloc] initWithDisplayName:[appDelegate.defaults objectForKey:@"displayName"] andInvitation:[NSNumber numberWithBool:YES]];
    //Let 'self.delegate' be the delegate of 'self'
    //'client' of sessionMngr has to listen to the 'MessageDisplayViewController delegate';
    self.delegate = self;
    self.sessionMngr.client = self.delegate;
  }

  //Set up a NSTimer to reload 'tableView'
  NSTimer *timer = [NSTimer timerWithTimeInterval:0.2 target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
  // Do any additional setup after loading the view, typically from a nib.
}

//- (void)viewWillDisappear:(BOOL)animated{
//  NSLog(@"View Will Disappear");
//  NSLog(@"connected peers %lu" ,(unsigned long) self.sessionMngr.session.connectedPeers.count);
//  [self.delegate connectivityControllerDidFinish:self];
//}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - invite other peers
- (IBAction)inviteOtherPeers:(UIBarButtonItem *)sender {
  if (self.sessionMngr) {
    [self.sessionMngr connect];
    NSLog(@"Start inviting other Peers");
  }else{
    NSLog(@"sessionMngr doesn't exist");
  }
}

#pragma mark - 'SettingsLogoutProtocol' method
- (void)logoutCurrentUser:(SettingsViewController *)sender{
  NSLog(@"current user log out!!!");
  if (self.sessionMngr)
  {
    self.sessionMngr = nil;
    NSLog(@"session created with : %@ is removed already",[appDelegate.defaults objectForKey:@"displayName"]);
  }
}

#pragma mark - 'CreateMessageDidFinishProtocol' method
- (void) createMessageDidFinish:(CreateMessageViewController *) sender{
  NSLog(@"createMessageDidFinishProtocol");
  if (sender.sessionMngr) self.sessionMngr = sender.sessionMngr;
}

#pragma mark - prepareForSegue with identifier 'createMessage'
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
  if (![segue.identifier isEqualToString:@"createMessage"]) return;
  CreateMessageViewController *cmVc = segue.destinationViewController;
  cmVc.delegate = self;
  if (self.sessionMngr) cmVc.sessionMngr = self.sessionMngr;
}

@end
