//
//  FirstViewController.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/4/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "MessageDisplayViewController.h"
#import "MessageDetailControllerTableViewController.h"
#import "SessionManager.h"
#import "ServiceConnector.h"
#import "AppDelegate.h"
#import "DBManager.h"
#import "Message.h"
#import "messageCustomCell.h"



@interface MessageDisplayViewController ()<UITableViewDataSource,UITableViewDelegate,UITabBarControllerDelegate,ServiceConnectorDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *alertMessages;
@property (strong, nonatomic) NSMutableDictionary *contactList;
@property (strong, nonatomic) NSArray *messageIds;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadMessages;
@end

@implementation MessageDisplayViewController{
  AppDelegate *appDelegate;
  DBManager *dbManager;
  BOOL messageDisplay;
  BOOL canMulSelected;
  NSArray *senderNames;
  NSMutableDictionary *selectedMessages;
  NSMutableDictionary *button_selection;
  NSString *messageText;
}

#pragma mark - Private Methods
- (void)reloadTableView{
  NSString *user_name = [appDelegate.defaults objectForKey:@"displayName"];
  if (messageDisplay)
  {
    self.messageIds = nil;
    NSString *queryMessageIds = [NSString stringWithFormat:@"select messageid from receivedMessage where receiver_name = '%@'",user_name];
    self.messageIds = [[dbManager loadDataFromDB:queryMessageIds] mutableCopy];
    NSLog(@"message ID count : %lu",(unsigned long)self.messageIds.count);
  }else{
    self.messageIds = nil;
    NSString *querySendMessage = [NSString stringWithFormat:@"select messageid from sendMessage where send_name = '%@'",user_name];
    self.messageIds = [[dbManager loadDataFromDB:querySendMessage] mutableCopy];
    NSLog(@"sent message count :%lu",(unsigned long)self.messageIds.count);
  }

  [self.tableView reloadData];
}

#pragma mark - Synchronizing messages Methods
- (void)uploadMessagesToCloud:(NSDictionary *)messages_dic{
  /*
   submit all received messages in local db to web service;
   then refresh table 'reveived_messages': replace table 'received_message' in cloud db with table 'receivedMessage' in local db;
   */
  ServiceConnector *connector = [[ServiceConnector alloc] init];
  connector.delegate = self;
  
  //get all message_ids from keys of dictionary
  NSArray *selectedIds = [[NSArray alloc] initWithArray:[messages_dic allKeys] copyItems:YES];
  //select all information of messages where id = selectedMessages[i]
  NSMutableArray *messages = [[NSMutableArray alloc] initWithCapacity:50];
  if ([selectedIds count] > 0)
  {
    for (NSString *message_id in selectedIds)
    {
      NSMutableString *queryMessage = [[NSMutableString alloc] init];
      
      messageDisplay ?
      [queryMessage appendString:[NSString stringWithFormat:@"select * from receivedMessage where messageid = '%@'",message_id]] :
      [queryMessage appendString:[NSString stringWithFormat:@"select * from sendMessage where messageid = '%@'",message_id]];
      NSArray *messageInfo = [[dbManager loadDataFromDB:queryMessage] mutableCopy];
      
      NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
      [dictionary setValue:[messageInfo[0][0] mutableCopy] forKey:@"message_id"];
      messageDisplay ? [dictionary setObject:messageInfo[0][1] forKey:@"receiver_name"] : [dictionary setValue:[messageInfo[0][1] mutableCopy]forKey:@"send_name"];
      
      NSMutableArray *jsonArry = [[NSMutableArray alloc] initWithCapacity:9];
      /*
       if(messageDisplay -> received_message)
       else (messageDisplay -> send_message)
       */
      if (messageDisplay)
      {
        [jsonArry addObject:[messageInfo[0][2] mutableCopy]];//protocol
        [jsonArry addObject:[messageInfo[0][3] mutableCopy]];//sendtime
        [jsonArry addObject:[messageInfo[0][4] mutableCopy]];//sentname
        [jsonArry addObject:[messageInfo[0][5] mutableCopy]];//textcontent
        [jsonArry addObject:[messageInfo[0][6] mutableCopy]];//hoplist
        [jsonArry addObject:[messageInfo[0][7] mutableCopy]];//longitude
        [jsonArry addObject:[messageInfo[0][8] mutableCopy]];//latitude
        [jsonArry addObject:[messageInfo[0][9] mutableCopy]];//address
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArry options:kNilOptions error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"print json string : %@",jsonString);
        
        [dictionary setValue:jsonString forKey:@"json_string"];
        [messages addObject:dictionary];
      }else{
        [jsonArry addObject:[messageInfo[0][2] mutableCopy]];//sendtime
        [jsonArry addObject:[messageInfo[0][3] mutableCopy]];//protocoltype
        [jsonArry addObject:[messageInfo[0][4] mutableCopy]];//destpeer
        [jsonArry addObject:[messageInfo[0][5] mutableCopy]];//textcontent
        [jsonArry addObject:[messageInfo[0][6] mutableCopy]];//longitude
        [jsonArry addObject:[messageInfo[0][7] mutableCopy]];//latitude
        [jsonArry addObject:[messageInfo[0][8] mutableCopy]];//address
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArry options:kNilOptions error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSLog(@"print json string : %@",jsonString);
        
        [dictionary setValue:jsonString forKey:@"json_string"];
        [messages addObject:dictionary];
      }
    }
  }else{
    NSLog(@"selected messages connot be nil");
  }
  
  //set string for message_type
  NSMutableString *message_type = [[NSMutableString alloc] initWithCapacity:15];
  messageDisplay ? ([message_type setString:@"received_message"]) : ([message_type setString:@"send_message"]);
  
  if ([messages count] > 0)
  {
    [connector uploadMessagesToCloud:[messages mutableCopy] withMessageType:message_type];
    messages = nil;
  }else{
    NSLog(@"upload messages connot be nil");
  }
  
  //release connector
  connector = nil;
}

