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

//@property (nonatomic, retain) NSMutableDictionary *autoTimeStamp;
//@property (nonatomic, retain) NSMutableDictionary *manualTimeStamp;
//@property (nonatomic, retain) NSMutableDictionary *gpsPing;
@property (nonatomic, retain) NSMutableDictionary *radii;

@property (nonatomic, retain) NSDictionary *sessionTime;

@property (nonatomic, retain) NSString *batteryUsed;
@property (nonatomic, retain) NSString *option;
@property (nonatomic, retain) NSString *location;

@property (nonatomic, retain) NSString *inSession;

@property (nonatomic, weak) id<ResultsControllerDelegate> delegate;

@end
