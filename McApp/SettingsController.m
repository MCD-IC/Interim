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

@property (strong, nonatomic) IBOutlet UITextField *proximity;
@property (strong, nonatomic) IBOutlet UILabel *beingMonitored;

@property (strong, nonatomic) IBOutlet UILabel *distance1;
@property (strong, nonatomic) IBOutlet UILabel *distance2;

@property (strong, nonatomic) IBOutlet UISlider *secondSlider;
@property (strong, nonatomic) IBOutlet UISlider *fiveToTenSlider;

- (IBAction)timeSlider1:(id)sender;
- (IBAction)timeSlider5:(id)sender;

@end

@implementation SettingsController{
    
IBOutlet UILabel *choosenOption;
NSString *radius;
NSString *setTitle;
    
BOOL inSession;
int incrementation;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    choosenOption.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberOption"];
    self.title = @"Settings";
    self.proximity.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberRadius"];
    inSession = false;
    
    self.distance1.text = [NSString stringWithFormat:@"%@%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberDistance1"], @"m"];
    self.distance2.text = [NSString stringWithFormat:@"%@%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberDistance2"], @"m"];
   
    incrementation = 500;
    
    self.secondSlider.value = [[[NSUserDefaults standardUserDefaults] stringForKey:@"rememberDistance1"] intValue]/incrementation;
    self.fiveToTenSlider.value = [[[NSUserDefaults standardUserDefaults] stringForKey:@"rememberDistance2"] intValue]/incrementation;

    self.secondSlider.minimumValue = 1;
    self.secondSlider.maximumValue = 10000/incrementation;
    
    self.fiveToTenSlider.minimumValue = 1;
    self.fiveToTenSlider.maximumValue = 20000/incrementation;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

    [[NSUserDefaults standardUserDefaults] setObject:self.proximity.text forKey:@"rememberRadius"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [_delegate dataFromChoice: choosenOption.text];
    [_delegate dataFromDestination: [[NSUserDefaults standardUserDefaults] stringForKey:@"rememberRadius"]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

-(void) setOption :(NSString *)option{
    choosenOption.text = option;
    [[NSUserDefaults standardUserDefaults] setObject:option forKey:@"rememberOption"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)optionA:(id)sender {
    [self.view endEditing:YES];
    [self setOption: @"A"];
}

- (IBAction)optionB:(id)sender {
    [self.view endEditing:YES];
    [self setOption: @"B"];
}

- (IBAction)optionC:(id)sender {
    [self.view endEditing:YES];
    [self setOption: @"C"];
}

- (IBAction)optionD:(id)sender {
    [self.view endEditing:YES];
    [self setOption: @"D"];
}


- (IBAction)timeSlider1:(id)sender {
    self.distance1.text = [NSString stringWithFormat:@"%d%@", (int)self.secondSlider.value * incrementation, @"m"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", (int)self.secondSlider.value * incrementation] forKey:@"rememberDistance1"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)timeSlider5:(id)sender {
    self.distance2.text = [NSString stringWithFormat:@"%d%@", (int)self.fiveToTenSlider.value * incrementation, @"m"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", (int)self.fiveToTenSlider.value * incrementation]  forKey:@"rememberDistance2"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