- (void)downloadMessagesFromCloud{
  /*
   messageDisplay ? received_message : send_message
   {
      send request to web service for getting all associated messages;
   
      download messages associated with user_name from cloud db;
      compare each message_id derived from cloud with local message_ids;
      matched ? jump to next : store into local db;
   }
   */
  ServiceConnector *connector = [[ServiceConnector alloc] init];
  connector.delegate = self;
  
  //get message_type
  NSMutableString *message_type = [[NSMutableString alloc] initWithCapacity:15];
  messageDisplay ? [message_type appendString:@"received_message"] : [message_type appendString:@"send_message"];
  
  //get user_name
  NSString *user_name = [appDelegate.defaults objectForKey:@"displayName"];
  
  //invoke method to downloading messages from cloud
  [connector downloadMessagesFromCloudDbWithUserName:user_name];
  
//  //release connector
//  connector = nil;
}

- (IBAction)uploadMessages:(UIBarButtonItem *)sender {
  NSLog(@"upload");
//  if ([self.uploadMessages.title isEqualToString:@"Upload"])
//  {
//    self.editButton.title = @"Cancel";
//    self.uploadMessages.title = @"Send";
//    canMulSelected = NO;
//  }else if([self.uploadMessages.title isEqualToString:@"Send"]){
//    self.uploadMessages.title = @"Upload";
//    self.editButton.title = @"Download";
//    canMulSelected = YES;
//    //upload messages to cloud
//    [self uploadMessagesToCloud:selectedMessages];
//  }else if ([self.uploadMessages.title isEqualToString:@"Cancel"]){
//    self.uploadMessages.title = @"Upload";
//    self.editButton.title = @"Download";
//  }
  [self uploadMessagesToCloud:selectedMessages];
}

- (IBAction)downloadOrCancel:(UIBarButtonItem *)sender {
//  if ([self.editButton.title isEqualToString:@"Download"])
//  {
//    //download messages from cloud
//    NSLog(@"Download");
//    [self downloadMessagesFromCloud];
//  }else{
//    self.editButton.title = @"Download";
//    self.uploadMessages.title = @"Upload";
//  }
  NSLog(@"download");
  [self downloadMessagesFromCloud];
}

