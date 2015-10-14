#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolBox.h>
#import <MapKit/MapKit.h>
#import "SettingsController.h"
#import "ResultsController.h"

@interface ViewController () <CLLocationManagerDelegate, SettingsControllerDelegate, ResultsControllerDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *latitude;
@property (weak, nonatomic) IBOutlet UILabel *longitude;
@property (weak, nonatomic) IBOutlet UILabel *address;
@property (weak, nonatomic) IBOutlet UILabel *speed;
@property (strong, nonatomic) IBOutlet UILabel *delta;
@property (strong, nonatomic) IBOutlet UILabel *option;

//@property (strong, nonatomic) IBOutlet MKMapView *map;

@property (strong, nonatomic) IBOutlet UISegmentedControl *startStop;
@property (strong, nonatomic) IBOutlet UILabel *battery;

@property (strong, nonatomic) IBOutlet UILabel *destinationLocation;
@property (strong, nonatomic) IBOutlet UILabel *readOut;
@property (strong, nonatomic) IBOutlet UILabel *manualMessage;

@property (strong, nonatomic) IBOutlet UIButton *confirmGeoUI;
@property (strong, nonatomic) IBOutlet UIButton *endSession;

- (IBAction)startStop:(id)sender;
- (IBAction)confirmGeo:(id)sender;
- (IBAction)gotoResults:(id)sender;

@property (strong, nonatomic) IBOutlet UIButton *confirmGeofence;




@end

@implementation ViewController{
    
    //CL Declarations
    CLLocationManager *manager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    CLLocation *destinationPlot;
    CLLocationDistance distance;
    
    //Region Monitoring
    NSArray *_regionArray;
    NSArray *geofences;
    
    //Maps
    MKCircle *circle;
    MKPointAnnotation *annotation;
    CLLocationCoordinate2D destinationCoordinate;

    //Alerts
    UIAlertView *gpsHelloAlert;
    UIAlertView *geofenceHelloAlert;
    UIAlertView *geofenceHelloCAlert;
    UIAlertView *goodbyeAlert;
    UIAlertView *gotoSettingsAlert;
    UIAlertView *gpsPingAlert;
    UIAlertView *manualConfimationAlert;
    UIAlertView *endingAlert;
    UIAlertView *endSessionAlert;
    
    //Data Points
    NSDictionary *currentDestination;
    NSDictionary *startLocation;
    NSMutableDictionary *sessionTime;
    NSString *currentOption;

    //Radii Data Points
    NSMutableDictionary *autoTimeStamps;
    NSMutableDictionary *manualTimeStamps;
    int batteryStart;
    int batteryEnd;

    //Misc.
    NSNumberFormatter *f;
    int pingCount;
    bool entered;
    bool inSession;
    int manualCount;
    int autoCount;
    bool bInitLocation;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Current Session";
    self.startStop.selectedSegmentIndex = 1;
    
    manager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    entered = false;
    
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
    if([currentDestination count] < 1){
        self.confirmGeoUI.hidden = true;
        self.endSession.hidden = true;
        self.manualMessage.hidden = true;
        
    }else{
        self.endSession.hidden = false;
        self.confirmGeoUI.hidden = false;
        self.manualMessage.hidden = false;
    }
    
    currentOption = @"";
    inSession = false;
    
    autoTimeStamps = [[NSMutableDictionary alloc] init];
    manualTimeStamps = [[NSMutableDictionary alloc] init];
    sessionTime = [[NSMutableDictionary alloc] init];
    
    manualCount = 0;
    autoCount = 0;
    
    self.readOut.text = @"To begin, go to settings and set parameters.";

    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://45.55.238.244/int-data/"]];
    
    /*UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    localNotification.alertBody = @"hi";
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];*/
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    if (localNotification) {
        application.applicationIconBadgeNumber = 0;
    }
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
    
    application.applicationIconBadgeNumber = 0;
}

