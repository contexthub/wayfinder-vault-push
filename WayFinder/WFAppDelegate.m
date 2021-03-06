//
//  WFAppDelegate.m
//  WayFinder
//
//  Created by Anuradha Ramprakash on 3/28/14.
//  Copyright (c) 2014 ChaiONE. All rights reserved.
//

#import "WFAppDelegate.h"

@implementation WFAppDelegate

+ (WFAppDelegate *) sharedAppDelegate {
    return (WFAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // Register for remote notifications
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeNewsstandContentAvailability ];
    
    // Setup ContextHub App ID, CCHSensorPipeline datasource and delegate, and tags
    [self setupContextHub];
    
    // Set default number of times visited
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"timesVisited":@0}];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - ContextHub

- (void)setupContextHub {
    // Debug flag is very important so that pushes are sent to the correct gateway during development
#ifdef DEBUG
    [[ContextHub sharedInstance] setDebug:TRUE];
#endif
    
    // Initialize ContextHub with our app ID
    [ContextHub registerWithAppId:@"YOUR-APP-ID"];
    
    [[CCHSensorPipeline sharedInstance] setDelegate:self];
    [[CCHSensorPipeline sharedInstance] setDataSource:self];
    
    // Subscribe to "beacon-wayfinder" beacon tag
    if ([[CCHSensorPipeline sharedInstance] addSubscriptionForTags:@[WFBeaconTag]]) {
        NSLog(@"Successfully added subscription to \"%@\" tag", WFBeaconTag);
    } else {
        NSLog(@"Failed to add subscription to \"%@\" tag", WFBeaconTag);
    }
}

#pragma mark - Sensor Pipeline Delegate

- (BOOL)sensorPipeline:(CCHSensorPipeline *)sensorPipeline shouldPostEvent:(NSDictionary *)event {
    // If you'd like to keep events from hitting the server, you can return NO here.
    // This is a good spot to filter events.
    NSLog(@"Should post event?");
    return YES;
}

- (void)sensorPipeline:(CCHSensorPipeline *)sensorPipeline willPostEvent:(NSDictionary *)event {
    // If you want to access event data directl before it will be posted to the server, you can do that here
    NSLog(@"Will post event: %@", event);
}

- (void)sensorPipeline:(CCHSensorPipeline *)sensorPipeline didPostEvent:(NSDictionary *)event {
    // If you want to access event data directly after it has been posted to the server, you can do that here
    NSLog(@"Did post event: %@", event);
}

#pragma mark - Sensor Pipeline Data Source

- (NSDictionary*)sensorPipeline:(CCHSensorPipeline *)sensorPipeline payloadForEvent:(NSDictionary *)event {
    // Add custom data structures to the events, and they will end up on the server.
    return @{};
}

#pragma mark - Remote Notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Set up the alias, tag, and register for push notifications on the server
    [[CCHPush sharedInstance] registerDeviceToken:deviceToken alias:[[UIDevice currentDevice] name] tags:@[WFDeviceTag] completionHandler:^(NSError *error) {
        if (!error) {
            NSLog(@"Successfully registered device with alias %@ and tags %@", [[UIDevice currentDevice] name], WFDeviceTag);
        }
        else {
            NSLog(@"Error: %@", error);
        }
    }];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Did fail to register %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    // Define our fetch completion handler which is called by ContextHub if the push wasn't a push for CCHSubscriptionService
     void (^fetchCompletionHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult result){
        NSLog(@"Push Received %@", userInfo);
        NSString *message = [userInfo valueForKeyPath:@"aps.alert"];
        
        // Pop an alert about our message
        [[[UIAlertView alloc] initWithTitle:@"ContextHub" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
        
        // This push resulted in no new background data
        completionHandler(UIBackgroundFetchResultNoData);
    };
    
    // Let ContextHub process the push
    [[CCHPush sharedInstance] application:application didReceiveRemoteNotification:userInfo completionHandler:fetchCompletionHandler];
}

@end
