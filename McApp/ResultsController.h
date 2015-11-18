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

@property (nonatomic, retain) NSMutableDictionary *autoTimeStamp;
@property (nonatomic, retain) NSMutableDictionary *manualTimeStamp;
@property (nonatomic, retain) NSMutableDictionary *sessionTime;

@property (nonatomic, retain) NSString *batteryUsed;
@property (nonatomic, retain) NSString *options;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *numOfStores;
@property (nonatomic, retain) NSDictionary *startLocation;

@property (nonatomic, strong) id<ResultsControllerDelegate> delegate;

@end