//Alerts /////////////////////////////////////////////////////////

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView == gotoSettingsAlert){
        [self performSegueWithIdentifier:@"toSettings" sender:self];
    }
    
    if(alertView == manualConfimationAlert){
        if (buttonIndex == 0) {
            [manualTimeStamps setObject:[self dateAndTime] forKey: [@"manualConfirmation-" stringByAppendingString:[@(manualCount) stringValue]]];
            manualCount++;
            
            endingAlert = [[UIAlertView alloc] initWithTitle:@"End Session?"
                                                     message:@"Ending session will sent you to results."
                                                    delegate:self
                                           cancelButtonTitle:@"Yes"
                                           otherButtonTitles:@"No", nil];
            [endingAlert show];
            self.readOut.text = [self dateAndTime];
        }
    }
    
    if(alertView == endingAlert){
        if (buttonIndex == 0) {
            [self endingSession];
        }
    }
    
    if(alertView == gpsHelloAlert){
        if (buttonIndex == 0) {
            [manualTimeStamps setObject:[self dateAndTime] forKey: [@"manualGPS-" stringByAppendingString:[@(manualCount) stringValue]]];
            manualCount++;
            
            endingAlert = [[UIAlertView alloc] initWithTitle:@"End Session?"
                                                     message:@"Ending session will sent you to results."
                                                    delegate:self
                                           cancelButtonTitle:@"Yes"
                                           otherButtonTitles:@"No", nil];
            [endingAlert show];
        }
    }
    
    if(alertView == geofenceHelloAlert){
        if (buttonIndex == 0) {
            [manualTimeStamps setObject:[self dateAndTime] forKey: [@"manualGeofence-" stringByAppendingString:[@(manualCount) stringValue]]];
            manualCount++;
            
            endingAlert = [[UIAlertView alloc] initWithTitle:@"End Session?"
                                                     message:@"Ending session will sent you to results."
                                                    delegate:self
                                           cancelButtonTitle:@"Yes"
                                           otherButtonTitles:@"No", nil];
            [endingAlert show];
        }
    }
    
    if(alertView == geofenceHelloCAlert){
        if (buttonIndex == 0) {
            [manualTimeStamps setObject:[self dateAndTime] forKey: [@"manualGeofence-" stringByAppendingString:[@(manualCount) stringValue]]];
            manualCount++;
            
            endingAlert = [[UIAlertView alloc] initWithTitle:@"End Session?"
                                                     message:@"Ending session will sent you to results."
                                                    delegate:self
                                           cancelButtonTitle:@"Yes"
                                           otherButtonTitles:@"No", nil];
            [endingAlert show];
        }
    }
    
    if(alertView == gpsPingAlert){
        //if false
        if (buttonIndex == 1) {
            geofences = [self buildGeofenceData];
            [self initializeRegionMonitoring:geofences];
            [manager stopUpdatingLocation];
            //[self initializeMap];
        }else{
            [manualTimeStamps setObject:[self dateAndTime] forKey: [@"manualPingGPS-" stringByAppendingString:[@(manualCount) stringValue]]];
            manualCount++;
            
            endingAlert = [[UIAlertView alloc] initWithTitle:@"End Session?"
                                                     message:@"Ending session will sent you to results."
                                                    delegate:self
                                           cancelButtonTitle:@"Yes"
                                           otherButtonTitles:@"No", nil];
            [endingAlert show];
        }
    }
}
//end/////////////////////////////////////////////////////////

//Segue data sharing/////////////////////////////////////////////////////////
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    SettingsController *transferSettingsController = segue.destinationViewController;
    if ([[segue identifier] isEqualToString:@"toSettings"]){
        transferSettingsController.option = self.option.text;
        transferSettingsController.currentDestination = currentDestination;
        transferSettingsController.delegate = self;
    }
    
    ResultsController *transferResultsController = segue.destinationViewController;
    if ([[segue identifier] isEqualToString:@"toResults"]){
        transferResultsController.autoTimeStamp = autoTimeStamps;
        transferResultsController.manualTimeStamp = manualTimeStamps;
        transferResultsController.startLocation = startLocation;
        transferResultsController.sessionTime = sessionTime;
        transferResultsController.option = self.option.text;
        transferResultsController.location = currentDestination;
        transferResultsController.batteryUsed = [@(batteryStart - batteryEnd) stringValue];
        transferResultsController.delegate = self;
    }
}
//end/////////////////////////////////////////////////////////

//Set destination parameters from settings/////////////////////////////////////////////////////////
- (void)dataFromChoice:(NSString *)data{
    //NSLog(data);
    //NSLog(currentOption);
   
    if(![data isEqualToString:currentOption]){
        [self stopData];
        //NSLog(@"It stopped");
    }
    
    currentOption = data;
    self.option.text = data;
    self.readOut.text = @"Press start to begin session.";
}

