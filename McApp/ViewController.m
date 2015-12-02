#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "SettingsController.h"
#import "ResultsController.h"
#include <mach/mach_time.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController () <CLLocationManagerDelegate, SettingsControllerDelegate, ResultsControllerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *latitude;
@property (weak, nonatomic) IBOutlet UILabel *longitude;
@property (weak, nonatomic) IBOutlet UILabel *address;
@property (weak, nonatomic) IBOutlet UILabel *speed;
@property (strong, nonatomic) IBOutlet UILabel *delta;
@property (strong, nonatomic) IBOutlet UILabel *option;
@property (strong, nonatomic) IBOutlet UILabel *radiusOutput;

@property (strong, nonatomic) IBOutlet UISegmentedControl *startStop;
@property (strong, nonatomic) IBOutlet UILabel *battery;

@property (strong, nonatomic) IBOutlet UILabel *destinationLocation;
@property (strong, nonatomic) IBOutlet UILabel *readOut;
@property (strong, nonatomic) IBOutlet UILabel *manualMessage;

@property (strong, nonatomic) IBOutlet UIButton *confirmGeoUI;
@property (strong, nonatomic) IBOutlet UIButton *endSession;

@property (strong, nonatomic) IBOutlet UILabel *gpsOp;
@property (strong, nonatomic) IBOutlet UILabel *nearMidFar;

- (IBAction)startStop:(id)sender;
- (IBAction)confirmGeo:(id)sender;
- (IBAction)gotoResults:(id)sender;

@property (strong, nonatomic) IBOutlet UIButton *confirmGeofence;
@property (strong, nonatomic) IBOutlet UITextView *addressField;

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
    bool haveResults;

    //Location
    NSArray *jsonLocation;
    NSDictionary *addressData;
    NSMutableArray *coordinateData;
    NSMutableArray *Data;
    NSString *location;
    int shortestDistance;
    
    //Timer
    NSTimer *timer;
    int on;
    int off;
    int timerCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Current Session";
    self.startStop.selectedSegmentIndex = 1;
    
    manager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    entered = false;
    
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
    if(![radius isEqualToString:@""]){
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
    self.option.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberOption"];
    self.radiusOutput.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberRadius"];

    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://45.55.238.244/int-data/"]];
    
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    coordinateData = [NSMutableArray array];
    
    if(![[[NSUserDefaults standardUserDefaults] stringForKey:@"rememberFirstTime"] isEqualToString:@"No"]){
        
        [[NSUserDefaults standardUserDefaults] setObject:@"1500" forKey:@"rememberDistance1"];
        [[NSUserDefaults standardUserDefaults] setObject:@"2500" forKey:@"rememberDistance2"];
        [[NSUserDefaults standardUserDefaults] setObject:@"150" forKey:@"rememberRadius"];
        [[NSUserDefaults standardUserDefaults] setObject:@"A" forKey:@"rememberOption"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self performSegueWithIdentifier: @"toSettings" sender: self];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@"No" forKey:@"rememberFirstTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    radius = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberRadius"];

    on = 60;
    off = 0;
    shortestDistance = 40000000;
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addressFieldTapped)];
    [self.addressField setUserInteractionEnabled:YES];
    [self.addressField addGestureRecognizer:gestureRecognizer];
    
    [[self.addressField layer] setBorderColor:[[UIColor blackColor] CGColor]];
    [[self.addressField layer] setBorderWidth:2];
    [[self.addressField layer] setCornerRadius:5];
    
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"address"] != nil)
        self.addressField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"address"];
}

-(void) addressFieldTapped{
    if([self.addressField.text isEqualToString:@"Enter an address"])
        self.addressField.text = @"";
    [self.addressField becomeFirstResponder];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

//get current location and nearest mcdonalds locations ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) getMcDonaldsBasedOnCurrentLocation{
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://maps.googleapis.com/maps/api/geocode/json?address=", [self.addressField.text stringByReplacingOccurrencesOfString:@" " withString:@"+"] ,@"+il&key=AIzaSyABuwnYjysfu_JqG2uuLzO5dS3fMWWRSPc"]]];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSData *objectData = [requestReply dataUsingEncoding:NSUTF8StringEncoding];
        
        addressData = [NSJSONSerialization JSONObjectWithData:objectData  options:kNilOptions error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            destinationPlot = [[CLLocation alloc] initWithLatitude:[addressData[@"results"][0][@"geometry"][@"location"][@"lat"] doubleValue] longitude:[addressData[@"results"][0][@"geometry"][@"location"][@"lng"] doubleValue]];
        });
        
        [self startSession];
        [[NSUserDefaults standardUserDefaults] setObject:self.addressField.text forKey:@"address"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }] resume];
}

