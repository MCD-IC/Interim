//
//  nanoClock.m
//  McApp
//
//  Created by Booker Washington on 10/19/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "NanoClock.h"
#include <mach/mach_time.h>

@implementation NanoClock : NSObject

bool _running;
double tick;// tick is based on musical beats per minute. use setMilliseconds method to set based on time si units

- (id) init{
    self = [super init];
    if (self) {
        tick = 1;
        _running = false;
   }
    
    return self;
}

- (void)run {
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    
    uint64_t currentTime = mach_absolute_time();
    
    currentTime *= info.numer;
    currentTime /= info.denom;
    
    uint64_t interval = (1000 * 1000 * 1000 );
    uint64_t nextTime = currentTime + interval / tick;
    
    while (_running) {
        if (currentTime >= nextTime) {
            [self.delegate timeKeeper];
            
            nextTime += interval / tick;
        }
        
        currentTime = mach_absolute_time();
        currentTime *= info.numer;
        currentTime /= info.denom;
    }
}

-(void) setBPM : (double)bpm{
    tick = bpm / 60.0;
}

-(void) setMilliseconds : (double)ms{
    tick = 1000 / ms;
}

-(void) start{
    [NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
    _running = true;
}

-(void) stop{
    [NSThread exit];
    _running = false;
}


@end