//
//  ResultsController.m
//  McApp
//
//  Created by Booker Washington on 9/22/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#import "ResultsController.h"
#import <Firebase/Firebase.h>

@interface ResultsController ()

@property (strong, nonatomic) IBOutlet UILabel *autoTimeStampLabel;
@property (strong, nonatomic) IBOutlet UILabel *manualTimeStampLabel;
@property (strong, nonatomic) IBOutlet UILabel *batteryUsage;
@property (strong, nonatomic) IBOutlet UILabel *optionLevel;

- (IBAction)saveData:(id)sender;

@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *sessionTextField;

@end

@implementation ResultsController

NSDictionary *dataToSave;
UIAlertView  *sendAlert;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Results";
    
    self.autoTimeStampLabel.text = self.autoTimeStamp;
    self.manualTimeStampLabel.text  = self.manualTimeStamp;
    self.batteryUsage.text  = self.batteryLevel;
    self.optionLevel.text  = self.option;
    
    /*self.autoTimeStampLabel.text = @"12-35-65";
    self.manualTimeStampLabel.text  = @"12-34-56";
    self.batteryUsage.text  = @"100%";
    self.optionLevel.text  = @"D";*/

    NSLog(self.option);
    
    self.nameTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberName"];
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
    sendAlert = [[UIAlertView alloc] initWithTitle:@"Complete the Session"
                                        message:@""
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [sendAlert show];
}

-(void) saveAndSend{
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://geogps-interim.firebaseio.com/"];
    
    Firebase *usersRef = [ref childByAppendingPath: self.nameTextField.text];
    
    NSDictionary *sessionData = @{self.sessionTextField.text: @{
                                          @"option": self.optionLevel.text,
                                          @"autoTimeStamp": self.autoTimeStampLabel.text,
                                          @"manualTimeStamp": self.manualTimeStampLabel.text,
                                          @"battery":self.batteryUsage.text
                                          }};
    
    [usersRef updateChildValues: sessionData withCompletionBlock:^(NSError *error, Firebase *ref) {
        if (error) {
            NSLog(@"Data could not be saved.");
        } else {
            NSLog(@"Data saved successfully.");
        }
    }];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.nameTextField.text forKey:@"rememberName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    [[NSUserDefaults standardUserDefaults] setObject:sessionData forKey:@"session"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.view endEditing:YES];
    //return
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberName"]);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end