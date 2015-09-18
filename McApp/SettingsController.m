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

- (IBAction)toRomeoville:(id)sender;
- (IBAction)toChicago:(id)sender;
- (IBAction)toOakBrook:(id)sender;


@property (strong, nonatomic) IBOutlet UITextField *proximity;
@property (strong, nonatomic) IBOutlet UILabel *beingMonitored;

@end

@implementation SettingsController{

UIAlertView *alertA;
UIAlertView *alertB;
UIAlertView *alertC;
UIAlertView *alertD;
    
UIAlertView *alertRomeoville;
UIAlertView *alertChicago;
UIAlertView *alertOakBrook;
    
IBOutlet UILabel *choosenOption;

NSDictionary *destination;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.

    choosenOption.text = self.option;
    NSLog(self.option);
    
    self.title = @"Settings";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //NSLog(@"Go");
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
    
    if(alertView == alertRomeoville){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            self.beingMonitored.text = @"Romeoville";
            destination = @{@"latitude":@"41.6721034", @"longitude":@"-88.0681658", @"radius":_proximity.text, @"title":@"Romeoville"};
        }
    }
    
    if(alertView == alertChicago){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            self.beingMonitored.text = @"Chicago";
            destination = @{@"latitude":@"41.8860837", @"longitude":@"-87.6321842", @"radius":_proximity.text, @"title":@"Chicago"};
        }
    }
    
    if(alertView == alertOakBrook){
        if (buttonIndex == 1) {
            NSLog(@"Cancel");
        }else{
            NSLog(@"OK");
            self.beingMonitored.text = @"Oak Brook";
            destination = @{@"latitude":@"41.8477231", @"longitude":@"-87.9476483", @"radius":_proximity.text, @"title":@"Oak Brook"};
        }
    }
}

- (IBAction)optionA:(id)sender {
    alertA = [[UIAlertView alloc] initWithTitle:@"Option A"
                                          message:@"Initial GPS Location + Geofences (Regions)"
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertA show];
}

- (IBAction)optionB:(id)sender {
    alertB = [[UIAlertView alloc] initWithTitle:@"Option B"
                                        message:@"Initial GPS Location + Geofences (Regions) + GPS Verification"
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertB show];
}

- (IBAction)optionC:(id)sender {
    alertC = [[UIAlertView alloc] initWithTitle:@"Option C"
                                          message:@"Initial GPS Location + Significant Change Location Service"
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertC show];
}

- (IBAction)optionD:(id)sender {
    alertD = [[UIAlertView alloc] initWithTitle:@"Option D"
                                          message:@"Standard Location Service"
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:@"Cancel", nil];
    [alertD show];
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
@end
