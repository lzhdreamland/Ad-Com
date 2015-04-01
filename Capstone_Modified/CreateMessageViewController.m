//
//  CreateMessageViewController.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/20/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "CreateMessageViewController.h"
#import "AppDelegate.h"
#import "DBManager.h"
#import "addressManager.h"
#import "networkCheckManager.h"
#import "Message.h"


@interface CreateMessageViewController ()<SessionClientProtocol,UITextViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate,CLLocationManagerDelegate>
@property (strong, nonatomic) IBOutlet UITextView *textInputView;

@end

@implementation CreateMessageViewController{
  AppDelegate *appDelegate;
  DBManager *dbManager;
  UIPickerView *prototypePicker;
  UIToolbar *toolBar;
  CLLocationManager *locationMngr;
  CLGeocoder *geoCoder;
  CLPlacemark *placeMark;
  NSMutableDictionary *contactList;
  NSArray *protocolTypes;
  BOOL protocolSelectedMark;
  NSArray *destPeers;
  NSString *selectedPeer;
  NSString *messageContent;
  NSString *protocolType;
  NSArray *locationsArry;
  NSString *address;
}

#pragma mark - Private Methods
//private method to generate unique messageID
- (NSString *)generateMessageId:(NSString *)senderName{
  //using 'UUID String' as unique message id
  NSString *uuid = [[NSUUID UUID] UUIDString];
  NSLog(@"print random messageID : %@",uuid);
  return uuid;
}


- (IBAction)done:(id)sender {
  NSLog(@"create message done");
  [self dismissViewControllerAnimated: YES completion: nil];
  [self.delegate createMessageDidFinish:self];
}

////private method to start updating location
//- (void)getGpsLocation{
//  locationMngr = [[CLLocationManager alloc] init];
//  locationMngr.delegate = self;
//  
//  [locationMngr startUpdatingLocation];
//}

//display protocol type selections
- (IBAction)selectProtocol:(UIButton *)sender {
  //set variable 'hidden' of destPeerPicker to NO
  //display picker view for protocol type options
  CGRect bounds = self.view.bounds;
  CGFloat width = bounds.size.width;
  CGFloat height = bounds.size.height;
  
  //  UIView *pickerBackView = [[UIView alloc] initWithFrame:CGRectMake(0, height-260, width, 260)];
  //  pickerBackView.backgroundColor = [UIColor grayColor];
  
  
  toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, height-194.0, width, 44.0)];
  
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:self
                                                                action:@selector(donePicker)];
  
  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(cancelPicker)];
  
  UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                            target:self
                                                                            action:nil];
  
  [toolBar setItems:[NSArray arrayWithObjects:cancelButton,flexible, doneButton, nil]];
  
  prototypePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0f, height-150.0f, width, 150.0f)];
  prototypePicker.showsSelectionIndicator = YES;
  prototypePicker.backgroundColor = [UIColor grayColor];
  prototypePicker.delegate = self;
  prototypePicker.dataSource = self;
  
  [self.view addSubview:prototypePicker];
  [self.view addSubview:toolBar];
}

- (void)donePicker{
  [prototypePicker removeFromSuperview];
  [toolBar removeFromSuperview];
  protocolSelectedMark = NO;
}

- (void)cancelPicker{
  [prototypePicker removeFromSuperview];
  [toolBar removeFromSuperview];
  protocolSelectedMark = NO;
}

