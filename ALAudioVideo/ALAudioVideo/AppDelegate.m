//
//  AppDelegate.m
//  ALAudioVideo
//
//  Created by Adarsh on 14/06/17.
//  Copyright © 2017 Adarsh. All rights reserved.
//

#import "AppDelegate.h"

#import <Applozic/Applozic.h>
#import "ApplozicLoginViewController.h"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    // checks wheather app version is updated/changed then makes server call setting VERSION_CODE
    [ALRegisterUserClientService isAppUpdated];

    [self registerForNotification];

    // Register for Applozic notification tap actions and network change notifications
    ALAppLocalNotifications *localNotification = [ALAppLocalNotifications appLocalNotificationHandler];
    [localNotification dataConnectionNotificationHandler];


    if ([ALUserDefaultsHandler isLoggedIn])
    {
        [ALPushNotificationService userSync];

        // Get login screen from storyboard and present it
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ApplozicLoginViewController *viewController = (ApplozicLoginViewController *)[storyboard instantiateViewControllerWithIdentifier:@"LaunchChatFromSimpleViewController"];

        [self.window makeKeyAndVisible];
        [self.window.rootViewController presentViewController:viewController animated:YES completion:nil];
    }

    // Override point for customization after application launch.
    NSLog(@"launchOptions: %@", launchOptions);
    if (launchOptions != nil) {
        NSDictionary *dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (dictionary != nil) {
            NSLog(@"Launched from push notification: %@", dictionary);
            ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
            BOOL applozicProcessed = [pushNotificationService processPushNotification:dictionary updateUI:[NSNumber numberWithInt:APP_STATE_INACTIVE]];

            //IF not a appplozic notification, process it
            if (!applozicProcessed) {
                //Note: notification for app
            }
        }
    }

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSLog(@"APP_ENTER_IN_BACKGROUND");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    NSLog(@"APP_ENTER_IN_FOREGROUND");
    [application setApplicationIconBadgeNumber:0];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[ALDBHandler sharedInstance] saveContext];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)
deviceToken {

    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

    NSString *apnDeviceToken = hexToken;
    NSLog(@"apnDeviceToken: %@", hexToken);

    if (![[ALUserDefaultsHandler getApnDeviceToken] isEqualToString:apnDeviceToken]) {
        ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
        [registerUserClientService updateApnDeviceTokenWithCompletion
         :apnDeviceToken withCompletion:^(ALRegistrationResponse
                                          *rResponse, NSError *error) {

            if (error) {
                NSLog(@"%@",error);
                return;
            }
            NSLog(@"Registration response%@", rResponse);
        }];
    }
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

-(void)registerForNotification
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error)
     {
        if(!error)
        {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [[UIApplication sharedApplication] registerForRemoteNotifications];  // required to get the app to do anything at all about push notifications
                NSLog(@"Push registration success." );
            });
        }
        else
        {
            NSLog(@"Push registration FAILED" );
            NSLog(@"ERROR: %@ - %@", error.localizedFailureReason, error.localizedDescription );
            NSLog(@"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion );
        }
    }];

}

//============================================================================================================================
#pragma mark : UNUserNotificationCenterDelegate : REMOTE NOTIFICATIONS
//============================================================================================================================

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification*)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService
                                                           alloc] init];
    NSDictionary *userInfo = notification.request.content.userInfo;

    if ([pushNotificationService isApplozicNotification:userInfo]) {
        [pushNotificationService notificationArrivedToApplication:[UIApplication sharedApplication] withDictionary:userInfo];
        completionHandler(UNNotificationPresentationOptionNone);
        return;
    }
    completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound);

}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse* )response withCompletionHandler:(nonnull void (^)(void))completionHandler {

    NSDictionary *userInfo =  response.notification.request.content.userInfo;

    if ([[userInfo valueForKey:@"AL_KEY"] isEqualToString:@"APPLOZIC_24"]) {
        NSLog(@"Test notification ");
        return;
    }
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService
                                                           alloc] init];
    if ([pushNotificationService isApplozicNotification:userInfo]) {
        [pushNotificationService notificationArrivedToApplication:[UIApplication sharedApplication] withDictionary:userInfo];

        NSDictionary *payloadDict = [userInfo objectForKey:@"aps"];
        NSString * alert = [payloadDict objectForKey:@"alert"];
        NSString * sound = [payloadDict objectForKey:@"sound"];

        if (alert)
        {
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            NSArray * msgContent = [alert componentsSeparatedByString:@":"];
            content.title = [NSString localizedUserNotificationStringForKey:(msgContent[0] ? msgContent[0] : alert) arguments:nil];
            content.body = [NSString localizedUserNotificationStringForKey:(msgContent[1] ? msgContent[1] : alert) arguments:nil];
            content.userInfo = userInfo;
            if (sound)
            {
                content.sound = [UNNotificationSound defaultSound];
            }

            UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:@"VOIP_APNS" content:content trigger:nil];
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            center.delegate = self;
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"Add NotificationRequest Succeeded!");
                }
            }];
        }
        completionHandler();
        return;
    }
    completionHandler();
}

@end