- (void)checkboxSelected:(id)sender{
  UIButton *button = sender;
  NSLog(@"custome cell button tag : %ld",(long)button.tag);
  
  NSIndexPath *selected_row = [NSIndexPath indexPathForRow:button.tag inSection:0];
  messageCustomCell *selected_cell = (messageCustomCell *)[self.tableView cellForRowAtIndexPath:selected_row];
  /*
   check dictionary 'button_selection'
   if([value->cell.messageIdLabel isEqualTo: @"Unselected"])
   {
      set associated cell accessoryView.hidden as NO;
      set button image as @"Checked-Checkbox-24.png";
      set value @"Selected" for key cell.messageIdLabel in dictionary 'button_selection';
      set value cell.messageDetail.text for key cell.messageIdLabel in dictionary 'selectedMessages';
   }else{
      set associated cell accessoryView.hidden as YES;
      set button image as @"Unchecked-Checkbox-24.png";
      set value @"Unselected" for key cell.messageIdLabel in dictionary 'button_selection';
      remove key cell.messageIdLabel in dictionary 'selectedMessages';
   }
   */
  NSLog(@"checkbox : %@",[button_selection objectForKey:selected_cell.messageIdLabel.text]);
  if ([[button_selection objectForKey:selected_cell.messageIdLabel.text] isEqualToString:@"Unselected"])
  {
    selected_cell.accessoryView.hidden = NO;
    [button setImage:[UIImage imageNamed:@"Checked-Checkbox-24.png"] forState:UIControlStateNormal];
    [button setNeedsDisplay];
    [button_selection setValue:@"Selected" forKey:[selected_cell.messageIdLabel.text mutableCopy]];
    [selectedMessages setValue:[selected_cell.messageDetailLabel.text mutableCopy] forKey:[selected_cell.messageIdLabel.text mutableCopy]];
  }else{
    selected_cell.accessoryView.hidden = YES;
    [button setImage:[UIImage imageNamed:@"Unchecked-Checkbox-24.png"] forState:UIControlStateNormal];
    [button setNeedsDisplay];
    [button_selection setValue:@"Unselected" forKey:[selected_cell.messageIdLabel.text mutableCopy]];
    [selectedMessages removeObjectForKey:[selected_cell.messageIdLabel.text mutableCopy]];
  }
  NSLog(@"%@",selected_cell.messageIdLabel.text);
}

#pragma mark - UITableView Delegate Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  return self.messageIds.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
  return 80.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  messageCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageDisplayCell"];
  
//  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageDisplayCell"];
  [cell.checkbox setFrame:CGRectMake(20, 70, 80, 40)];
  [cell.checkbox setImage:[UIImage imageNamed:@"Unchecked-Checkbox-24.png"] forState:UIControlStateNormal];
  [cell.checkbox imageRectForContentRect:CGRectMake(0, (CGRectGetHeight(cell.checkbox.frame) - Q_CHECK_ICON_WH)/2.0, Q_CHECK_ICON_WH, Q_CHECK_ICON_WH)];
  [cell.checkbox setTag:indexPath.row];
  [cell.checkbox addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchUpInside];
  
  cell.messageIdLabel.text = self.messageIds[indexPath.row][0];
  /*
   if(messageDisplay == YES)
   {
      Display received messages;
   }else{
      Display sent messages;
   }
   */
  NSString *user_name = [appDelegate.defaults objectForKey:@"displayName"];
  if (messageDisplay)
  {
    NSString *querySenderName = [NSString stringWithFormat: @"select sendname from receivedMessage where messageid = '%@' and receiver_name = '%@'",self.messageIds[indexPath.row][0],user_name];
    NSArray *senderName = [[dbManager loadDataFromDB:querySenderName] mutableCopy];
    cell.messageDetailLabel.text = [@"Sender : " stringByAppendingString: senderName[0][0]];
  }else
  {
    NSString *querySenderTime =  [NSString stringWithFormat: @"select sendtime from sendMessage where messageid = '%@' and send_name = '%@'",self.messageIds[indexPath.row][0],user_name];
    NSArray *sendTime = [[dbManager loadDataFromDB:querySenderTime] mutableCopy];
    cell.messageDetailLabel.text = [@"Send Time :" stringByAppendingString:sendTime[0][0]];
  }
  
  //set up dictionaries 'selectedMessages' && 'button_selection' relatively
  [selectedMessages setValue:[cell.messageDetailLabel.text mutableCopy] forKey:[cell.messageIdLabel.text mutableCopy]];
  [button_selection setValue:@"Unselected" forKey:[cell.messageIdLabel.text mutableCopy]];
  return cell;
}