- (IBAction)sendNewMessage:(UIButton *)sender {
  /*
   if(selected Peer in pickerView)
   {
      Create Message with destPeer -- selectedPeer
      Transmit Message in JSON data;
   }else
   {
      broadcast Message to all connectedPeers;
      destPeerName = @" ";
   }
   */
  NSLog(@"sendNewMessage");

  NSMutableArray *jsonArry = [[NSMutableArray alloc] init];
  NSMutableDictionary *jsonDic = [[NSMutableDictionary alloc] init];
  NSMutableArray *timeAndSender = [[NSMutableArray alloc] init];
  NSMutableArray *jumpedHops = [[NSMutableArray alloc] init];
  NSLog(@"print locations when send: %@",locationsArry);
  NSLog(@"print address when send: %@",address);
  
  NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy.MM.dd-HH:mm:ss"];

  //1.getting messageID via public method 'generateMessageId'
  NSString *messageId = [self generateMessageId:[appDelegate.defaults objectForKey:@"displayName"]];
  //2.getting protocolType name(protocolType)
  //make sure protocolType is not nil
  if (protocolType == nil) {
    protocolType = @"epidemic";
  }
  //3.getting destPeerName
  //make sure selectedPeer is not nil
  if (!selectedPeer)
  {
    selectedPeer = @" ";
  }
  
  NSString *destPeerName = selectedPeer;
  //4.getting timeAndSender (* nsArray)
      //4.1 record current time
      //4.2 asscociated time with name of sender
  //Get current time
  NSString *currentTime = [formatter stringFromDate:[NSDate date]];
  //[0] 'currentTime' ; [1] 'displayName'
  [timeAndSender insertObject:[NSMutableArray arrayWithObjects:currentTime,[appDelegate.defaults objectForKey:@"displayName"],nil] atIndex:0];
  //get locations : longitude && latitude, meanwhile address
  NSString *longitude;
  NSString *latitude;
  if (locationsArry != nil)
  {
    longitude = [locationsArry[0] copy];
    latitude = [locationsArry[1] copy];
  }else{
    longitude = @"not found";
    latitude = @"not found";
  }
  //Create array for jumped hops
  [jumpedHops addObject:[appDelegate.defaults objectForKey:@"displayName"]];
  
  //Get text content which cannot be nil
  if (self.textInputView.text.length != 0)
  {
    messageContent = self.textInputView.text;
    //add all needed info into 'jsonArry'
    [jsonArry addObject:messageId];//[0] --> messageId
    [jsonArry addObject:protocolType];//[1] --> protocolType
    [jsonArry addObject:destPeerName];//[2] --> destPeerName
    [jsonArry addObject:messageContent];//[3] --> messageContent
    [jsonArry addObject:timeAndSender];//[4] --> timeAndSender(* NSArray)
    [jsonArry addObject:jumpedHops];//[5] --> jumpedHopsList
    [jsonArry addObject:longitude];//[6] --> longtitude
    [jsonArry addObject:latitude];//[7] --> latitude
    [jsonArry addObject:address];//[8] --> address
    
    //set jsonArry into dictionary with key "message"
    [jsonDic setObject:jsonArry forKey:@"message"];
    NSError *error = nil;
    //Transmit in JSON
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:kNilOptions error:&error];

    if (!self.sessionMngr.hasPeers) return;
    NSLog(@"hasPeers?");
    [self.sessionMngr sendMessage:jsonData toDestPeer:selectedPeer];
    UIAlertView *sendSuccess = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Message was forwarded successfully!" delegate:self cancelButtonTitle:@"Confirm" otherButtonTitles: nil];
    [sendSuccess show];
  }else
  {
    NSLog(@"Message Content cannot be nil");
  }
  
}

#pragma mark - UITextViewDelegate Methods
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
  NSLog(@"textViewShouldBeginEditing");
  return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
  NSLog(@"textViewDidBeginEditing");
  textView.backgroundColor = [UIColor greenColor];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView{
  NSLog(@"textViewShouldEndEditing");
  textView.backgroundColor = [UIColor lightGrayColor];
  return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView{
  NSLog(@"textViewDidEndEditing");
}

- (void)textViewDidChange:(UITextView *)textView{
  NSLog(@"textViewDidChange:");
}

- (void)textViewDidChangeSelection:(UITextView *)textView{
  NSLog(@"textViewDidChangeSelection:");
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
  NSCharacterSet *doneButtonCharacterSet = [NSCharacterSet newlineCharacterSet];
  NSRange replacementTextRange = [text rangeOfCharacterFromSet:doneButtonCharacterSet];
  NSUInteger location = replacementTextRange.location;
  
  if (textView.text.length + text.length > 140)
  {
    if (location != NSNotFound) {
      [textView resignFirstResponder];
    }
    return NO;
  }else if (location != NSNotFound){
    [textView resignFirstResponder];
    return NO;
  }
  return YES;
}

#pragma mark - UIPickerView Delegate methods
//Number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
  return 1;
}

//Number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
  if (protocolSelectedMark == NO)
  {
    return protocolTypes.count;
  }else
  {
    if (destPeers != nil)
    {
      return destPeers.count;
    }else{
      return 0;
    }
  }
}

// The data to return for the row and component (column) that's being passed in
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
  if (protocolSelectedMark == NO)
  {
    return protocolTypes[row];
  }else{
    if (destPeers.count > 0)
    {
      return destPeers[row];
    }else{
      return @"null";
    }
  }
}

