//
//  ResultsController.m
//  McApp
//
//  Created by Booker Washington on 9/22/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#import "ResultsController.h"


@interface ResultsController ()

@property (strong, nonatomic) IBOutlet UILabel *autoTimeStampLabel;
@property (strong, nonatomic) IBOutlet UILabel *manualTimeStampLabel;
@property (strong, nonatomic) IBOutlet UILabel *batteryUsage;
@property (strong, nonatomic) IBOutlet UILabel *optionLevel;

@end

@implementation ResultsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Results";
    
    self.autoTimeStampLabel.text = self.autoTimeStamp;
    self.manualTimeStampLabel.text  = self.manualTimeStamp;
    self.batteryUsage.text  = self.batteryLevel;
    self.optionLevel.text  = self.option;
    NSLog(@"getting option");
    NSLog(self.option);
}

@end