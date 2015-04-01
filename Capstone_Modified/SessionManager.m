//
//  SessionManager.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/4/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "SessionManager.h"
#import "AppDelegate.h"
#import "DBManager.h"

NSString *const serviceTypeName = @"serviceName";
@interface SessionManager()
@property (strong,nonatomic) NSMutableDictionary *contactDic;
@property (strong,nonatomic) NSArray *previousContact;
@property (strong,nonatomic) NSString *displayName;
@property (strong,nonatomic) MCPeerID *peerID;
@property (assign,nonatomic) BOOL acceptInvitation;
@property (assign,nonatomic) BOOL inviteOtherPeers;

@end
@implementation SessionManager{
  AppDelegate *appDelegate;
  DBManager *dbManager;
  NSArray *connectRecord;
  NSInteger previousPeersCount;
}

#pragma mark - init Methods
- (id)initWithDisplayName:(NSString *)displayName andInvitation:(NSNumber *) acceptInviation{
  self = [super init];
  if (self) {
    self.displayName = displayName;
    self.peerID = [[MCPeerID alloc] initWithDisplayName:self.displayName];
    self.acceptInvitation = [acceptInviation  boolValue];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //Create DBManager to have access to 'profileList.sql'
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
    //Create 'session' && 'nearbyAdvertise'
    if (self.acceptInvitation)
    {
      //Create 'session','nearybyAdvertiser'
      //Start advertising
      _session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
      _session.delegate = self;
      
      _nearbyAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:serviceTypeName];
      _nearbyAdvertiser.delegate = self;
      [_nearbyAdvertiser startAdvertisingPeer];
      
      _nearbyBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:serviceTypeName];
      _nearbyBrowser.delegate = self;
      [_nearbyBrowser startBrowsingForPeers];
      
      NSLog(@"Start advertising");
      NSLog(self.acceptInvitation ? @"Accept invitation is YES" : @"Accept invitation is NO");
    }
  }
  return self;
}

#pragma mark - Life Cycle
- (void)connect{
  NSAssert(self.displayName != nil, @"You Must set a displayname");
  NSAssert(self.peerID != nil, @"self.peerID must not be nil");
  NSAssert(self.session != nil, @"Session must not be nil");
  
  if (self.session) {
    NSLog(@"Peer %@ is connecting ", self.displayName);
    
    NSLog(self.inviteOtherPeers ? @"invite other peers is YES":@"invite other peers is NO");
    NSLog(self.acceptInvitation ? @"accept other peers is YES":@"accept other peers is NO");
    
    //Init 'nearbyBrowser' && Start 'browsingPeers'
    //Predicate whether 'nearbyBrowser' existed or not
    if (!self.nearbyBrowser) {
      _nearbyBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:serviceTypeName];
      _nearbyBrowser.delegate = self;
      [_nearbyBrowser startBrowsingForPeers];
    }else{//if 'nearbyBrowser' already existed, simply start browsing
      [_nearbyBrowser stopBrowsingForPeers];
      _nearbyBrowser.delegate = nil;
      _nearbyBrowser = nil;
      
      _nearbyBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:serviceTypeName];
      _nearbyBrowser.delegate = self;
      [_nearbyBrowser startBrowsingForPeers];
    }
  }
}

- (void) disconnect
{
  NSLog(@"Peer %@ is disonnecting", self.displayName);
  
  [self.nearbyAdvertiser stopAdvertisingPeer];
  self.nearbyAdvertiser.delegate = nil;
  self.nearbyAdvertiser = nil;
  
  [self.nearbyBrowser stopBrowsingForPeers];
  self.nearbyBrowser.delegate = nil;
  self.nearbyBrowser = nil;
  
  [self.session disconnect];
  self.session.delegate = nil;
  self.session = nil;
}

- (void)alertAdvertiserStatus:(NSNumber *) advertiseStatus{
  self.acceptInvitation = [advertiseStatus boolValue];
  if (!self.acceptInvitation) {
    //disconnect connection
    [self disconnect];
    NSLog(@"Stop advertising && disconnect");
    NSLog(self.acceptInvitation ? @"Accept invitation is YES" : @"Accept invitation is NO");
  }else{
    //Create 'session','nearybyAdvertiser'
    //Start advertising
    _session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
    _session.delegate = self;
    
    _nearbyAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:serviceTypeName];
    _nearbyAdvertiser.delegate = self;
    [_nearbyAdvertiser startAdvertisingPeer];
    
    NSLog(@"Start advertising");
    NSLog(self.acceptInvitation ? @"Accept invitation is YES" : @"Accept invitation is NO");
  }
}

