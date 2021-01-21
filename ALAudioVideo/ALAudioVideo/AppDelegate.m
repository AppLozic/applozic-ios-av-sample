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
#import "ALAudioVideoCallHandler.h"
#import <PushKit/PushKit.h>
#import "ALAudioVideoPushNotificationService.h"

@interface AppDelegate () <UNUserNotificationCenterDelegate, PKPushRegistryDelegate>

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
    [[ALAudioVideoCallHandler shared] dataConnectionNotificationHandler];

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

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"DEVICE_TOKEN :: %@", deviceToken);

    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

    NSString *apnDeviceToken = hexToken;
    NSLog(@"APN_DEVICE_TOKEN :: %@", hexToken);

    if ([[ALUserDefaultsHandler getApnDeviceToken] isEqualToString:apnDeviceToken]) {
        return;
    }

    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService updateAPNsOrVOIPDeviceToken:apnDeviceToken
                                          withApnTokenFlag:YES withCompletion:^(ALRegistrationResponse *response, NSError *error) {

    }];
}

-(void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type {

    NSLog(@"PUSHKIT : VOIP_TOKEN_DATA : %@",credentials.token);
    const unsigned *tokenBytes = [credentials.token bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

    NSLog(@"PUSHKIT : VOIP_TOKEN : %@",hexToken);
    if ([[ALUserDefaultsHandler getVOIPDeviceToken] isEqualToString:hexToken]) {
        return;
    }

    NSLog(@"PUSHKIT : VOIP_TOKEN_UPDATE_CALL");
    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService updateAPNsOrVOIPDeviceToken:hexToken
                                          withApnTokenFlag:NO withCompletion:^(ALRegistrationResponse *response, NSError *error) {

    }];
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
                /// Push kit Registry
                PKPushRegistry * pushKitVOIP = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
                pushKitVOIP.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
                pushKitVOIP.delegate = self;
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

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler{

    NSLog(@"RECEIVED_NOTIFICATION_WITH_COMPLETION :: %@", userInfo);
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
    if ([pushNotificationService isApplozicNotification:userInfo]) {
        [pushNotificationService notificationArrivedToApplication:application withDictionary:userInfo];
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

//============================================================================================================================
#pragma mark : UNUserNotificationCenterDelegate : REMOTE NOTIFICATIONS
//============================================================================================================================

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification*)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService
                                                           alloc] init];
    NSDictionary *userInfo = notification.request.content.userInfo;
    NSLog(@"APNS willPresentNotification for userInfo: %@",userInfo);

    if ([pushNotificationService isApplozicNotification:userInfo]) {
        [pushNotificationService notificationArrivedToApplication:[UIApplication sharedApplication] withDictionary:userInfo];
        completionHandler(UNNotificationPresentationOptionNone);
        return;
    }
    completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse* )response withCompletionHandler:(nonnull void (^)(void))completionHandler {


    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService
                                                           alloc] init];
    NSDictionary *userInfo =  response.notification.request.content.userInfo;
    NSLog(@"APNS didReceiveNotificationResponse for userInfo: %@",userInfo);

    if ([pushNotificationService isApplozicNotification:userInfo]) {
        [pushNotificationService notificationArrivedToApplication:[UIApplication sharedApplication] withDictionary:userInfo];
        completionHandler();
        return;
    }
    completionHandler();
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void(^)(void))completion {

    NSLog(@"PUSHKIT : INCOMING VOIP NOTIFICATION : %@",payload.dictionaryPayload.description);

    ALAudioVideoPushNotificationService *pushNotificationService = [[ALAudioVideoPushNotificationService
                                                                     alloc] init];
    NSDictionary * userInfoPayload = payload.dictionaryPayload;
    if ([pushNotificationService isApplozicNotification:userInfoPayload]) {
        [pushNotificationService processPushNotification:userInfoPayload];
        completion();
    }
}

@end
