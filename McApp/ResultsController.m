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
#import "NotesController.h"

@interface ResultsController () <NotesControllerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *sendingLabel;

@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *sessionTextField;
@property (strong, nonatomic) IBOutlet UILabel *wifiLabel;
@property (strong, nonatomic) IBOutlet UITextView *resultText;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *sending;

- (IBAction)saveData:(id)sender;

@end

@implementation ResultsController

UIAlertView  *sendAlert;
UIAlertView  *sessionAlert;
NSString *cellProvider;
NSString *phoneType;
NSString *notes;

Firebase *ref;
Firebase *usersRef;
NSDictionary *sessionData;

bool sent;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Results";
    notes = @"none";

    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    
    self.nameTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberName"];
    self.sendingLabel.text = @"";

    phoneType = deviceName();
    cellProvider = [carrier carrierName];
    
    [self.resultText setEditable:NO];
    [self setDataTextfield];

    self.sending.hidden = true;
    
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NotesController *transferNotesController  = segue.destinationViewController;
    if ([[segue identifier] isEqualToString:@"toNotes"]){

        transferNotesController.delegate = self;
    }
}

- (void)notesText:(NSString *)data{
    NSLog(@"%@", data);
    notes = data;
}

- (IBAction)wifiSwitch:(id)sender {
    if([sender isOn]){
        self.wifiLabel.text = @"Yes";
        [self setDataTextfield];
    }else{
        self.wifiLabel.text = @"No";
        [self setDataTextfield];
    }
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizeTapGesture:)];
    [self.resultText.superview addGestureRecognizer:tapGesture];
}

- (void) setDataTextfield{
    @try{
        self.resultText.text = [NSString stringWithFormat:@"%@",@{@"option": self.option,
                                                                  @"autoTimeStamp": self.autoTimeStamp,
                                                                  @"manualTimeStamp": self.manualTimeStamp,
                                                                  @"startLocation": self.startLocation,
                                                                  @"battery":self.batteryUsed,
                                                                  @"location": self.location,
                                                                  @"provider": cellProvider,
                                                                  @"phoneType": phoneType,
                                                                  @"wifiOnOff": self.wifiLabel.text,
                                                                  @"sessionTime":self.sessionTime,
                                                                  @"notes":notes
                                                                  }];
        

    }@catch (NSException *exception) {
        NSLog(@"Exception:%@",exception);
    }
}

- (void)didRecognizeTapGesture:(UITapGestureRecognizer*)gesture{
    CGPoint point = [gesture locationInView:gesture.view];
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        if (CGRectContainsPoint(self.resultText.frame, point)){
            [self.view endEditing:YES];
        }
    }
}

- (IBAction)saveData:(id)sender {
    if(![self.nameTextField.text isEqualToString:@""]){
        if(![self.sessionTextField.text isEqualToString:@""]){
            self.sending.hidden = false;
            self.sendingLabel.text = @"sending...";
            [self saveAndSend];
        }else{
            [self beforeSendAlert];
        }
    }else{
        [self beforeSendAlert];
    }

}

-(void) saveAndSend{
    ref = [[Firebase alloc] initWithUrl:@"https://geogps-interim.firebaseio.com/"];
    usersRef = [ref childByAppendingPath: [self.nameTextField.text stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    NSLog(@"saveandsend");
    
    [self dataToSave];
    
    /*[ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        @try {
            if([snapshot.value[[self.nameTextField.text stringByReplacingOccurrencesOfString:@" " withString:@"_"]][[self.sessionTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""]] count] == 0){
                NSLog(@"fill it");
                
                [self dataToSave];
            }else{
                sessionAlert = [[UIAlertView alloc] initWithTitle:@"This session name is already taken."
                                                          message:@"Would you like to overwrite?"
                                                         delegate:self
                                                cancelButtonTitle:@"Yes"
                                                otherButtonTitles:@"No", nil];
                [sessionAlert show];
                
                self.sending.hidden = true;
                self.sendingLabel.text = @"";
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception:%@",exception);
            //[self dataToSave];
        }
    }];*/
    
    [[NSUserDefaults standardUserDefaults] setObject:self.nameTextField.text forKey:@"rememberName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.view endEditing:YES];
}

-(void)beforeSendAlert{
    sendAlert = [[UIAlertView alloc] initWithTitle:@"To save the session results, complete your name and session title."
                                               message:@""
                                              delegate:self
                                     cancelButtonTitle:@"Okay"
                                     otherButtonTitles:nil];
    [sendAlert show];
}
    
    
-(void) dataToSave{
    sessionData = @{[self.sessionTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""]: @{
                    @"option": self.option,
                    @"autoTimeStamp": self.autoTimeStamp,
                    @"battery":self.batteryUsed,
                    @"manualTimeStamp": self.manualTimeStamp,
                    @"startLocation": self.startLocation,
                    @"location": self.location,
                    @"provider": cellProvider,
                    @"phoneType": phoneType,
                    @"wifiOnOff": self.wifiLabel.text,
                    @"sessionTime":self.sessionTime
                    }};

    NSLog(@"%@", sessionData);
    
    [usersRef updateChildValues: sessionData withCompletionBlock:^(NSError *error, Firebase *ref) {
        self.sending.hidden =  false;
        self.sendingLabel.text = @"sending...";
        
        if (error) {
            NSLog(@"Data could not be saved.");
            UIAlertView *alertA = [[UIAlertView alloc] initWithTitle:@"Server error"
                                                             message:@"Please try again"
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles: nil];
            [alertA show];
            
            self.sending.hidden =  true;
            self.sendingLabel.text = @"";
            
        } else {
            NSLog(@"Data saved successfully.");
            UIAlertView *alertB = [[UIAlertView alloc] initWithTitle:@"Sent"
                                                message:@"Your data was saved to the cloud."
                                               delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles: nil];
            [alertB show];
            
            self.sendingLabel.text = @"sent";
            self.sending.hidden =  true;
        }
    }];
    
    [[NSUserDefaults standardUserDefaults] setObject:sessionData forKey:@"session"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView == sessionAlert){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            [self dataToSave];
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