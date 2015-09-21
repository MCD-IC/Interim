#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "SettingsController.h"

@interface ViewController () <CLLocationManagerDelegate, SettingsControllerDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *latitude;
@property (weak, nonatomic) IBOutlet UILabel *longitude;
@property (weak, nonatomic) IBOutlet UILabel *address;
@property (weak, nonatomic) IBOutlet UILabel *speed;
@property (strong, nonatomic) IBOutlet UILabel *delta;

@property (strong, nonatomic) IBOutlet MKMapView *map;

@property (strong, nonatomic) IBOutlet UISegmentedControl *startStop;
@property (strong, nonatomic) IBOutlet UILabel *battery;
@property (strong, nonatomic) IBOutlet UILabel *currentOption;
@property (strong, nonatomic) IBOutlet UILabel *destinationLocation;

- (IBAction)startStop:(id)sender;
- (IBAction)confirmGeo:(id)sender;
- (IBAction)confirmGPS:(id)sender;

@end

@implementation ViewController{
    CLLocationManager *manager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    CLLocation *destinationPlot;
    CLLocationDistance distance;
    
    NSArray *_regionArray;
    NSArray *geofences;
    MKCircle *circle;

    UIAlertView *hello;
    UIAlertView *goodbye;
    UIAlertView *customGeofence;
    UIAlertView *gotoSettings;
    NSDictionary *currentDestination;
    NSString *proximity;
    MKPointAnnotation *annotation;
    
    CLLocationCoordinate2D destinationCoordinate;
    NSNumberFormatter *f;
    NSString *currentOption;

    bool entered;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Current Location";
    self.startStop.selectedSegmentIndex = 1;
    
    manager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    entered = false;

    [self alerts];
    
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
    [[UIDevice currentDevice] batteryLevel];
    [[UIDevice currentDevice] batteryState];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Alerts /////////////////////////////////////////////////////////
-(void) alerts{
    gotoSettings = [[UIAlertView alloc] initWithTitle:@"Please Enter Your Settings"
                                       message:@"You are being sent to the settings screen."
                                      delegate:self
                             cancelButtonTitle:@"Okay"
                             otherButtonTitles:nil];
    
    
    hello = [[UIAlertView alloc] initWithTitle:@"Welcome"
                                                       message:@"Happy you made it."
                                                      delegate:self
                                             cancelButtonTitle:@"Thanks"
                                             otherButtonTitles:nil];
    
    goodbye = [[UIAlertView alloc] initWithTitle:@"Goodbye"
                                                       message:@"Have the best day."
                                                      delegate:self
                                             cancelButtonTitle:@"See ya"
                                             otherButtonTitles:nil];
    
    customGeofence = [[UIAlertView alloc] initWithTitle:@"Custom Hello"
                                         message:@"Custom Welcome"
                                        delegate:self
                               cancelButtonTitle:@"Custom Thank you"
                               otherButtonTitles:nil];
}
//end/////////////////////////////////////////////////////////

//Capturing data /////////////////////////////////////////////////////////
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    SettingsController *transferViewController = segue.destinationViewController;
    if ([[segue identifier] isEqualToString:@"toSettings"]){
        transferViewController.option = self.currentOption.text;
        transferViewController.currentProximity = proximity;
        transferViewController.currentDestination = currentDestination;
        transferViewController.delegate = self;
    }
}

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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView == gotoSettings){
        [self performSegueWithIdentifier:@"toSettings" sender:self];
    }
}
//end/////////////////////////////////////////////////////////

//set destination parameters from settings/////////////////////////////////////////////////////////
- (void)dataFromChoice:(NSString *)data{
    NSLog(data);
    NSLog(currentOption);
   
    if(![data isEqualToString:currentOption]){
        [self stopData];
        NSLog(@"It stopped");
    }
    
    currentOption = data;
    self.currentOption.text = data;
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
    [self.map removeAnnotations: self.map.annotations];
    
    destinationPlot = [[CLLocation alloc] initWithLatitude:[data[@"latitude"] doubleValue] longitude:[data[@"longitude"] doubleValue]];
    destinationCoordinate.latitude = [data[@"latitude"] doubleValue];
    destinationCoordinate.longitude = [data[@"longitude"] doubleValue];
    self.destinationLocation.text = data[@"title"];
    NSLog(@"Dictionary: %@", [data description]);
}