//end ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
            haveResults = true;
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
        if (buttonIndex == 1) {
            [manager stopUpdatingLocation];
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
        transferSettingsController.delegate = self;
    }
    
    ResultsController *transferResultsController = segue.destinationViewController;
    if ([[segue identifier] isEqualToString:@"toResults"]){
        if([autoTimeStamps count] > 0){
            transferResultsController.autoTimeStamp = autoTimeStamps;
            transferResultsController.location = location;
        }else{
            transferResultsController.autoTimeStamp = [@{@"auto":@"none"} mutableCopy];
            transferResultsController.location = @"undefined location";
        }
        transferResultsController.manualTimeStamp = manualTimeStamps;
        transferResultsController.startLocation = startLocation;
        transferResultsController.sessionTime = sessionTime;
        
        if ([self.option.text isEqualToString:@"A" ]) {
           transferResultsController.options = [NSString stringWithFormat:@"%@ %@ %@",self.option.text, [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberDistance1"], [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberDistance2"]  ];
        }else{
            transferResultsController.options = self.option.text;
        }
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
}

- (void)dataFromDestination:(NSString *)data{
    if( data != NULL ){
        radius = data;
        self.radiusOutput.text = radius;
    }
}

//end////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Start and stop corelocation services////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)startData{
    self.gpsOp.hidden = true;
    self.nearMidFar.hidden = true;
    [self getStartLocation];
}

- (void)stopData{
    [manager stopUpdatingLocation];
    self.startStop.selectedSegmentIndex = 1;
    pingCount = 0;
    [sessionTime setObject:[self dateAndTime] forKey: @"stopSession"];
    [timer invalidate];
}

- (IBAction)startStop:(id)sender {
    switch (self.startStop.selectedSegmentIndex){
        case 1:
            endingAlert = [[UIAlertView alloc] initWithTitle:@"End Session?"
                                                     message:@""
                                                    delegate:self
                                           cancelButtonTitle:@"Yes"
                                           otherButtonTitles:@"No", nil];
            [endingAlert show];
            break;
        case 0:
            [self startData];
            break;
        default:
            break;
    }
}

-(void) startSession{

    manager.delegate = self;

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

    [manager requestAlwaysAuthorization];
    [manager requestWhenInUseAuthorization];
    [manager startUpdatingLocation];
    

    dispatch_async(dispatch_get_main_queue(), ^{
        self.startStop.selectedSegmentIndex = 0;
        
        self.confirmGeoUI.hidden = false;
        self.endSession.hidden = true;
        self.manualMessage.hidden = false;
        self.readOut.text = @"In Session";
    });
    
    haveResults = false;
    

    batteryStart = [[UIDevice currentDevice] batteryLevel] * 100;
    [sessionTime setObject:[self dateAndTime] forKey: @"startSession"];
    
    inSession = true;
    entered = false;
    
    [autoTimeStamps removeAllObjects];
    [manualTimeStamps removeAllObjects];
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
 
    dispatch_async(dispatch_get_main_queue(), ^{
        self.confirmGeoUI.hidden = true;
        self.manualMessage.hidden = true;
        self.readOut.text = @"";
    });
    
    if(haveResults){
        [self performSegueWithIdentifier: @"toResults" sender: self];
        self.endSession.hidden = false;
    }
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
    dispatch_async(dispatch_get_main_queue(), ^{
        self.gpsOp.hidden = false;
        self.nearMidFar.hidden = false;
        timerCount = 0;
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(gpsTimer) userInfo:nil repeats:YES];
    });
}

-(void)runOptionB{
    manager.desiredAccuracy = kCLLocationAccuracyBest;
}

-(void)runOptionC{
    manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
}

-(void)runOptionD{
    [manager stopUpdatingLocation];
}


-(void)gpsTimer{
    if(shortestDistance < [[[NSUserDefaults standardUserDefaults] stringForKey:@"rememberDistance1"] intValue]){
        on = 60;
        off = 0;
        self.nearMidFar.text = @"every second";
    }else if((shortestDistance > [[[NSUserDefaults standardUserDefaults] stringForKey:@"rememberDistance1"] intValue]) && (shortestDistance < [[[NSUserDefaults standardUserDefaults] stringForKey:@"rememberDistance2"] intValue])){
        on = 5;
        off = 10;
        self.nearMidFar.text = @"5s every 10s";
    }else if(shortestDistance > [[[NSUserDefaults standardUserDefaults] stringForKey:@"rememberDistance2"] intValue]){
        on = 5;
        off = 25;
        self.nearMidFar.text = @"5s every 25s";
    }
    
    if(timerCount % (on + off)  == 0){
        NSLog(@"on");
        self.gpsOp.text = @"GPS running";
        [manager startUpdatingLocation];
    }
    if(timerCount % (on + off)  == on){
        NSLog(@"off");
        self.gpsOp.text = @"GPS Waiting";
        [manager stopUpdatingLocation];
    }
    timerCount++;
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
        
        shortestDistance = MIN(shortestDistance, [currentLocation distanceFromLocation:mcDonaldsLocation]);
        //NSLog(@"%f", shortestDistance);
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
                    location = [jsonLocation objectAtIndex:i][@"address"][@"addressLine1"];
                    autoCount++;
                    haveResults = true;
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
        self.readOut.text = [NSString stringWithFormat:@"Countdown: %d", 3 - pingCount];

        if(pingCount == 3){
            [manager stopUpdatingLocation];
            self.readOut.text = @"Initial GPS ping is done";
            startLocation = @{@"latitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude], @"longitude" : [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude]};
            [self getMcDonaldsBasedOnCurrentLocation];
            currentOption = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberOption"];
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