#pragma mark - 'viewDidLoad' Methods
- (void)viewDidLoad {
  NSLog(@"viewDidLoad (MessageDisplay ViewController)");
  [super viewDidLoad];
  
  //Set delegate && datasource of 'tableView'
  [self.tableView setDelegate:self];
  [self.tableView setDataSource:self];
  [self.tableView setAllowsMultipleSelection:YES];
  
  //Init 'appDelegate' because of that we need to utilize its variable 'sessionMngr'
  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
  //Init 'dbManager' for loading received message
  dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
  //retrieve messageIds to display
//  NSString *queryMessageIds = @"select messageid from receivedMessage";
//  self.messageIds = [dbManager loadDataFromDB:queryMessageIds];
//  NSLog(@"message ID count : %lu",(unsigned long)self.messageIds.count);
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  //clear highlighted row for tableview
  [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
  [self.tableView reloadData];
  
  NSLog(@"viewWillAppear");
  if (!dbManager) {
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
  }
  
  if (!appDelegate) {
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  }
  
  messageDisplay = [[appDelegate.defaults objectForKey:@"receiveOrSend"] boolValue];
  canMulSelected = YES;
  
  //clear selectedMessages
  if (selectedMessages)
  {
    selectedMessages = nil;
  }
  
  if (button_selection) {
    button_selection = nil;
  }
  
  //init array for info of selected cells && associated buttons which is subview of each cell
  selectedMessages = [[NSMutableDictionary alloc] initWithCapacity:50];
  button_selection = [[NSMutableDictionary alloc] initWithCapacity:50];
  
  NSString *user_name = [appDelegate.defaults objectForKey:@"displayName"];
  
  if (messageDisplay)
  {
    self.messageIds = nil;
    NSString *queryMessageIds = [NSString stringWithFormat:@"select messageid from receivedMessage where receiver_name = '%@'",user_name];
    self.messageIds = [[dbManager loadDataFromDB:queryMessageIds] mutableCopy];
    NSLog(@"message ID count : %lu",(unsigned long)self.messageIds.count);
  }else{
    self.messageIds = nil;
    NSString *querySendMessage = [NSString stringWithFormat:@"select messageid from sendMessage where send_name = '%@'",user_name];
    self.messageIds = [[dbManager loadDataFromDB:querySendMessage] mutableCopy];
    NSLog(@"sent message count :%lu",(unsigned long)self.messageIds.count);
  }
  //retrieve messageIds to display
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - uiswitchSegment to switch displayed messages
- (IBAction)alertMessagesDisplay:(UISegmentedControl *)sender {
  /*
   if(UISegment.selected == 'received')
   {
      load received messages;
   }else{
      load send messages;
   }
   */
  self.messageIds = nil;
  //clear selectedMessages
  if (selectedMessages)
  {
    selectedMessages = nil;
  }
  
  if (button_selection) {
    button_selection = nil;
  }
  
  //init array for info of selected cells && associated buttons which is subview of each cell
  selectedMessages = [[NSMutableDictionary alloc] initWithCapacity:50];
  button_selection = [[NSMutableDictionary alloc] initWithCapacity:50];
  
  NSString *user_name = [appDelegate.defaults objectForKey:@"displayName"];
  if (sender.selectedSegmentIndex == 0)
  { //retrieve data of received messages
    NSString *queryMessageIds = [NSString stringWithFormat:@"select messageid from receivedMessage where receiver_name='%@'",user_name];
    self.messageIds = [[dbManager loadDataFromDB:queryMessageIds] mutableCopy];
    NSLog(@"received message count : %lu",(unsigned long)self.messageIds.count);
    messageDisplay = YES;
    [appDelegate.defaults setObject:[NSNumber numberWithBool:YES] forKey:@"receiveOrSend"];
  }else
  { //retrieve data of send messages
    self.messageIds = nil;
    NSString *querySendMessage = [NSString stringWithFormat:@"select messageid from sendMessage where send_name = '%@'",user_name];
    self.messageIds = [[dbManager loadDataFromDB:querySendMessage] mutableCopy];
    NSLog(@"sent message count :%lu",(unsigned long)self.messageIds.count);
    messageDisplay = NO;
    [appDelegate.defaults setObject:[NSNumber numberWithBool:NO] forKey:@"receiveOrSend"];
  }
  
  [self reloadTableView];
}

#pragma mark - prepareForSegue method
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
  NSLog(@"showMessageDetail");
  if (![segue.identifier isEqualToString:@"showMessageDetail"]) return;
  
  NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
  NSString *messageId = ((messageCustomCell *)[self.tableView cellForRowAtIndexPath:selectedRow]).messageIdLabel.text;
  
  if (messageId != nil) {
    [[segue destinationViewController] setMessageId:messageId];
    [[segue destinationViewController] setReceivedOrSent:messageDisplay];
  }
}

#pragma mark - ServiceConnectorDelegate methods
- (void)requestReturnedDataToUploadMessages:(NSData *)data{
  NSLog(@"request returned to upload messages");
  NSError *error;
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
  
  NSString *validation = [dictionary objectForKey:@"validate"];
  
  if ([validation isEqualToString:@"true"])
  {
    NSLog(@"upload success");
  }else{
    NSLog(@"%@",validation);
  }
}

-(void)requestReturnedDataToDownloadMessages:(NSData *)data{
  NSLog(@"request returned to download messages");
  NSError *error;
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
  
  NSString *validation = [dictionary objectForKey:@"validate"];
  
  if ([validation isEqualToString:@"true"])
  {
    /*
     'received_messages' -> array of received messages
     'send_messages' -> array of send_messages
     
     each element of array is a dictionary:
     message_id -> message_id;
     receiver_name || sender_name (cloud db column,'send_name' in local db)
     json_string:
     {
        received_message:
         [0]protocol
         [1]sendtime
         [2]sentname
         [3]textcontent
         [4]hoplist
         [5]longitude
         [6]latitude
         [7]address
     
        send_message:
         [0]sendtime
         [1]protocoltype
         [2]destpeer
         [3]textcontent
         [4]longitude
         [5]latitude
         [6]address
     }
     */
//    NSString *user_name = [appDelegate.defaults objectForKey:@"displayName"];
    if ([dictionary objectForKey:@"received_messages"])
    {
      NSArray *cloud_received_messages = [[dictionary objectForKey:@"received_messages"] mutableCopy];
      
      NSLog(@"downloaded received messages are : %@",[dictionary objectForKey:@"received_messages"]);
      for (NSDictionary *dic in cloud_received_messages)
      {
        NSString *message_id = [dic objectForKey:@"message_id"];
        NSString *receiver_name = [dic objectForKey:@"receiver_name"];
        NSString *json_string = [dic objectForKey:@"json_string"];
        //transform json_string to json data, then to array
        NSError *error;
        NSData *json_data = [json_string dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *received_message_array = [NSJSONSerialization JSONObjectWithData:json_data options:kNilOptions error:&error];
        /*
         [0]protocol
         [1]sendtime
         [2]sentname
         [3]textcontent
         [4]hoplist
         [5]longitude
         [6]latitude
         [7]address
         */
        NSString *protocol = [received_message_array[0] mutableCopy];
        NSString *sendtime = [received_message_array[1] mutableCopy];
        NSString *sendname = [received_message_array[2] mutableCopy];
        NSString *textcontent = [received_message_array[3] mutableCopy];
        NSString *hoplist = [received_message_array[4] mutableCopy];
        NSString *longitude = [received_message_array[5] mutableCopy];
        NSString *latitude = [received_message_array[6] mutableCopy];
        NSString *address = [received_message_array[7] mutableCopy];
        
        NSString *insertDb = [NSString stringWithFormat:@"insert into receivedMessage values('%@','%@','%@','%@','%@','%@','%@','%@','%@','%@')",message_id,receiver_name,protocol,sendtime,sendname,textcontent,hoplist,longitude,latitude,address];
        [dbManager executeQuery:insertDb];
        NSLog(@"%@",insertDb);
      }
    }
    
    if ([dictionary objectForKey:@"send_messages"])
    {
      NSArray *cloud_send_messages = [[dictionary objectForKey:@"send_messages"] mutableCopy];
      
      for (int i=0; i<cloud_send_messages.count; i++)
      {
        NSDictionary *dic = [[cloud_send_messages objectAtIndex:i] mutableCopy];
        NSLog(@"dic is :%@",dic);
        NSString *message_id = [dic objectForKey:@"message_id"];
        NSString *send_name = [dic objectForKey:@"send_name"];
        NSString *json_string = [dic objectForKey:@"json_string"] ;
        //transform json_string to json data, then to array
        NSError *error;
        NSData *json_data = [json_string dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *send_message_array = [NSJSONSerialization JSONObjectWithData:json_data options:kNilOptions error:&error];
        NSLog(@"send_message_array : %@",send_message_array);
        /*
         [0]sendtime
         [1]protocoltype
         [2]destpeer
         [3]textcontent
         [4]longitude
         [5]latitude
         [6]address
         */
        NSString *sendtime = [send_message_array[0] mutableCopy];
        NSString *protocoltype = [send_message_array[1] mutableCopy];
        NSString *destpeer = [send_message_array[2] mutableCopy];
        NSString *textcontent = [send_message_array[3] mutableCopy];
        NSString *longitude = [send_message_array[4] mutableCopy];
        NSString *latitude = [send_message_array[5] mutableCopy];
        NSString *address = [send_message_array[6] mutableCopy];

        NSString *insertDb = [NSString stringWithFormat:@"insert into sendMessage values('%@','%@','%@','%@','%@','%@','%@','%@','%@')",message_id,send_name,sendtime,protocoltype,destpeer,textcontent,longitude,latitude,address];
        [dbManager executeQuery:insertDb];
        NSLog(@"%@",insertDb);
      }
    }
    [self reloadTableView];
}
}
@end
