//
//  ContactsTableViewController.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/16/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "ProfileDetailViewController.h"
#import "AppDelegate.h"
#import "DBManager.h"

@interface ContactsTableViewController ()
@end

@implementation ContactsTableViewController{
  AppDelegate *appDelegate;
  DBManager *dbManager;
  NSArray *profileNames;
}
#pragma mark - Private methods
- (void) reloadTableView{
  [self.tableView reloadData];
}

#pragma mark - 'viewDidLoad' Methods
- (void)viewDidLoad {
  NSLog(@"viewDidLoad (ContactsViewController)");
  [super viewDidLoad];
  //Make sure that 'appDelegate' will exist whenever jumped into this view controller
  //custom title
  UILabel *lblTitle = [[UILabel alloc] init];
  lblTitle.text = @"Contacts";
  lblTitle.backgroundColor = [UIColor clearColor];
  lblTitle.textColor = [UIColor whiteColor];
  lblTitle.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
  [lblTitle sizeToFit];
  self.navigationItem.titleView = lblTitle;
  
  if (!appDelegate) {
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  }
  
  //get user name
  NSString *user_name = [appDelegate.defaults objectForKey:@"displayName"];
  //Connect to local database
  //Retrive distinct profilenames
  if (!dbManager)
  {
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
    NSString *distinctQuery = [NSString stringWithFormat:@"select distinct profilename from profiles where receiver_name = '%@'",user_name];
    profileNames = [[NSArray alloc] initWithArray:[[dbManager loadDataFromDB:distinctQuery] mutableCopy]];
    NSLog(@"%@",distinctQuery);
  }else
  {
    NSString *distinctQuery = [NSString stringWithFormat:@"select distinct profilename from profiles where receiver_name = '%@'",user_name];
    profileNames = [[NSArray alloc] initWithArray:[[dbManager loadDataFromDB:distinctQuery] mutableCopy]];
    NSLog(@"%@",distinctQuery);
  }

  //Set up delegate && datasource as 'self' for tableView
  [self.tableView setDelegate:self];
  [self.tableView setDataSource:self];
  
  //Set up a nsTimer to refresh tableView
  //Time Interval is '0.5'
  NSTimer *timer = [NSTimer timerWithTimeInterval:0.5 target:self  selector:@selector(reloadTableView) userInfo:nil repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
  
  NSLog(@"viewDidLoad finish");
}

- (void)viewWillAppear:(BOOL)animated{
  NSLog(@"viewWillAppear");
  //Refresh contact table
  //select distinct profilename from profiles
  if (!appDelegate) {
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  }
  
  NSString *receiver_name = [appDelegate.defaults objectForKey:@"displayName"];
  if (!dbManager)
  {
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
    NSString *distinctQuery = [NSString stringWithFormat:@"select distinct profilename from profiles where receiver_name = '%@'",receiver_name];
    profileNames = [[NSArray alloc] initWithArray:[[dbManager loadDataFromDB:distinctQuery] mutableCopy]];
    NSLog(@"%@",distinctQuery);
  }else
  {
    NSString *distinctQuery = [NSString stringWithFormat:@"select distinct profilename from profiles where receiver_name = '%@'",receiver_name];
    profileNames = [[NSArray alloc] initWithArray:[[dbManager loadDataFromDB:distinctQuery] mutableCopy]];
    NSLog(@"%@",distinctQuery);
  }
  
  [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
  NSInteger numberOfRows = profileNames.count;
  return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactsCell"];
  NSString *cellContent = [profileNames objectAtIndex:indexPath.row][0];
  
  cell.textLabel.text = [NSString stringWithFormat:@"%@",cellContent];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
  NSLog(@"prepareForSegue");
  if (![segue.identifier isEqualToString:@"showProfile"]) return;
  
  NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
  NSString *profileName = [self.tableView cellForRowAtIndexPath:selectedRow].textLabel.text;
  NSString *receiver_name = [appDelegate.defaults objectForKey:@"displayName"];
  if (profileName != nil) {
    [[segue destinationViewController] setProfileName:profileName];
    [[segue destinationViewController] setReceiver_name:receiver_name];
  }
}

@end
