//
//  mapViewController.m
//  Capstone_Modified
//
//  Created by ZihaoLin on 3/1/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//
@import CoreLocation;
@import MapKit;

#import "mapViewController.h"
#import "DBManager.h"
#import "networkCheckManager.h"

@interface mapViewController ()<CLLocationManagerDelegate>{
  
  IBOutlet UISegmentedControl *mapTypeControl;
  IBOutlet UISwitch *showHereSwitch;
  IBOutlet UISwitch *show3DSwitch;
  UIView * controlView;
  IBOutlet UIToolbar *toolBar;
}
@property (strong,nonatomic) CLLocationManager * locationManager;
@property (strong,nonatomic) CLGeocoder * geocoder;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end

@implementation mapViewController{
  DBManager *dbManager;
  NSArray *loadedLocations;
}
#pragma mark CLLocationManagerDelegate protocol methods

- (void) locationManager: (CLLocationManager *) manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  NSLog(@"didChangeStatus %d",status);
  //if (status == kCLAuthorizationStatusAuthorizedWhenInUse) [manager startUpdatingLocation];
  if (status == kCLAuthorizationStatusAuthorizedWhenInUse) [self makeMapTrackUser];
}

//- (void) locationManager: (CLLocationManager *) manager didUpdateLocations:(NSArray *)locations {
//  NSLog(@"didUpdateLocations %d",(int)locations.count);
//  CLLocation * location = locations.lastObject;
//  NSLog(@"location %@",[location description]);
//
//}
//
//- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
//  NSLog(@"didFailWithError");
//}
#pragma mark MKMapViewDelegate Protocol methods

- (MKAnnotationView *) mapView: (MKMapView *) mapView viewForAnnotation:(id<MKAnnotation>)annotation {
  NSLog(@"viewForAnnotation");
  if ([annotation isKindOfClass: [MKUserLocation class]]) return nil;
  MKPinAnnotationView * pinView = (MKPinAnnotationView * )[self.mapView dequeueReusableAnnotationViewWithIdentifier: @"pin"];
  if (!pinView) {
    pinView = [[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"pin"];
    pinView.canShowCallout = YES;
    pinView.draggable = YES;
    pinView.animatesDrop = YES;
    pinView.enabled = YES;
  }
  pinView.pinColor = MKPinAnnotationColorPurple;
  return pinView;
}

- (void) mapView: (MKMapView *) mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
  NSLog(@"didChangeDragState old %d new %d",(int)oldState,(int)newState);
  if (![view.annotation isKindOfClass: [MKPointAnnotation class]]) return;
  MKPointAnnotation * annotation = view.annotation;
  switch (newState) {
    case MKAnnotationViewDragStateNone:
      break;
    case MKAnnotationViewDragStateStarting:
      annotation.title = @"dragging";
      break;
    case MKAnnotationViewDragStateDragging:
      break;
    case MKAnnotationViewDragStateCanceling:
      break;
    case MKAnnotationViewDragStateEnding:
      [self titleAnnotation: annotation usingCoordinate: annotation.coordinate];
      break;
  }
}

- (void) setAnnotationView: (MKAnnotationView *) view pinColor: (MKPinAnnotationColor) color {
  if (view && [view respondsToSelector: @selector(pinColor)]) ((MKPinAnnotationView *)view).pinColor = color;
}

- (void) mapView: (MKMapView *) mapView didSelectAnnotationView:(MKAnnotationView *)view {
  NSLog(@"didSelectAnnotationView");
  [self setAnnotationView: view pinColor: MKPinAnnotationColorPurple];
//  routeSrc = routeDst;
//  [self setAnnotationView: routeSrc pinColor: MKPinAnnotationColorGreen];
//  routeDst = view;
//  [self setAnnotationView: routeDst pinColor: MKPinAnnotationColorRed];
}

- (void) mapView: (MKMapView *) mapView didDeselectAnnotationView:(MKAnnotationView *)view {
  NSLog(@"didDeselectAnnotationView");
}