- (void)dataFromDestination:(NSDictionary *)data{
    if( data != NULL ){
        if(![data[@"title"] isEqualToString:currentDestination[@"title"]]){
            [self stopData];
            [self resetCoordinates: data];
        }
        
        if(![data[@"radius"] isEqualToString:currentDestination[@"radius"]]){
            [self stopData];
            [self resetCoordinates: data];
        }
    }
}

-(void) resetCoordinates:(NSDictionary *)data{
    currentDestination = data;
    self.destinationLocation.text = data[@"title"];
    destinationPlot = [[CLLocation alloc] initWithLatitude:[data[@"latitude"] doubleValue] longitude:[data[@"longitude"] doubleValue]];

    //[self.map removeAnnotations: self.map.annotations];
    //destinationCoordinate.latitude = [data[@"latitude"] doubleValue];
    //destinationCoordinate.longitude = [data[@"longitude"] doubleValue];
}

//end/////////////////////////////////////////////////////////

//Start and stop corelocation services/////////////////////////////////////////////////////////
- (void)startData{
    
    
    @try{
        if ([self.option.text isEqualToString:@""]){
            gotoSettingsAlert = [[UIAlertView alloc] initWithTitle:@"Please Enter Your Settings"
                                                           message:@"You are being sent to the settings screen."
                                                          delegate:self
                                                 cancelButtonTitle:@"Okay"
                                                 otherButtonTitles:nil];
            
            [gotoSettingsAlert show]; 
            self.startStop.selectedSegmentIndex = 1;
        }else{
            
            if([currentOption isEqualToString:@"A"]) {
                [self runOptionA];
            }
            else if([currentOption isEqualToString:@"B"]) {
                [self runOptionB];
                bInitLocation = false;
            }
            else if([currentOption isEqualToString:@"C"]) {
                [self runOptionC];
            }
            else if([currentOption isEqualToString:@"D"]) {
                [self runOptionD];
            }
            else if([currentOption isEqualToString:@"E"]) {
                [self runOptionE];
            }
            else if([currentOption isEqualToString:@"F"]) {
                [self runOptionF];
            }
            
            self.confirmGeoUI.hidden = false;
            self.endSession.hidden = true;
            self.manualMessage.hidden = false;
            self.readOut.text = @"In Session";
            batteryStart = [[UIDevice currentDevice] batteryLevel] * 100;
            [sessionTime setObject:[self dateAndTime] forKey: @"startSession"];
            
            inSession = true;
            entered = false;
            
            [autoTimeStamps removeAllObjects];
            [manualTimeStamps removeAllObjects];
        }
    }@catch(NSException *exception){
        gotoSettingsAlert = [[UIAlertView alloc] initWithTitle:@"Please Enter Your Settings"
                                                       message:@"You are being sent to the settings screen."
                                                      delegate:self
                                             cancelButtonTitle:@"Okay"
                                             otherButtonTitles:nil];
        
        [gotoSettingsAlert show];
    }
}

- (void)stopData{
    [manager stopUpdatingLocation];
    
    for(CLRegion *geofence in geofences) {
        [manager stopMonitoringForRegion:geofence];
    }
    self.startStop.selectedSegmentIndex = 1;
    //[self.map removeOverlay:circle];
    pingCount = 0;
    [sessionTime setObject:[self dateAndTime] forKey: @"stopSession"];
}

- (IBAction)startStop:(id)sender {
    switch (self.startStop.selectedSegmentIndex){
        case 1:
            //NSLog(@"Off");
            
            endingAlert = [[UIAlertView alloc] initWithTitle:@"End Session?"
                                                     message:@"Ending session will sent you to results."
                                                    delegate:self
                                           cancelButtonTitle:@"Yes"
                                           otherButtonTitles:@"No", nil];
            [endingAlert show];
            break;
        case 0:
            //NSLog(@"On");
            [self startData];
            break;
        default:
            break;
    }
}

- (IBAction)confirmGeo:(id)sender {
    manualConfimationAlert = [[UIAlertView alloc] initWithTitle:@"Manual Boundary Crossing Alert"
                                                        message:@"This a manual geofence confirmation."
                                                       delegate:self
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:@"Cancel", nil];
    [manualConfimationAlert show];
}

