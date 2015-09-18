//
//  SettingsController.h
//  McApp
//
//  Created by Booker Washington on 9/14/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#import "ViewController.h"

@protocol SettingsControllerDelegate <NSObject>

@required

- (void)dataFromChoice:(NSString *)data;
- (void)dataFromDestination:(NSDictionary *)data;

@end

@interface SettingsController : ViewController

@property (nonatomic, retain) NSString *option;
@property (nonatomic, retain) NSString *currentProximity;

@property (nonatomic, weak) id<SettingsControllerDelegate> delegate;

@end
