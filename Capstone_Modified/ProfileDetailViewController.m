//
//  ProfileDetailViewController.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 1/27/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "ProfileDetailViewController.h"
#import "AppDelegate.h"
#import "DBManager.h"

@interface ProfileDetailViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UILabel *profileNameLabel;
@property (strong, nonatomic) IBOutlet UITableView *contactTableView;
@property (strong, nonatomic) NSMutableDictionary *retreivedContact;
@property (strong, nonatomic) NSArray *contactList;
@end

@implementation ProfileDetailViewController{
  AppDelegate *appDelegate;
  DBManager *dbManager;
  NSArray *connectedInfo;
}

- (void)viewDidLoad {
  NSLog(@"viewDidLoad");
  [super viewDidLoad];
  
  //custom title
  UILabel *lblTitle = [[UILabel alloc] init];
  lblTitle.text = [NSString stringWithFormat:@"%@",self.profileName];
  lblTitle.backgroundColor = [UIColor clearColor];
  lblTitle.textColor = [UIColor whiteColor];
  lblTitle.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
  [lblTitle sizeToFit];
  self.navigationItem.titleView = lblTitle;
  
  [self.navigationItem.leftBarButtonItem setTintColor:[UIColor whiteColor]];

  [self.contactTableView setDelegate:self];
  [self.contactTableView setDataSource:self];
  
  //Connect to local database
  //Retrive distinct profilenames
  if (!dbManager)
  {
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
    NSString *distinctQuery = [NSString stringWithFormat:@"select connectedname,connectedtime from profiles where profilename='%@' AND receiver_name = '%@'",self.profileName,self.receiver_name];
    connectedInfo = [[NSArray alloc] initWithArray:[dbManager loadDataFromDB:distinctQuery]];
  }
  
    // Do any additional setup after loading the view.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView Delegate Methods
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
  return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  return connectedInfo.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"profileContactList"];
  
  cell.textLabel.text = connectedInfo[indexPath.row][0];
  cell.detailTextLabel.text = connectedInfo[indexPath.row][1];
  
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
  return @"Contact List";
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section{
  //Set the text color for header text
  UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
  [header.textLabel setTextColor:[UIColor whiteColor]];
  header.textLabel.font = [UIFont fontWithName:@"ChalkboardSE-Bold" size:20.0];
  
  // Set the background color of our header/footer.
  header.contentView.backgroundColor = [UIColor lightGrayColor];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