- (IBAction)gotoResults:(id)sender {
    if(inSession){
        endSessionAlert = [[UIAlertView alloc] initWithTitle:@"Your are in a session"
                                                     message:@"Press stop to end the session and see results."
                                                    delegate:self
                                           cancelButtonTitle:@"Okay"
                                           otherButtonTitles:nil];
        [endSessionAlert show];
    }else{
        [self performSegueWithIdentifier: @"toResults" sender: self];
    }
}

-(void) endingSession{

    [self stopData];
    inSession = false;
    manualCount = 0;
    autoCount = 0;
    batteryEnd = [[UIDevice currentDevice] batteryLevel] * 100;
    
    self.endSession.hidden = false;
    self.confirmGeoUI.hidden = true;
    self.manualMessage.hidden = true;
    self.readOut.text = @"";

    //[autoTimeStamps removeAllObjects];
    //[manualTimeStamps removeAllObjects];
    [self performSegueWithIdentifier: @"toResults" sender: self];
}

//end////////////////////////////////////////////////////////

//Map and region monitor setting/////////////////////////////////////////////////////////
/*- (void)initializeMap {
    self.map.centerCoordinate = destinationCoordinate;
    [self.map setRegion:MKCoordinateRegionMakeWithDistance(destinationCoordinate, 800, 800) animated:YES];
    [self.map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    self.map.delegate = self;
    
    annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:destinationCoordinate];
    [annotation setTitle:currentDestination[@"title"]];
    [self.map addAnnotation:annotation];
    
    circle = [MKCircle circleWithCenterCoordinate:destinationCoordinate radius:[currentDestination[@"radius"] floatValue]];
    [self.map addOverlay:circle];
}

- (MKOverlayView *)mapView:(MKMapView *)map viewForOverlay:(id<MKOverlay>)overlay{
    
    //NSLog(@"Drawing circle");
    
    MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    [circleView setStrokeColor:[UIColor blackColor]];
    return circleView;
}*/
//end////////////////////////////////////////////////////////

//Building geofences/////////////////////////////////////////////////////////
- (NSArray*) buildGeofenceData {
 
    NSMutableArray *geofences = [NSMutableArray array];
    
    if([currentOption isEqualToString:@"C"]){
        NSDictionary *earlyCourse = @{@"latitude":currentDestination[@"latitude"], @"longitude":currentDestination[@"longitude"], @"radius":@"600", @"title":currentDestination[@"title"]};
        CLRegion *earlyCourseRegion = [self mapDictionaryToRegion:earlyCourse];
        [geofences addObject:earlyCourseRegion];
        
        NSDictionary *midCourse = @{@"latitude":currentDestination[@"latitude"], @"longitude":currentDestination[@"longitude"], @"radius":@"800", @"title":currentDestination[@"title"]};
        CLRegion *midCourseRegion = [self mapDictionaryToRegion:midCourse];
        [geofences addObject:midCourseRegion];
        
        NSDictionary *lateCourse = @{@"latitude":currentDestination[@"latitude"], @"longitude":currentDestination[@"longitude"], @"radius":@"1000", @"title":currentDestination[@"title"]};
        CLRegion *lateCourseRegion = [self mapDictionaryToRegion:lateCourse];
        [geofences addObject:lateCourseRegion];
    }else{
        CLRegion *region = [self mapDictionaryToRegion:currentDestination];
        [geofences addObject:region];
    }
    
    return [NSArray arrayWithArray:geofences];
}

- (CLRegion*)mapDictionaryToRegion:(NSDictionary*)dictionary {
    NSString *title = [dictionary valueForKey:@"title"];
    
    CLLocationDegrees latitude = [[dictionary valueForKey:@"latitude"] doubleValue];
    CLLocationDegrees longitude =[[dictionary valueForKey:@"longitude"] doubleValue];
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    CLLocationDistance regionRadius = [[dictionary valueForKey:@"radius"] doubleValue];
    
    return [[CLRegion alloc] initCircularRegionWithCenter:centerCoordinate
                                                   radius:regionRadius
                                               identifier:title];
}

