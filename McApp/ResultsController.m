//
//  ResultsController.m
//  McApp
//
//  Created by Booker Washington on 9/22/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#import "ResultsController.h"
#import <Firebase/Firebase.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <sys/utsname.h>

@interface ResultsController ()

@property (strong, nonatomic) IBOutlet UILabel *autoTimeStampLabel;
@property (strong, nonatomic) IBOutlet UILabel *manualTimeStampLabel;
@property (strong, nonatomic) IBOutlet UILabel *batteryUsageLabel;
@property (strong, nonatomic) IBOutlet UILabel *optionLevel;
@property (strong, nonatomic) IBOutlet UILabel *sendingLabel;

@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *sessionTextField;

- (IBAction)saveData:(id)sender;

@end

@implementation ResultsController

UIAlertView  *sendAlert;
UIAlertView  *sessionAlert;

NSString *wifiOnOff;
NSString *cellProvider;
NSString *phoneType;

Firebase *ref;
Firebase *usersRef;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Results";

    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    
    self.nameTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberName"];
    self.sendingLabel.text = @"";

    //self.batteryUsage.text  = self.batteryLevel;
    //self.autoTimeStampLabel.text = self.autoTimeStamp;
    //self.manualTimeStampLabel.text  = self.manualTimeStamp;

    self.optionLevel.text  = self.option;

    phoneType = deviceName();
    cellProvider = [carrier carrierName];
    
    //NSLog(self.option);
    //NSLog(deviceName());
    //NSLog(@"Carrier Name: %@", [carrier carrierName]);
}

- (IBAction)saveData:(id)sender {

    if(![self.autoTimeStampLabel.text isEqualToString:@""]){
        if(![self.manualTimeStampLabel.text isEqualToString:@""]){
            if(![self.nameTextField.text isEqualToString:@""]){
                if(![self.sessionTextField.text isEqualToString:@""]){
                    [self saveAndSend];
                }else{
                    [self beforeSendAlert];
                }
            }else{
                [self beforeSendAlert];
            }
        }else{
            [self beforeSendAlert];
        }
    }else{
        [self beforeSendAlert];
    }
}

-(void)beforeSendAlert{
    sendAlert = [[UIAlertView alloc] initWithTitle:@"To save a session results, the session must be complete."
                                        message:@""
                                       delegate:self
                              cancelButtonTitle:@"Okay"
                              otherButtonTitles:nil];
    [sendAlert show];
}

-(void) saveAndSend{
    ref = [[Firebase alloc] initWithUrl:@"https://geogps-interim.firebaseio.com/"];
    usersRef = [ref childByAppendingPath: self.nameTextField.text];
    
    [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"%@", snapshot.value[self.nameTextField.text][self.sessionTextField.text]);
        if([snapshot.value[self.nameTextField.text][self.sessionTextField.text] count] == 0){
            NSLog(@"fill it");
            
            [self dataToSave];
        }else{
            sessionAlert = [[UIAlertView alloc] initWithTitle:@"This session name is already taken."
                                                   message:@"Would you like to overwrite?"
                                                  delegate:self
                                         cancelButtonTitle:@"Yes"
                                         otherButtonTitles:@"No", nil];
            [sessionAlert show];
        }


    }];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.nameTextField.text forKey:@"rememberName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.view endEditing:YES];
}

-(void) dataToSave{
    NSDictionary *sessionData = @{self.sessionTextField.text: @{
                                    @"option": self.optionLevel.text,
                                    @"location": self.location,
                                    @"provider": cellProvider,
                                    @"phoneType": phoneType,
                                    @"wifiOnOff": wifiOnOff,
                                    @"radii":self.radii,
                                    @"sessionTime":self.sessionTime
                                }};
    
    NSLog(@"%@", sessionData);
    /*
    
    [usersRef updateChildValues: sessionData withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        self.sendingLabel.text = @"sending...";
        
        if (error) {
            NSLog(@"Data could not be saved.");
            UIAlertView *alertA = [[UIAlertView alloc] initWithTitle:@"Server error"
                                                             message:@"Please try again"
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles: nil];
            [alertA show];
        } else {
            NSLog(@"Data saved successfully.");
            UIAlertView *alertB = [[UIAlertView alloc] initWithTitle:@"Sent"
                                                message:@"Your data was saved to the cloud."
                                               delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles: nil];
            [alertB show];
            
            self.sendingLabel.text = @"sent";
        }
    }];
    
    [[NSUserDefaults standardUserDefaults] setObject:sessionData forKey:@"session"];
    [[NSUserDefaults standardUserDefaults] synchronize];*/
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView == sendAlert){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            [self saveAndSend];
        }
    }
    
    if(alertView == sessionAlert){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            [self saveAndSend];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

NSString* deviceName(){
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

@end