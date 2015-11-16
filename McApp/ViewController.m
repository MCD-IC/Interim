#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "SettingsController.h"
#import "ResultsController.h"
#include <mach/mach_time.h>
#import "NanoClock.h"

@interface ViewController () <CLLocationManagerDelegate, SettingsControllerDelegate, ResultsControllerDelegate, MKMapViewDelegate, NanoClockDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *latitude;
@property (weak, nonatomic) IBOutlet UILabel *longitude;
@property (weak, nonatomic) IBOutlet UILabel *address;
@property (weak, nonatomic) IBOutlet UILabel *speed;
@property (strong, nonatomic) IBOutlet UILabel *delta;
@property (strong, nonatomic) IBOutlet UILabel *option;

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

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIButton *confirmGeofence;

@end

@implementation ViewController{
    
    //CL Declarations
    CLLocationManager *manager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    CLLocation *destinationPlot;
    CLLocationDistance distance;
    
    //Maps
    MKCircle *circle;
    MKPointAnnotation *annotation;
    CLLocationCoordinate2D destinationCoordinate;

    //Alerts
    UIAlertView *gpsHelloAlert;
    UIAlertView *goodbyeAlert;
    UIAlertView *gotoSettingsAlert;
    UIAlertView *gpsPingAlert;
    UIAlertView *manualConfimationAlert;
    UIAlertView *endingAlert;
    UIAlertView *endSessionAlert;
    
    //Data Points
    NSDictionary *startLocation;
    NSMutableDictionary *sessionTime;
    NSString *currentOption;
    NSString *radius;
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

    NanoClock *nanoClock;
    
    NSArray *jsonLocation;
    NSMutableArray *addressData;
    NSMutableArray *coordinateData;
    
    NSMutableArray *Data;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Current Session";
    self.startStop.selectedSegmentIndex = 1;
    
    manager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    entered = false;
    
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
    /*if([currentDestination count] < 1){
        self.confirmGeoUI.hidden = true;
        self.endSession.hidden = true;
        self.manualMessage.hidden = true;
    }else{
        self.endSession.hidden = false;
        self.confirmGeoUI.hidden = false;
        self.manualMessage.hidden = false;
    }*/
    
    currentOption = @"";
    inSession = false;
    
    autoTimeStamps = [[NSMutableDictionary alloc] init];
    manualTimeStamps = [[NSMutableDictionary alloc] init];
    sessionTime = [[NSMutableDictionary alloc] init];
    
    manualCount = 0;
    autoCount = 0;
    
    self.readOut.text = @"To begin, go to settings and set parameters.";
    
    [self getStartLocation];

    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://45.55.238.244/int-data/"]];
    
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    //nanoClock = [[NanoClock alloc] init];
    //nanoClock.delegate = self;
    //[nanoClock setMilliseconds : 1000];
    //[nanoClock start];
    
    addressData = [NSMutableArray array];
    coordinateData = [NSMutableArray array];
}

//get current location and nearest mcdonalds locations ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) getMcDonaldsBasedOnCurrentLocation{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *CLServices = [NSString stringWithFormat:@"%@%@%@%@%@",@"http://apidev-us.mcd.com:9002/v3/restaurant/location?filter=geodistance&coords=", startLocation[@"latitude"], @",", startLocation[@"longitude"], @"&distance=10&market=US&languageName=en-us&size=11"];
    
    [request setURL:[NSURL URLWithString:CLServices]];
    [request setValue:@"VwWmfqPCQAFje0gIobXptGrrFnQM190t" forHTTPHeaderField:@"mcd_apikey"];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        //NSLog(@"requestReply: %@", requestReply);
        
        NSError *jsonError;
        NSData *objectData = [requestReply dataUsingEncoding:NSUTF8StringEncoding];
        jsonLocation = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&jsonError];

        for (int i = 0; i < [jsonLocation count]; i++) {
            //NSDictionary *address = [[jsonLocation objectAtIndex:i] objectForKey:@"address"];
            //address = [jsonLocation objectAtIndex:i][@"address"];
            
            [addressData addObject: [jsonLocation objectAtIndex:i][@"address"][@"addressLine1"]];
            [coordinateData addObject: [NSString stringWithFormat:@"%@%@%@", [jsonLocation objectAtIndex:i][@"address"][@"location"][@"lat"], @" ", [jsonLocation objectAtIndex:i][@"address"][@"location"][@"lon"]]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }] resume];
}

//end ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//uitableview ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(NSInteger) tableView :(UITableView *) tableView numberOfRowsInSection:(NSInteger) section{
    return [addressData count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIndentifier = @"locationCell";
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier forIndexPath:indexPath];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier ];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIndentifier ];
    }
    
    cell.textLabel.text = [addressData objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [coordinateData objectAtIndex:indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    //NSLog(@"%@", selectedCell.textLabel.text);
    destinationPlot = [[CLLocation alloc] initWithLatitude:[[jsonLocation objectAtIndex:indexPath.row][@"address"][@"location"][@"lat"] doubleValue] longitude:[[jsonLocation objectAtIndex:indexPath.row][@"address"][@"location"][@"lon"] doubleValue]];
}

//end ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) timeKeeper{
    NSLog(@"keeping time");
    [nanoClock stop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//notification ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) sendNotification{
    UIUserNotificationType types = UIUserNotificationTypeBadge |
    UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *mySettings =
    [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];

    localNotification.alertTitle = NSLocalizedString(@"Auto Notification", nil);
    localNotification.alertBody = @"You are at your desitnation";
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    //localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        application.applicationIconBadgeNumber = 0;
    }
    NSLog(@"didFinish");
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    application.applicationIconBadgeNumber = 0;
    
    NSLog(@"didRecieve");
}

