//
//  NanoClock.h
//  McApp
//
//  Created by Booker Washington on 10/19/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#ifndef NanoClock_h
#define NanoClock_h

#endif /* NanoClock_h */

@protocol NanoClockDelegate;

@interface NanoClock : NSObject

-(void) setBPM:(double)value;
-(void) setMilliseconds:(double)value;
-(void) start;
-(void) stop;

@property (nonatomic, strong) id<NanoClockDelegate> delegate;

@end

@protocol NanoClockDelegate <NSObject>

-(void) timeKeeper;

@end