//
//  SettingsController.m
//  McApp
//
//  Created by Booker Washington on 9/14/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#import "SettingsController.h"

@interface SettingsController ()

- (IBAction)optionA:(id)sender;
- (IBAction)optionB:(id)sender;
- (IBAction)optionC:(id)sender;
- (IBAction)optionD:(id)sender;
- (IBAction)optionE:(id)sender;
- (IBAction)optionF:(id)sender;

- (IBAction)set:(id)sender;

@property (strong, nonatomic) IBOutlet UITextField *proximity;
@property (strong, nonatomic) IBOutlet UILabel *beingMonitored;


@end

@implementation SettingsController{

UIAlertView *alertA;
UIAlertView *alertB;
UIAlertView *alertC;
UIAlertView *alertD;
UIAlertView *alertE;
UIAlertView *alertF;
    
UIAlertView *setAlert;
    
IBOutlet UILabel *choosenOption;

NSString *radius;
NSString *setTitle;
    
BOOL inSession;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    choosenOption.text = self.option;
    NSLog(self.option);

    self.proximity.text = self.currentDestination[@"radius"];
    self.title = @"Settings";
    
    setTitle = self.currentDestination[@"title"];
    
    NSLog(self.currentDestination[@"radius"]);
    
    self.proximity.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberRadius"];
    inSession = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //NSLog(@"Go");
    
    if(![choosenOption.text isEqualToString:@""])
    [_delegate dataFromChoice: choosenOption.text];
    [_delegate dataFromDestination: radius];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView == alertA){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            choosenOption.text = @"A";
        }
    }

    if(alertView == alertB){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            choosenOption.text = @"B";
        }
    }
    
    if(alertView == alertC){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            choosenOption.text = @"C";
        }
    }

    if(alertView == alertD){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            choosenOption.text = @"D";
        }
    }
    
    if(alertView == alertE){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            choosenOption.text = @"E";
        }
    }
    
    if(alertView == alertF){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            choosenOption.text = @"F";
        }
    }
 
    if(alertView == setAlert){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            if(![self.proximity.text isEqualToString:@""] && ![choosenOption.text isEqualToString:@""]){
                NSLog(@"OK");
                
                @try{
                    radius = self.proximity.text;
                    [self.navigationController popViewControllerAnimated:YES];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:self.proximity.text forKey:@"rememberRadius"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }@catch(NSException *exception){
                  
                }
            }else{
                alertA = [[UIAlertView alloc] initWithTitle:@"Please set all parameters: Location, Proximity, Option"
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                [alertA show];
            }
        }
    }
}

- (IBAction)optionA:(id)sender {
    [self.view endEditing:YES];
    
    alertA = [[UIAlertView alloc] initWithTitle:@"Option A"
                                          message:@""
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertA show];
}

- (IBAction)optionB:(id)sender {
    [self.view endEditing:YES];
    alertB = [[UIAlertView alloc] initWithTitle:@"Option B"
                                        message:@""
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertB show];
}

- (IBAction)optionC:(id)sender {
    [self.view endEditing:YES];
    alertC = [[UIAlertView alloc] initWithTitle:@"Option C"
                                          message:@""
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertC show];
}

- (IBAction)optionD:(id)sender {
    [self.view endEditing:YES];
    alertD = [[UIAlertView alloc] initWithTitle:@"Option D"
                                          message:@"Standard Location Service - Best"
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertD show];
}

- (IBAction)optionE:(id)sender {
    [self.view endEditing:YES];
    alertE = [[UIAlertView alloc] initWithTitle:@"Option E"
                                        message:@"Standard Location Service - Nearest Ten Meters"
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:@"Cancel", nil];
    [alertE show];

}

- (IBAction)optionF:(id)sender {
    [self.view endEditing:YES];
    alertF = [[UIAlertView alloc] initWithTitle:@"Option F"
                                        message:@""
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:@"Cancel", nil];
    [alertF show];
}

- (IBAction)set:(id)sender {
    setAlert = [[UIAlertView alloc] initWithTitle:@"ALL SET?"
                                              message:@""
                                             delegate:self
                                    cancelButtonTitle:@"Yes"
                                    otherButtonTitles:@"No", nil];
    [setAlert show];
}

@end