//Capture the picker view selection
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
  if (protocolSelectedMark == NO)
  {
    if (row == 0) {
      selectedPeer = nil;
      [prototypePicker removeFromSuperview];
      [toolBar removeFromSuperview];
      protocolType = protocolTypes[0];
      NSLog(@"%@",protocolType);
    }else{
      protocolSelectedMark = YES;
      protocolType = protocolTypes[1];
      [prototypePicker reloadAllComponents];
    }
  }else{
    if (destPeers.count > 0) {
      selectedPeer = (NSString *)destPeers[row];
    }else{
      selectedPeer = nil;
    }
    
    protocolSelectedMark = NO;
    [prototypePicker removeFromSuperview];
    [toolBar removeFromSuperview];
  }
  
  NSLog(@"selectedPeer is %@",selectedPeer);
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
  NSLog(@"didFailWithError: %@", error);
  UIAlertView *errorAlert = [[UIAlertView alloc]
                             initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
  NSLog(@"didUpdateToLocation: %@", locations);
  CLLocation *currentLocation = locations[locations.count - 1];
  
  if (currentLocation != nil)
  {
    locationsArry = [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude],[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude], nil];
    NSLog(@"print locations : %@",locations);
  }

  /*
   check network connectivity
   if(network connected == YES)
   {
   get address from last location;
   }else{
   set address as 'not found';
   }
   */
  BOOL networkConnectivity = [networkCheckManager hasConnectivity];
  if (networkConnectivity && currentLocation != nil)
  {
    //retriving address based on last location information
    NSLog(@"retriving address");
    address = [addressManager retrieveAddress:currentLocation];
  }else{
    NSLog(@"cannot connect to network");
    address = @"not found";
  }

}


#pragma mark - 'viewDidLoad' methods
- (void)viewDidLoad {
  NSLog(@"viewDidLoad(Create Message View Controller)");
  [super viewDidLoad];
  [self.textInputView setDelegate:self];
  
  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
  
  NSLog(@"connected peers are %@",self.sessionMngr.session.connectedPeers);
  
  //init protocol types with two options 'epidemic' and 'route'
  protocolTypes = [[NSArray alloc] initWithObjects:@"epidemic",@"route" ,nil];
  // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
  //custom title
  UILabel *lblTitle = [[UILabel alloc] init];
  lblTitle.text = @"Create Message";
  lblTitle.backgroundColor = [UIColor clearColor];
  lblTitle.textColor = [UIColor whiteColor];
  lblTitle.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
  [lblTitle sizeToFit];
  self.navigationItem.titleView = lblTitle;

  protocolSelectedMark = NO;
  
  //init for updating locaiton
  locationMngr = nil;
  locationMngr = [[CLLocationManager alloc] init];
  geoCoder = [[CLGeocoder alloc] init];
  //availiable for IOS version 8.0 or later
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
    [locationMngr requestWhenInUseAuthorization];
  }
  
  locationMngr.delegate = self;
  locationMngr.desiredAccuracy = kCLLocationAccuracyBest;
  //start up updating locations via location manager
  [locationMngr startUpdatingLocation];
  //init address as "not found"
  address = @"not found";
  
  //Initialize data for destPeer pickerView
  //data for pickerView is based on 'contactList'
  NSMutableArray *store = [[NSMutableArray alloc] init];
  if (!appDelegate) {
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  }
  
  if (!dbManager) {
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
  }
  
  NSString *user_name = [appDelegate.defaults objectForKey:@"displayName"];
  //retrieve connected peers as array of destination peer from table 'profiles'
  if (dbManager)
  {
    NSString *queryConnectedPeers = [NSString stringWithFormat: @"select distinct profilename from profiles where receiver_name = '%@'",user_name];
    NSArray *connectedPeers = [[dbManager loadDataFromDB:queryConnectedPeers] mutableCopy];
    
    //store all names of connected peers into array store
    if (connectedPeers.count > 0)
    {
      for (int i=0; i<connectedPeers.count; i++)
      {
        [store addObject:connectedPeers[i][0]];
      }
    }
  }
  
  destPeers = [[NSArray alloc] initWithArray:store];
  selectedPeer = nil;
}

- (void)viewWillDisappear:(BOOL)animated{
  NSLog(@"viewWillDIsappear");
  //Stop updating locations when leave this page, for the purpose of saving battery
  [locationMngr stopUpdatingLocation];
  NSLog(@"stop updating locations");
  
  //clean locations for next time
  locationsArry = nil;
  
//  //implement createMessageDidFinish protocol
//  [self.delegate createMessageDidFinish:self];
  
}
@end
