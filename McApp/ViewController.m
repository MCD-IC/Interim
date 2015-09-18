#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "SettingsController.h"

@interface ViewController () <CLLocationManagerDelegate, SettingsControllerDelegate>

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
    NSArray *_regionArray;
    NSArray *geofences;

    UIAlertView *hello;
    UIAlertView *goodbye;
    UIAlertView *customGeofence;
    UIAlertView *gotoSettings;
    NSDictionary *currentDestination;
    NSString *proximity;
    
    CLLocationCoordinate2D initialCoordinate;
    NSNumberFormatter *f;

    
    bool entered;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Current Location";
    _startStop.selectedSegmentIndex = 1;
    
    manager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    romeoville = [[CLLocation alloc] initWithLatitude:41.6717353 longitude:-88.0689936];
    entered = false;

    [self alerts];
    
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
    [[UIDevice currentDevice] batteryLevel];
    [[UIDevice currentDevice] batteryState];

    initialCoordinate.latitude = 41.6717353;
    initialCoordinate.longitude = -88.0689936;
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
        transferViewController.option = _currentOption.text;
        transferViewController.currentProximity = proximity;
        transferViewController.currentDestination = currentDestination;
        transferViewController.delegate = self;
    }
}

- (NSTimeInterval) timeStamp {
    return [[NSDate date] timeIntervalSince1970] * 1000;
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
    _currentOption.text = data;
}

- (void)dataFromDestination:(NSDictionary *)data{
    if( data != NULL ){
        currentDestination = data;
        _destinationLocation.text = data[@"title"];
        NSLog(@"Dictionary: %@", [data description]);

        initialCoordinate.latitude = [data[@"latitude"] doubleValue];//41.6717353;
        initialCoordinate.longitude = [data[@"longitude"] doubleValue];//-88.0689936;
    }
    
}

//end/////////////////////////////////////////////////////////

//Start and stop corelocation services/////////////////////////////////////////////////////////
- (void)startData{
    
    if ([self.currentOption.text isEqualToString:@""] && currentDestination != NULL){
        [gotoSettings show];
        _startStop.selectedSegmentIndex = 1;
    }else{
        geofences = [self buildGeofenceData];
        [self initializeRegionMonitoring:geofences];
        
        manager.delegate = self;
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        
        [manager requestAlwaysAuthorization];
        [manager requestWhenInUseAuthorization];
        [manager startUpdatingLocation];
      
        [self initializeMap];
    }
}

- (void)stopData{
    [manager stopUpdatingLocation];
    [manager stopMonitoringForRegion:geofences];
    
    [self.map setRegion:MKCoordinateRegionMakeWithDistance(initialCoordinate, 800, 800) animated:YES];
    self.map.centerCoordinate = initialCoordinate;
    
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
}

- (IBAction)confirmGPS:(id)sender {
    NSLog(@"%f",[self timeStamp]);
}
//end/////////////////////////////////////////////////////////


//Map and region monitor setting/////////////////////////////////////////////////////////
- (void)initializeMap {
    
    self.map.centerCoordinate = initialCoordinate;
    [self.map setRegion:MKCoordinateRegionMakeWithDistance(initialCoordinate, 800, 800) animated:YES];
    [self.map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:initialCoordinate];
    [annotation setTitle:currentDestination[@"title"]];
    [self.map addAnnotation:annotation];
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
        NSString *msg = [NSString stringWithFormat:
                         @"%0.2f%%\n%@", [[UIDevice currentDevice] batteryLevel] * 100];
        //NSLog(@"%@", msg);
        
        _battery.text = msg;
    }
}
//end/////////////////////////////////////////////////////////


//Geofenceing region monitoring/////////////////////////////////////////////////////////
#pragma mark - Location Manager - Region Task Methods

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entered Region - %@", region.identifier);
    NSLog(@"%f",[self timeStamp]);
    [hello show];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Exited Region - %@", region.identifier);
    NSLog(@"%f",[self timeStamp]);
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
    
    
    distance = [currentLocation distanceFromLocation:romeoville];
    //NSLog(@"Space %f", [currentLocation distanceFromLocation:space]);
    NSLog(@"distance %f m", distance);
    
    if(currentLocation != nil){
        self.latitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        self.longitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        self.speed.text = [NSString stringWithFormat:@"%.8f", newLocation.speed];
        self.delta.text = [NSString stringWithFormat:@"%.3f meters", distance];
    }
    
    if(distance <= 100){
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
            NSLog(@"%@", error.debugDescription);
            
        }
        
    }];
    
    [self batteryStatus];
}

//end/////////////////////////////////////////////////////////

@end