- (void) initializeRegionMonitoring:(NSArray*)geofences {
    for(CLRegion *geofence in geofences) {
        [manager startMonitoringForRegion:geofence];
    }
}
//end////////////////////////////////////////////////////////

//Battery////////////////////////////////////////////////////////
/*- (void)batteryStatus{
    NSArray *batteryStatus = [NSArray arrayWithObjects:
                              @"Battery status is unknown.",
                              @"Battery is in use (discharging).",
                              @"Battery is charging.",
                              @"Battery is fully charged.", nil];
    
    if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateUnknown){
        //NSLog(@"%@", [batteryStatus objectAtIndex:0]);
    }
    else{
        NSString *msg = [NSString stringWithFormat:@"%0.2f%%\n%@", [[UIDevice currentDevice] batteryLevel] * 100];
        //NSLog(@"%@", msg);
        
        self.battery.text = msg;
        battery = msg;
    }
}*/
//end/////////////////////////////////////////////////////////


//Options to run/////////////////////////////////////////////////////////
-(void)runOptionA{
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBest;
 
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    pingCount = 0;
    
    self.startStop.selectedSegmentIndex = 0;
    //[self initializeMap];
    //NSLog(@"A");
}

-(void)runOptionB{
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    pingCount = 0;
    
    self.startStop.selectedSegmentIndex = 0;
    //[self initializeMap];
    //NSLog(@"B");
}

//OLD C - sigificant change not being used
/*-(void)runOptionC{
    geofences = [self buildGeofenceData];
    [self initializeRegionMonitoring:geofences];
    
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startMonitoringSignificantLocationChanges];
    
    //[self initializeMap];
    self.startStop.selectedSegmentIndex = 0;
    
    //NSLog(@"C");
}*/
//////////////////////////////////////////////////////

-(void)runOptionC{
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    pingCount = 0;
    
    self.startStop.selectedSegmentIndex = 0;
    //[self initializeMap];
    //NSLog(@"C");
}

-(void)runOptionD{
    //geofences = [self buildGeofenceData];
    //[self initializeRegionMonitoring:geofences];
    
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    //[self initializeMap];
    self.startStop.selectedSegmentIndex = 0;
    
    //NSLog(@"D");
}

-(void)runOptionE{
    //geofences = [self buildGeofenceData];
    //[self initializeRegionMonitoring:geofences];
    
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    //[self initializeMap];
    self.startStop.selectedSegmentIndex = 0;
    
    //NSLog(@"E");
}


-(void)runOptionF{
    //geofences = [self buildGeofenceData];
    //[self initializeRegionMonitoring:geofences];
    
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    //[self initializeMap];
    self.startStop.selectedSegmentIndex = 0;
    
    //NSLog(@"F");
}

//end/////////////////////////////////////////////////////////

//Geofenceing region monitoring/////////////////////////////////////////////////////////
#pragma mark - Location Manager - Region Task Methods

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if([currentOption isEqualToString:@"A"]){
        [geofenceHelloAlert show];
        
        [autoTimeStamps setObject:[self dateAndTime] forKey: [@"autoGeofence-" stringByAppendingString:[@(autoCount) stringValue]]];
        autoCount++;
    }

    if([currentOption isEqualToString:@"B"]){
        [geofenceHelloAlert show];
        
        [autoTimeStamps setObject:[self dateAndTime] forKey: [@"autoGeofence-" stringByAppendingString:[@(autoCount) stringValue]]];
        autoCount++;
        
        [manager startUpdatingLocation];
        pingCount = 0;
    }
    
    if([currentOption isEqualToString:@"C"]){
        geofenceHelloCAlert = [[UIAlertView alloc] initWithTitle:@"Auto Geofence Crossing Alert - Arrival"
                                                         message:@"Are you at McDonald's?"
                                                        delegate:self
                                               cancelButtonTitle:@"Yes"
                                               otherButtonTitles:@"No,", nil];
        
        [geofenceHelloCAlert show];
        
        [autoTimeStamps setObject:[self dateAndTime] forKey: [@"autoGeofence-" stringByAppendingString:[@(autoCount) stringValue]]];
        autoCount++;
        
        [manager startUpdatingLocation];
        pingCount = 0;
    }
    
    [self ping];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    goodbyeAlert = [[UIAlertView alloc] initWithTitle:@"Auto Geofence Boundary Crossing Alert - Leaving"
                                              message:@"Have the best day."
                                             delegate:self
                                    cancelButtonTitle:@"See ya"
                                    otherButtonTitles:nil];
    [goodbyeAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Started monitoring %@ region", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    NSLog(@"didDetermineState");
    
    if (state == CLRegionStateInside) {
        NSLog(@"inside");
        return;
    } else if (state == CLRegionStateOutside) {
        NSLog(@"outside");
    } else {
        NSLog(@"unknown");
    }
}
//end/////////////////////////////////////////////////////////