#pragma mark LongPressGestureRecognizer methods

//- (IBAction) handleLongPress: (UILongPressGestureRecognizer *) gesture {
//  //  NSLog(@"handleLongPress state %d",(int)gesture.state);
//  if (gesture.state != UIGestureRecognizerStateEnded) return;
//  MKPointAnnotation * annotation = [[MKPointAnnotation alloc] init];
//  annotation.title = @"waiting";
//  CGPoint pt = [gesture locationInView: self.mapView];
//  CLLocationCoordinate2D coord = [self.mapView convertPoint: pt toCoordinateFromView: self.mapView];
//  annotation.coordinate = coord;
//  [self.mapView addAnnotation: annotation];
//  [self titleAnnotation: annotation usingCoordinate: coord];
//}

- (IBAction)showReceivedMessagesPins:(UIButton *)sender {
  //load top 7 received messages whose 'longitude' && 'latitude' columns are not @"not found"
  NSString *queryMessages = @"select longitude,latitude from receivedmessage where longitude not like '%not found%' limit 7";
  loadedLocations = [[dbManager loadDataFromDB:queryMessages] copy];
  NSLog(@"print loadedLocations : %@",loadedLocations);
  
  //add pins on mapView
  int pinCounter = 0;
  while (pinCounter < loadedLocations.count)
  {
    //a life-cycle for adding a pin on mapView
    MKPointAnnotation * annotation = [[MKPointAnnotation alloc] init];
    annotation.title = @"waiting";
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([[loadedLocations[pinCounter][1] copy] doubleValue], ([[loadedLocations[pinCounter][0] copy] doubleValue]));
    annotation.coordinate = coord;
    [self.mapView addAnnotation: annotation];
    [self titleAnnotation: annotation usingCoordinate: coord];
    pinCounter++;
  }
  
}

- (IBAction)showSendMessagesPins:(UIButton *)sender {
  //load top 7 received messages whose 'longitude' && 'latitude' columns are not @"not found"
  NSString *queryMessages = @"select longitude,latitude from sendMessage where longitude not like '%not found%' limit 7";
  loadedLocations = [[dbManager loadDataFromDB:queryMessages] copy];
  NSLog(@"print loadedLocations : %@",loadedLocations);
  
  //add pins on mapView
  int pinCounter = 0;
  while (pinCounter < loadedLocations.count)
  {
    //a life-cycle for adding a pin on mapView
    MKPointAnnotation * annotation = [[MKPointAnnotation alloc] init];
    annotation.title = @"waiting";
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([[loadedLocations[pinCounter][1] copy] doubleValue], ([[loadedLocations[pinCounter][0] copy] doubleValue]));
    annotation.coordinate = coord;
    [self.mapView addAnnotation: annotation];
    [self titleAnnotation: annotation usingCoordinate: coord];
    pinCounter++;
  }
}


- (void) titleAnnotation: (MKPointAnnotation *) annotation usingCoordinate: (CLLocationCoordinate2D) coord {
  CLLocation * location = [[CLLocation alloc] initWithLatitude: coord.latitude longitude: coord.longitude];
  [self.geocoder reverseGeocodeLocation: location completionHandler:
   ^(NSArray * placemarks, NSError * error) {
     annotation.title = (error) ? (@"error") : ([self stringFromPlacemarks: placemarks]);
   } ];
}

- (NSString *) stringFromPlacemarks: (NSArray *) placemarks {
  if (placemarks.count == 0) return @"somewhere";
  //    for (CLPlacemark * placemark in placemarks) {
  //      NSLog(@"placemark %@",[placemark description]);
  //    }
  CLPlacemark * placemark = placemarks[0];
  return placemark.name;
}

#pragma mark Control Drawer methods