//end/////////////////////////////////////////////////////////

//Start and stop corelocation services/////////////////////////////////////////////////////////
- (void)startData{
    @try{
        if ([self.currentOption.text isEqualToString:@""]){
            [gotoSettings show];
            self.startStop.selectedSegmentIndex = 1;
        }else{
            
            if([currentOption isEqualToString:@"A"]) {
                [self runOptionA];
            }
            else if([currentOption isEqualToString:@"B"]) {
                [self runOptionB];
            }
            else if([currentOption isEqualToString:@"C"]) {
                [self runOptionC];
            }
            else if([currentOption isEqualToString:@"D"]) {
                [self runOptionD];
            }

        }
    }@catch(NSException *exception){
        [gotoSettings show];
    }
}

- (void)stopData{
    [manager stopUpdatingLocation];
    [manager stopMonitoringForRegion:geofences];
    self.startStop.selectedSegmentIndex = 1;
    [self.map removeOverlay:circle];
}

- (IBAction)startStop:(id)sender {
    switch (self.startStop.selectedSegmentIndex){
        case 1:
            NSLog(@"Off");
            [self stopData];
            break;
        case 0:
            NSLog(@"On");
            [self startData];
            break;
        default:
            break;
    }
    
}

- (IBAction)confirmGeo:(id)sender {
    NSLog(@"%f",[self timeStamp]);
    NSLog([self dateAndTime]);
}

- (IBAction)confirmGPS:(id)sender {
    NSLog(@"%f",[self timeStamp]);
    NSLog([self dateAndTime]);
}

//end////////////////////////////////////////////////////////


//Options to run/////////////////////////////////////////////////////////
-(void)runOptionA{
    geofences = [self buildGeofenceData];
    [self initializeRegionMonitoring:geofences];
    
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    [self initializeMap];
    self.startStop.selectedSegmentIndex = 0;
    
    NSLog(@"A");
}

-(void)runOptionB{
    geofences = [self buildGeofenceData];
    [self initializeRegionMonitoring:geofences];
    
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    [self initializeMap];
    self.startStop.selectedSegmentIndex = 0;

    NSLog(@"B");
}

-(void)runOptionC{
    geofences = [self buildGeofenceData];
    [self initializeRegionMonitoring:geofences];
    
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    [self initializeMap];
    self.startStop.selectedSegmentIndex = 0;
    
    NSLog(@"C");
}

-(void)runOptionD{
    geofences = [self buildGeofenceData];
    [self initializeRegionMonitoring:geofences];
    
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    [self initializeMap];
    self.startStop.selectedSegmentIndex = 0;

    NSLog(@"D");    
}

//end/////////////////////////////////////////////////////////


//Map and region monitor setting/////////////////////////////////////////////////////////
- (void)initializeMap {
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
    
    NSLog(@"Drawing circle");
    
    MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    [circleView setStrokeColor:[UIColor blackColor]];
    return circleView;
}

- (NSArray*) buildGeofenceData {
 
    NSMutableArray *geofences = [NSMutableArray array];
    CLRegion *region = [self mapDictionaryToRegion:currentDestination];
    [geofences addObject:region];
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

- (void)batteryStatus{
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
    }
}
//end/////////////////////////////////////////////////////////


//Geofenceing region monitoring/////////////////////////////////////////////////////////
#pragma mark - Location Manager - Region Task Methods

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entered Region - %@", region.identifier);
    NSLog(@"%f",[self timeStamp]);
    NSLog([self dateAndTime]);
    [hello show];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exited Region - %@", region.identifier);
    NSLog(@"%f",[self timeStamp]);
    NSLog([self dateAndTime]);
    [goodbye show];
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
    //NSLog(@"Space %f", [currentLocation distanceFromLocation:space]);
    //NSLog(@"distance %f m", distance);
    
    if(currentLocation != nil){
        self.latitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        self.longitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        self.speed.text = [NSString stringWithFormat:@"%.8f", newLocation.speed];
        self.delta.text = [NSString stringWithFormat:@"%.3f meters", distance];
    }
    
    if(distance <= [proximity doubleValue]){
        if(!entered){
            [customGeofence show];
            entered = true;
        }
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
    
    [self batteryStatus];
}

//end/////////////////////////////////////////////////////////

@end