//GPS/////////////////////////////////////////////////////////
#pragma mark CLLocationManagerDelegate Methods

- (void)locationManager: (nonnull CLLocationManager *)manager didFailWithError: (nonnull NSError *)error {
    NSLog(@"Error: %@", error);
    NSLog(@"Failed to get location :-(");
}

- (void)locationManager: (nonnull CLLocationManager *)manager didUpdateToLocation: (CLLocation *)newLocation fromLocation: (CLLocation *)oldLocation{

    //NSLog(@"Location %@", newLocation);
    CLLocation *currentLocation = newLocation;
    
    distance = [currentLocation distanceFromLocation:destinationPlot];
    //NSLog(@"Space %f", [currentLocation distanceFromLocation:destinationPlot]);
    //NSLog(@"distance %f m", distance);
    
    if(currentLocation != nil){
        self.latitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        self.longitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        self.speed.text = [NSString stringWithFormat:@"%.8f", newLocation.speed];
        self.delta.text = [NSString stringWithFormat:@"%.3f meters", distance];
    }
    
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error){
        
        if(error == nil && [placemarks count] > 0){
            
            placemark = [placemarks lastObject];
            
            self.address.text = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                                 placemark.subThoroughfare, placemark.thoroughfare,
                                 placemark.postalCode, placemark.locality,
                                 placemark.administrativeArea,
                                 placemark.country];
            
            //NSLog(@"%@ %@\n%@ %@\n%@\n%@", self.address.text);
        }else {
            //NSLog(@"%@", error.debugDescription);
        }
    }];
    
    if([currentOption isEqualToString:@"A"]){
       // NSLog(@"Pinging, option a");

        if(distance <= [currentDestination[@"radius"] doubleValue]){
            if(!entered){
                gpsPingAlert = [[UIAlertView alloc] initWithTitle:@"Auto GPS Ping"
                                                          message:@"Are you at McDonald's?"
                                                         delegate:self
                                                cancelButtonTitle:@"Yes"
                                                otherButtonTitles:@"No", nil];
                [gpsPingAlert show];
                [autoTimeStamps setObject:[self dateAndTime] forKey: [@"autoGPS-" stringByAppendingString:[@(autoCount) stringValue]]];
                autoCount++;
                
                entered = true;
                
                startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
                
                [self ping];
            }
        }else {
            //NSLog(@"ping count %d",pingCount);
            if(pingCount == 6){
                geofences = [self buildGeofenceData];
                [self initializeRegionMonitoring:geofences];
                [manager stopUpdatingLocation];
                self.readOut.text = @"GPS ping is done";
                
                startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
            }
        }
    }
    
    if([currentOption isEqualToString:@"B"]){
        //NSLog(@"Pinging, option b");
        if(distance <= [currentDestination[@"radius"] doubleValue]){
            if(!entered){
                gpsPingAlert = [[UIAlertView alloc] initWithTitle:@"Auto GPS Ping"
                                                          message:@"Are you at McDonald's?"
                                                         delegate:self
                                                cancelButtonTitle:@"Yes"
                                                otherButtonTitles:@"No", nil];
                
                [gpsPingAlert show];
                [autoTimeStamps setObject:[self dateAndTime] forKey: [@"autoGPS-" stringByAppendingString:[@(autoCount) stringValue]]];
                autoCount++;
                
                entered = true;
                
                startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
                
                [self ping];
            }
        }else {
            //NSLog(@"ping count %d",pingCount);
            if(pingCount == 6){
                geofences = [self buildGeofenceData];
                [self initializeRegionMonitoring:geofences];
                [manager stopUpdatingLocation];
                self.readOut.text = @"GPS ping is done";
                
                if(!bInitLocation){
                    startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
                    bInitLocation = true;
                }
            }
        }
    }
    
    if([currentOption isEqualToString:@"C"]){
        //NSLog(@"Pinging, option c");
        if(distance <= [currentDestination[@"radius"] doubleValue]){
            if(!entered){
                gpsPingAlert = [[UIAlertView alloc] initWithTitle:@"Auto GPS Ping"
                                                          message:@"Are you at McDonald's?"
                                                         delegate:self
                                                cancelButtonTitle:@"Yes"
                                                otherButtonTitles:@"No", nil];
                
                [gpsPingAlert show];
                [autoTimeStamps setObject:[self dateAndTime] forKey: [@"autoGPS-" stringByAppendingString:[@(autoCount) stringValue]]];
                autoCount++;
                
                entered = true;
                
                startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
                
                [self ping];
            }
        }else {
            //NSLog(@"ping count %c",pingCount);
            if(pingCount == 6){
                geofences = [self buildGeofenceData];
                [self initializeRegionMonitoring:geofences];
                [manager stopUpdatingLocation];
                self.readOut.text = @"GPS ping is done";
                
                startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
            }
        }
    }
    
    if([currentOption isEqualToString:@"D"]){
        //NSLog(@"Pinging, option d");
        if(distance <= [currentDestination[@"radius"] doubleValue]){
            if(!entered){
                
                gpsHelloAlert = [[UIAlertView alloc] initWithTitle:@"Auto GPS Boundary Crossing Alert"
                                                           message:@"Are you at McDonald's?"
                                                          delegate:self
                                                 cancelButtonTitle:@"Yes"
                                                 otherButtonTitles:@"No", nil];
                [gpsHelloAlert show];
                [autoTimeStamps setObject:[self dateAndTime] forKey: [@"autoGPS-" stringByAppendingString:[@(autoCount) stringValue]]];
                
                
                NSLog(@"%@", autoTimeStamps);
                autoCount++;
                entered = true;
                
                [self ping];
            }
        }
        if(pingCount == 6){
            startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
        }
    }
    
    if([currentOption isEqualToString:@"E"]){
        //NSLog(@"Pinging, option e");
        if(distance <= [currentDestination[@"radius"] doubleValue]){
            if(!entered){
                gpsHelloAlert = [[UIAlertView alloc] initWithTitle:@"Auto GPS Boundary Crossing Alert"
                                                           message:@"Are you at McDonald's?"
                                                          delegate:self
                                                 cancelButtonTitle:@"Yes"
                                                 otherButtonTitles:@"No", nil];
                
                [gpsHelloAlert show];
                [autoTimeStamps setObject:[self dateAndTime] forKey: [@"autoGPS-" stringByAppendingString:[@(autoCount) stringValue]]];
                autoCount++;
                entered = true;
                
                [self ping];
            }
        }
        if(pingCount == 6){
            startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
        }
    }
    
    if([currentOption isEqualToString:@"F"]){
        //NSLog(@"Pinging, option f");
        if(distance <= [currentDestination[@"radius"] doubleValue]){
            if(!entered){
                gpsHelloAlert = [[UIAlertView alloc] initWithTitle:@"Auto GPS Boundary Crossing Alert"
                                                           message:@"Are you at McDonald's?"
                                                          delegate:self
                                                 cancelButtonTitle:@"Yes"
                                                 otherButtonTitles:@"No", nil];
                
                [gpsHelloAlert show];
                [autoTimeStamps setObject:[self dateAndTime] forKey: [@"autoGPS-" stringByAppendingString:[@(autoCount) stringValue]]];
                autoCount++;
                entered = true;
                
                [self ping];
            }
        }
        if(pingCount == 6){
            startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
        }
    }
    
    //[self batteryStatus];
    pingCount++;
}

//formatting
- (NSTimeInterval) timeStamp {
    return [[NSDate date] timeIntervalSince1970];
}

-(NSString*) dateAndTime{
    // get current date/time
    NSString *date;
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    date = [dateFormatter stringFromDate:now];
    
    return date;
}

-(void) ping{
    NSURL *pathURL = [NSURL fileURLWithPath : [[NSBundle mainBundle] pathForResource:@"ding" ofType:@"mp3"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &ding);
    AudioServicesPlaySystemSound(ding);
}

//end/////////////////////////////////////////////////////////

@end