#pragma mark - Private
- (void) getPeers :(NSString *)peerDisplayname andCurrentTime :(NSString *)currentTime
{
  /*
   Logic:
   1.get previous contact info from table 'connectRecord'
   2.wrap previous contact list (connected peer name <--> connected time) into a NSArray
      select * from table_name , get each of table 'contactInfo'
   3.update table 'contactInfo' with 'peerDisplayname' && 'currentTime'
   4.exchange with previous contact list
   5.update contact GUI
   */
  //user_name === contact_name
  NSString *contact_name = [appDelegate.defaults objectForKey:@"displayName"];
  NSString *queryForContact = [NSString stringWithFormat:@"select displayname,connectedtime from contactInfo where contact_name = '%@'",contact_name];
  if ([[dbManager loadDataFromDB:queryForContact] count] > 0) {
    NSLog(@"query success with query '%@'",queryForContact);
    connectRecord = [[NSArray alloc] initWithArray:[[dbManager loadDataFromDB:queryForContact] mutableCopy]];
    NSLog(@"loaded connectRecord count is %lu",(unsigned long)connectRecord.count);
    NSLog(@"loaded connectRecord is %@",connectRecord);
  }else
  {
    //init a NSArray with element " ";
    connectRecord = [[NSArray alloc] initWithObjects:@" ", nil];
    NSLog(@"exchange contact list is nil");
  }
  
  //update table 'contactInfo'
  NSString *insertQuery = [NSString stringWithFormat:@"insert into contactInfo values('%@','%@','%@')",contact_name,peerDisplayname,currentTime];
  [dbManager executeQuery:insertQuery];
  NSLog(@"%@ success",insertQuery);
  
  /*
   Create a new 'sendProfile' including : 
   1.self.displayName;
   2.connectedRecord;
   Send 'sendProfile' to 'peerDisplayname'
   */
  [self.client exchangeProfileWithName:self.displayName andContactList:connectRecord withDestPeerName:peerDisplayname];
}

#pragma mark MCSessionDelegate methods
- (NSString *) stringFroState: (MCSessionState) state{
  switch (state) {
    case MCSessionStateConnected:
      return @"Connected";
      break;
    case MCSessionStateConnecting:
      return @"Connecting";
      break;
    case MCSessionStateNotConnected:
      return @"not Connected";
      break;
  }
}

- (void) session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
  NSLog(@"didReceiveData %d", (int)data.length);
  [self.client processData:data fromPeer:peerID];
}

- (void) session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
  /*
   whenever peers are connected;
   exchange 'profile' automatically;
   */
  NSLog(@"peerID %@ is %@",peerID.displayName,[self stringFroState:state]);
  //When peer is connected with others
  //Exchange 'profile' via method 'getPeers'
  //Update 'contactList' of own
  if ([[self stringFroState:state] isEqualToString:@"Connected"])
  {
    //Get current time associated with conneted peer
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy.MM.dd-HH:mm:ss"];
    NSString *currentTime = [formatter stringFromDate:[NSDate date]];
    NSLog(@"current time is %@",currentTime);
    [self getPeers:peerID.displayName andCurrentTime:currentTime];
  }
}