- (IBAction) showControls {
  //if has no network connectivity, control view will not be displayed
  BOOL networkCheck = [networkCheckManager hasConnectivity];
  if (networkCheck == NO) return;
  
  if (!controlView) {
    NSArray * views = [[NSBundle mainBundle] loadNibNamed: @"ControlView" owner: self options: nil];
    controlView = views[0];
    CGRect viewBds = controlView.bounds;
    CGRect screenBds = [UIScreen mainScreen].bounds;
    controlView.frame = CGRectMake(screenBds.origin.x,screenBds.origin.y+screenBds.size.height-self.tabBarController.tabBar.frame.size.height,screenBds.size.width,viewBds.size.height);
    [self.view addSubview: controlView];
  }
  
  mapTypeControl.selectedSegmentIndex = self.mapView.mapType;
  show3DSwitch.on = (self.mapView.camera && self.mapView.camera.pitch != 0.0) ? (YES) : (NO);
  showHereSwitch.on = self.mapView.showsUserLocation;
  
  [UIView animateWithDuration: 0.2 animations: ^(void){controlView.frame = CGRectOffset(controlView.frame,0,-controlView.frame.size.height); } ];
}

- (IBAction) hideControls {
  [UIView animateWithDuration: 0.2 animations: ^(void){controlView.frame = CGRectOffset(controlView.frame,0,controlView.frame.size.height); } ];
}

#pragma mark Control action methods

- (IBAction) setMapType: (UISegmentedControl *) sender {
  self.mapView.mapType = sender.selectedSegmentIndex;
}

- (IBAction) set3DMode: (UISwitch *) sender {
  if (sender.on) {
    MKMapCamera * camera = [self.mapView.camera copy];
    camera.pitch = 45;
    [self.mapView setCamera: camera animated: YES];
  }
  else {
    MKMapCamera * camera = [self.mapView.camera copy];
    camera.pitch = 0;
    [self.mapView setCamera: camera animated: YES];
  }
}

- (IBAction) setShowHereMode: (UISwitch *) sender {
  self.mapView.showsUserLocation = sender.on;
}

- (MKMapItem *) mapItemForAnnotationView: (MKAnnotationView *) annotationView {
  CLLocationCoordinate2D coord = annotationView.annotation.coordinate;
  MKPlacemark * placemark = [[MKPlacemark alloc] initWithCoordinate: coord addressDictionary: nil];
  MKMapItem * mapItem = [[MKMapItem alloc] initWithPlacemark: placemark];
  return mapItem;
}

- (MKOverlayRenderer *) mapView: (MKMapView *) mapView rendererForOverlay:(id<MKOverlay>)overlay {
  MKPolylineRenderer * renderer = [[MKPolylineRenderer alloc] initWithOverlay: overlay];
  renderer.strokeColor = [UIColor blueColor];
  renderer.lineWidth = 6.0;
  return renderer;
}

#pragma mark ViewController methods

- (void) makeMapTrackUser {
  self.mapView.showsUserLocation = YES;
  [self.mapView setUserTrackingMode: MKUserTrackingModeFollow animated: YES];
}

- (void) requestAuthorization {
  CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
  if (!self.locationManager) self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;
  if (status == kCLAuthorizationStatusNotDetermined) [self.locationManager requestWhenInUseAuthorization];
  if (status == kCLAuthorizationStatusAuthorizedWhenInUse) [self makeMapTrackUser];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  BOOL networkConnectivityCheck = [networkCheckManager hasConnectivity];
  if (networkConnectivityCheck == NO){
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Please check network connectivity " delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
    [alertView show];
  }
  
  MKUserTrackingBarButtonItem * trackButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView: self.mapView];
  NSMutableArray * items = [[NSMutableArray alloc] initWithArray: toolBar.items];
  [items insertObject: trackButton atIndex: 0];
  toolBar.items = items;
  
  [self requestAuthorization];
  
  self.mapView.mapType = MKMapTypeStandard;
  
  self.geocoder = [[CLGeocoder alloc] init];
  
  //init dbManager
  if (!dbManager)
  {
    dbManager = [[DBManager alloc] initWithDatabaseFilename:@"profileList.sql"];
  }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