//end ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Alerts /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

    
    if(alertView == gpsPingAlert){
        //if false
        if (buttonIndex == 1) {
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

//end//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Segue data sharing//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    SettingsController *transferSettingsController = segue.destinationViewController;
    if ([[segue identifier] isEqualToString:@"toSettings"]){
        transferSettingsController.option = self.option.text;
        transferSettingsController.delegate = self;
    }
    
    ResultsController *transferResultsController = segue.destinationViewController;
    if ([[segue identifier] isEqualToString:@"toResults"]){
        transferResultsController.autoTimeStamp = autoTimeStamps;
        transferResultsController.manualTimeStamp = manualTimeStamps;
        transferResultsController.startLocation = startLocation;
        transferResultsController.sessionTime = sessionTime;
        transferResultsController.option = self.option.text;
        transferResultsController.batteryUsed = [@(batteryStart - batteryEnd) stringValue];
        transferResultsController.delegate = self;
    }
}

//end/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Set destination parameters from settings///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)dataFromChoice:(NSString *)data{
    if(![data isEqualToString:currentOption]){
        [self stopData];
    }
    
    currentOption = data;
    self.option.text = data;
    self.readOut.text = @"Press start to begin session.";
}

- (void)dataFromDestination:(NSString *)data{
    if( data != NULL ){
        radius = data;
        
       /* if(![data[@"title"] isEqualToString:currentDestination[@"title"]]){
            [self stopData];
            [self resetCoordinates: data];
        }
        
        if(![data[@"radius"] isEqualToString:currentDestination[@"radius"]]){
            [self stopData];
            [self resetCoordinates: data];
        }*/
    }
}

-(void) resetCoordinates:(NSDictionary *)data{
//    currentDestination = data;
    

    self.destinationLocation.text = data[@"title"];
    destinationPlot = [[CLLocation alloc] initWithLatitude:[data[@"latitude"] doubleValue] longitude:[data[@"longitude"] doubleValue]];
}

//end////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Start and stop corelocation services////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
            manager.delegate = self;
            manager.desiredAccuracy = kCLLocationAccuracyBest;
            
            [manager requestAlwaysAuthorization];
            [manager requestWhenInUseAuthorization];
            [manager startUpdatingLocation];

            self.startStop.selectedSegmentIndex = 0;
            
            
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
    self.startStop.selectedSegmentIndex = 1;
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

//end///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Options to run//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)getStartLocation{
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    
    pingCount = 0;
    currentOption = @"start";
}


-(void)runOptionA{
    
}

-(void)runOptionB{

}

-(void)runOptionC{

}

-(void)runOptionD{
    manager.desiredAccuracy = kCLLocationAccuracyBest;

}

-(void)runOptionE{
    manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
}


-(void)runOptionF{

}

//end//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//GPS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark CLLocationManagerDelegate Methods

- (void)locationManager: (nonnull CLLocationManager *)manager didFailWithError: (nonnull NSError *)error {
    NSLog(@"Error: %@", error);
    NSLog(@"Failed to get location :-(");
}

- (void)locationManager: (nonnull CLLocationManager *)manager didUpdateToLocation: (CLLocation *)newLocation fromLocation: (CLLocation *)oldLocation{

    CLLocation *currentLocation = newLocation;
    
    distance = [currentLocation distanceFromLocation:destinationPlot];

    for (int i = 0; i < [jsonLocation count]; i++) {
        CLLocation *mcDonaldsLocation = [[CLLocation alloc] initWithLatitude:[[jsonLocation objectAtIndex:i][@"address"][@"location"][@"lat"] doubleValue] longitude:[[jsonLocation objectAtIndex:i][@"address"][@"location"][@"lon"] doubleValue]];

        if([currentLocation distanceFromLocation:mcDonaldsLocation] < [radius doubleValue]){
            if(!entered){
                @try{
                    gpsHelloAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", @"Auto Boundary Crossing Alert:",[jsonLocation objectAtIndex:i][@"address"][@"addressLine1"]]
                                                               message:@"Are you at McDonald's?"
                                                              delegate:self
                                                     cancelButtonTitle:@"Yes"
                                                     otherButtonTitles:@"No", nil];
                    [gpsHelloAlert show];
                    [autoTimeStamps setObject:[self dateAndTime] forKey: [@"autoGPS-" stringByAppendingString:[@(autoCount) stringValue]]];
                    [self sendNotification];
                    
                    autoCount++;
                    entered = true;
                    
                }@catch (NSException *exception) {
                    NSLog(@"Exception:%@",exception);
                }
            }
        }
    }
    
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
        }else {/*NSLog(@"%@", error.debugDescription);*/}
    }];
    
    if([currentOption isEqualToString:@"start"]){
        if(pingCount == 6){
            [manager stopUpdatingLocation];
            self.readOut.text = @"GPS ping is done";
            startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
            [self getMcDonaldsBasedOnCurrentLocation];
        }
    }

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

//end/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@end