#pragma mark - MCNearbyServiceAdvertiserDelegate
- (void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error{
  NSLog(@"Advertiser %@ did not start advertising with error : %@",self.displayName,error.description);
}

- (void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler{
  NSLog(@"Advertiser %@ received an invitation from %@", self.peerID.displayName, peerID.displayName);
BOOL probateIpad31 = [peerID.displayName isEqualToString:@"CS-iPad-3-1"];
  BOOL probateiPhone = [peerID.displayName isEqualToString:@"iPhone"];
//  if (probateIpad31) {
//    invitationHandler(NO,self.session);
//  }else{
    invitationHandler(YES,self.session);
//  }
  NSLog(@"Advertiser %@ accepted invitation from %@", self.peerID.displayName, peerID.displayName);
}

#pragma mark - MCNearbyServiceBrowseDelegate
- (void) browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error{
  NSLog(@"Browser %@ did not start browsing with error : %@ ",self.displayName,error.description);
}

- (void) browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info{
  NSLog(@"Browser %@ found peers : %@",self.displayName,peerID.displayName);
  //Check whether foundPeer already existed in 'contact' List
  /* 
   if(foundPeer existed in 'connectRecord')
   {
      invite 'foundPeer' to connect;
      if('foundPeer' connected)
      {
        exchange 'Profile' with 'foundPeer';
      }
   }else{
      operate via normal process
   }
   */
//  NSString *query = @"select distinct displayname from contactInfo";
//  NSArray *connectedPeers = [[NSArray alloc] initWithArray:[dbManager loadDataFromDB:query]];
//  NSLog(@"get connectedPeers are %@",connectedPeers);
  BOOL shouldInvite = self.peerID.hash < peerID.hash;
//  NSString *peerIdName = peerID.displayName;
  BOOL probateIpad31 = [peerID.displayName isEqualToString:@"CS-iPad-3-1"];
  BOOL probateiPhone = [peerID.displayName isEqualToString:@"iPhone"];
  if (shouldInvite && !probateIpad31)
  {
    [self.nearbyBrowser invitePeer:peerID toSession:self.session withContext:nil timeout:10];
  }else
  {
      NSLog(@"Browser %@ does not invite %@ to connect", self.peerID.displayName, peerID.displayName);
  }
}

- (void) browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
  NSLog(@"Browser %@ lost %@",self.displayName,peerID.displayName);
//  [self getPeers:peerID.displayName];
}

#pragma mark SessionManager methods
- (BOOL) hasPeers{
  return (self.session.connectedPeers.count > 0);
}

- (void) sendData:(NSData *)data{
  NSLog(@"sendData %d",(int)data.length);
  NSError *error;
  NSLog(@"connectedPeers are %@",self.session.connectedPeers);
  [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
  NSLog(@"data send successfully");
  //store message into table 'sendMessage'
  //1.parsing JSONData
  NSDictionary *jsonDic = [(NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error] copy];
  NSArray *jsonArry = (NSArray *)[[jsonDic objectForKey:@"message"] copy];
  NSString *messageID = [jsonArry[0] copy];//[0] --> messageId
  NSString *protocolType = [jsonArry[1] copy];//[1] --> protocolType
  NSString *destPeer = [jsonArry[2] copy];//[2] --> destPeerName
  NSString *content = [jsonArry[3] copy];//[3] --> messageContent
  NSArray *timeAndSender = [jsonArry[4] copy];
  NSString *sendtime = [timeAndSender[0][0] copy];//[4] --> hopList(* NSArray)
  NSString *longitude = [jsonArry[6] copy];//[6] --> longtitude
  NSString *latitude = [jsonArry[7] copy];//[7] --> latitude
  NSString *address = [jsonArry[8] copy];//[8] --> address
  NSString *sender_name = [appDelegate.defaults objectForKey:@"displayName"];
  //2.store into table 'sendMessage(messageid text primary key,sendtime text,protocoltype text,destpeer text,textcontent text)
  NSString *insertSendMessage = [NSString stringWithFormat:@"insert into sendMessage(messageid,send_name,sendtime,protocoltype,destpeer,textcontent,longitude,latitude,address) values('%@','%@','%@','%@','%@','%@','%@','%@','%@')",messageID,sender_name,sendtime,protocolType,destPeer,content,longitude,latitude,address];
  [dbManager executeQuery:insertSendMessage];
  NSLog(@"%@",insertSendMessage);
}

- (void) forwardMessage :(NSData *)data toDestPeer :(NSString *)destPeerName{
  NSLog(@"forward message %d to peer %@",(int)data.length,destPeerName);
  NSError *localError = nil;
  /*
   if(destPeerName isEqualTo " ")
   {
      save message.
   }else
   {
      send to destination peer
      if(destination peer exists in list of connected peers)
      {
        forward message to destination peer without saving;
      }else{
        push message to (all connected peer)/(jumped hops);
      }
   }
   */
  if ([destPeerName isEqualToString:@" "])
  {
    NSLog(@"save message");
    //save message into table : receivedmessage
    
    
    
  }else{
    NSError *error;
    NSUInteger destPeerIndex = -1;
    //check whether destination peer exists in list of connected peers
    for (MCPeerID *peer in self.session.connectedPeers)
    {
      if ([peer.displayName isEqualToString:destPeerName])
      {
        destPeerIndex = [self.session.connectedPeers indexOfObject:peer];
      }
    }
    /*
     if(destination peer existed in list of connected peers)
     {
        send data to destination peer
     }else{
        push message to |connectedPeers - jumpedHops|.
     }
     */
    if (destPeerIndex != -1)
    {
      NSLog(@"push message to %@", destPeerName);
      NSArray *peers = [[NSArray alloc] initWithObjects:[self.session.connectedPeers objectAtIndex:destPeerIndex], nil];
      [self.session sendData:data toPeers:peers withMode:MCSessionSendDataReliable error:&error];
    }else
    {
      //parsing json data 'data'
      NSArray *jsonArry = (NSArray *)[[[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error] objectForKey:@"message"] copy];
      NSArray *jumpedHops = (NSArray *)[[jsonArry objectAtIndex:5] copy];
      
      //calculate 'substracted' set of |connectedPeers - jumpedHops|
      NSMutableArray *pushDestPeers = [[NSMutableArray alloc] init];
      for (MCPeerID *peer in self.session.connectedPeers)
      {
        BOOL foundJumpedPeer = NO;
        for (NSString *jumpedHopName in jumpedHops)
        {
          if ([jumpedHopName isEqualToString:peer.displayName])
          {
            foundJumpedPeer = YES;
            break;
          }
        }
        if (foundJumpedPeer == NO)
        {
          [pushDestPeers addObject:peer];
        }
      }
      /*
       if(connectedPeers is a subset of jumpedHops)
       {
          don't push;
       }else{
          push message to 'substracted' set of |connectedPeers - jumpedHops|;
       }
       */
      if (pushDestPeers.count > 0)
      {
        NSLog(@"push message to %@",pushDestPeers);
        NSString *printJsonData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",printJsonData);
        [self.session sendData:data toPeers:pushDestPeers withMode:MCSessionSendDataReliable error:&error];
      }else
      {
        NSString *printJsonData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",printJsonData);
        NSLog(@"message connot be pushed as all connected peers were jumped before");
      }
    }
  }

}

- (void) sendMessage :(NSData *)data toDestPeer :(NSString *)destPeerName{
  NSLog(@"sendMessage %d to peer %@",(int)data.length,destPeerName);
  NSError *localError = nil;
  /*
   if(destPeerName isEqualTo " ")
   {
      save message.
   }else
   {
      send to destination peer
   }
   */
  NSError *error;
  NSUInteger destPeerIndex = -1;
  
  //Find out index of destination peer
  for (MCPeerID *peer in self.session.connectedPeers)
  {
    if ([peer.displayName isEqualToString:destPeerName])
    {
      destPeerIndex = [self.session.connectedPeers indexOfObject:peer];
    }
  }
  /*if(destination peer found)
  {
   send Message to destination Peer
  }else{
    broadcast;
  }
   */
  if (destPeerIndex !=-1)
  {
    NSArray *peers = [[NSArray alloc] initWithObjects:[self.session.connectedPeers objectAtIndex:destPeerIndex], nil];
    [self.session sendData:data toPeers:peers withMode:MCSessionSendDataReliable error:&error];
    
    //store message into table 'sendMessage'
    //1.parsing JSONData
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&localError];
    NSArray *jsonArry = [[jsonDic objectForKey:@"message"] copy];
    NSString *messageID = [jsonArry[0] copy];//[0] --> messageId
    NSString *protocolType = [jsonArry[1] copy];//[1] --> protocolType
    NSString *destPeer = [jsonArry[2] copy];//[2] --> destPeerName
    NSString *content = [jsonArry[3] copy];//[3] --> messageContent
    NSArray *timeAndSender = [jsonArry[4] copy];
    NSString *sendtime = [timeAndSender[0][0] copy];//[4] --> hopList(* NSArray)
    NSString *longitude = [jsonArry[6] copy];//[6] --> longtitude
    NSString *latitude = [jsonArry[7] copy];//[7] --> latitude
    NSString *address = [jsonArry[8] copy];//[8] --> address
    NSString *sender_name = [appDelegate.defaults objectForKey:@"displayName"];
//      NSString *sendname = [hopList[1] copy];
    //2.store into table 'sendMessage(messageid text primary key,sendtime text,protocoltype text,destpeer text,textcontent text)
    NSString *insertSendMessage = [NSString stringWithFormat:@"insert into sendMessage(messageid,send_name,sendtime,protocoltype,destpeer,textcontent,longitude,latitude,address) values('%@','%@','%@','%@','%@','%@','%@','%@','%@')",messageID,sender_name,sendtime,protocolType,destPeer,content,longitude,latitude,address];
    [dbManager executeQuery:insertSendMessage];
    NSLog(@"%@",insertSendMessage);
  }else{
    NSLog(@"Destination peer not connected, then broadcast message to all connected peers");
    [self sendData:data];
  }
 }

- (void) exchangeData:(NSData *)data withDestPeerName:(NSString *)destPeerName{
  NSLog(@"exchangeData %d with peer :%@",(int)data.length,destPeerName);
  NSError *error;
  NSUInteger destPeerIndex = -1;
  //Find out index for destination peer
  /*if(found)
  {
    assign index to 'destPeerIndex';
  }
  */
  for (MCPeerID *peer in self.session.connectedPeers)
  {
    if ([peer.displayName isEqualToString:destPeerName])
    {
       destPeerIndex = [self.session.connectedPeers indexOfObject:peer];
    }
  }
  //if (destPeerIndex exists) : exchange data with destination peer
  if (destPeerIndex != -1)
  {
    NSArray *peers = [[NSArray alloc] initWithObjects:[self.session.connectedPeers objectAtIndex:destPeerIndex], nil];
    [self.session sendData:data toPeers:peers withMode:MCSessionSendDataReliable error:&error];
  }
}
@end//SessionManager
