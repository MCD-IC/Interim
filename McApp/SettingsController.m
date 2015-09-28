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

- (IBAction)toRomeoville:(id)sender;
- (IBAction)toChicago:(id)sender;
- (IBAction)toOakBrook:(id)sender;
- (IBAction)set:(id)sender;

@property (strong, nonatomic) IBOutlet UITextField *proximity;
@property (strong, nonatomic) IBOutlet UILabel *beingMonitored;

@property (strong, nonatomic) IBOutlet UITextField *customTitle;
@property (strong, nonatomic) IBOutlet UITextField *customLatitude;
@property (strong, nonatomic) IBOutlet UITextField *customLongitude;
- (IBAction)enterCustomLocation:(id)sender;

@end

@implementation SettingsController{

UIAlertView *alertA;
UIAlertView *alertB;
UIAlertView *alertC;
UIAlertView *alertD;
UIAlertView *alertE;
    
UIAlertView *alertRomeoville;
UIAlertView *alertChicago;
UIAlertView *alertOakBrook;
UIAlertView *alertCustom;
    
UIAlertView *setAlert;
    
IBOutlet UILabel *choosenOption;

NSDictionary *destination;
    
NSString *setLatitude;
NSString *setLongitude;
NSString *setTitle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.

    choosenOption.text = self.option;
    NSLog(self.option);
    
    self.beingMonitored.text = self.currentDestination[@"title"];
    self.proximity.text = self.currentDestination[@"radius"];
    self.title = @"Settings";
    
    setLatitude = self.currentDestination[@"latitude"];
    setLongitude = self.currentDestination[@"longitude"];
    setTitle = self.currentDestination[@"title"];
    
    if(![setTitle isEqualToString:@"Chicago"]  ){
        if(![setTitle isEqualToString:@"Oak Brook"]  ){
            if(![setTitle isEqualToString:@"Romeoville"]  ){
                self.customTitle.text = setTitle;
                self.customLatitude.text = setLatitude;
                self.customLongitude.text = setLongitude;
            }
        }
    }
    
    NSLog(self.currentDestination[@"radius"]);
    
    self.customTitle.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"customLocation"][@"title"];
    self.customLatitude.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"customLocation"][@"latitude"];
    self.customLongitude.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"customLocation"][@"longitude"];
    
     //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"customLocation"]);
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
    [_delegate dataFromDestination: destination];
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
 
    if(alertView == setAlert){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            if(![setLatitude isEqualToString:@""] && ![self.proximity.text isEqualToString:@""] && ![choosenOption.text isEqualToString:@""]){
                NSLog(@"OK");
                
                @try{
                    destination = @{@"latitude":setLatitude, @"longitude":setLongitude, @"radius":self.proximity.text, @"title":setTitle};
                    NSLog(@"%@", destination);
                    [self.navigationController popViewControllerAnimated:YES];
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
    
    if(alertView == alertRomeoville){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            self.beingMonitored.text = @"Romeoville";
            
            setLatitude = @"41.6721034";
            setLongitude = @"-88.0681658";
            setTitle = @"Romeoville";
            [self clearCustom];
        }
    }
    
    if(alertView == alertChicago){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            self.beingMonitored.text = @"Chicago";

            setLatitude = @"41.8860837";
            setLongitude = @"-87.6321842";
            setTitle = @"Chicago";
            [self clearCustom];
        }
    }
    
    if(alertView == alertOakBrook){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            self.beingMonitored.text = @"Oak Brook";
            
            setLatitude = @"41.8477231";
            setLongitude = @"-87.9476483";
            setTitle = @"Oak Brook";
            [self clearCustom];
        }
    }
    
    if(alertView == alertCustom){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            self.beingMonitored.text = self.customTitle.text;
            
            setLatitude = self.customLatitude.text;
            setLongitude = self.customLongitude.text;
            setTitle = self.customTitle.text;
            
            [[NSUserDefaults standardUserDefaults] setObject:@{@"title":self.customTitle.text,@"latitude":self.customLatitude.text,@"longitude":self.customLongitude.text} forKey:@"customLocation"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (IBAction)optionA:(id)sender {
    [self.view endEditing:YES];
    alertA = [[UIAlertView alloc] initWithTitle:@"Option A"
                                          message:@"Initial GPS Location + Geofences (Regions)"
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertA show];
}

- (IBAction)optionB:(id)sender {
    [self.view endEditing:YES];
    alertB = [[UIAlertView alloc] initWithTitle:@"Option B"
                                        message:@"Initial GPS Location + Geofences (Regions) + GPS Verification"
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertB show];
}

- (IBAction)optionC:(id)sender {
    [self.view endEditing:YES];
    alertC = [[UIAlertView alloc] initWithTitle:@"Option C"
                                          message:@"Significant Change Location Service"
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertC show];
}

- (IBAction)optionD:(id)sender {
    [self.view endEditing:YES];
    alertD = [[UIAlertView alloc] initWithTitle:@"Option D"
                                          message:@"Standard Location Service"
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertD show];
}

- (IBAction)optionE:(id)sender {
    [self.view endEditing:YES];
    alertE = [[UIAlertView alloc] initWithTitle:@"Option E"
                                        message:@"Course Boundary @ 800 meters + GPS"
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:@"Cancel", nil];
    [alertE show];

}

- (IBAction)toRomeoville:(id)sender {
    
    alertRomeoville = [[UIAlertView alloc] initWithTitle:@"Romeoville"
                                        message:@""
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:@"Cancel", nil];
    [alertRomeoville show];
}

- (IBAction)toChicago:(id)sender {
    alertChicago = [[UIAlertView alloc] initWithTitle:@"Chicago"
                                        message:@""
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:@"Cancel", nil];
    [alertChicago show];
}

- (IBAction)toOakBrook:(id)sender {
    alertOakBrook = [[UIAlertView alloc] initWithTitle:@"Oak Brook"
                                        message:@""
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:@"Cancel", nil];
    [alertOakBrook show];
}

- (IBAction)set:(id)sender {
    setAlert = [[UIAlertView alloc] initWithTitle:@"ALL SET"
                                              message:@""
                                             delegate:self
                                    cancelButtonTitle:@"OK"
                                    otherButtonTitles:@"Cancel", nil];
    [setAlert show];
}
- (IBAction)enterCustomLocation:(id)sender {
    alertCustom = [[UIAlertView alloc] initWithTitle:self.customTitle.text
                                               message:@""
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:@"Cancel", nil];
    [alertCustom show];
}

-(void) clearCustom{
    self.customTitle.text = @"";
    self.customLatitude.text = @"";
    self.customLongitude.text = @"";
}
@end
