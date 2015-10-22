//
//  AppDelegate.m
//  McApp
//
//  Created by Booker Washington on 7/14/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


UIBackgroundTaskIdentifier bgTask;
NSOperationQueue* operationQueue;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"\n\nGoing to resign!\n\n");
        
        [operationQueue waitUntilAllOperationsAreFinished];
        
        NSLog(@"\n\nTotally resigned!\n\n");
        [application endBackgroundTask: bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    
    NSLog(@"\n\nRunning in the background!\n\n");
    [self startBackgroundTask];

}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"\n\nIt's in the foreground\n\n");
    [self stopBackgroundTask];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)startBackgroundTask{
    [self stopBackgroundTask];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            //in case bg task is killed faster than expected, try to start Location Service
        
            [operationQueue waitUntilAllOperationsAreFinished];
            
            [[UIApplication sharedApplication] endBackgroundTask: bgTask];
            bgTask = UIBackgroundTaskInvalid;

            NSLog(@"in background");
        }];

    });
}

-(void)stopBackgroundTask{
    if(bgTask!=UIBackgroundTaskInvalid){
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        

    }
}

@end
