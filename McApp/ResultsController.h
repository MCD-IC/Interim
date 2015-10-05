//
//  ResultsController.h
//  McApp
//
//  Created by Booker Washington on 9/22/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#import "ViewController.h"

@protocol ResultsControllerDelegate <NSObject>

@required



@end

@interface ResultsController : ViewController

@property (nonatomic, retain) NSString *autoTimeStamp;
@property (nonatomic, retain) NSString *manualTimeStamp;
@property (nonatomic, retain) NSString *batteryLevel;
@property (nonatomic, retain) NSString *option;
@property (nonatomic, retain) NSString *gpsTimeStamp;
@property (nonatomic, retain) NSString *inSession;

@property (nonatomic, weak) id<ResultsControllerDelegate> delegate;

@end
