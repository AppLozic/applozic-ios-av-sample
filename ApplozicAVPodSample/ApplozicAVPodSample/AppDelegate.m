//
//  AppDelegate.m
//  ALAudioVideo
//
//  Created by Adarsh on 14/06/17.
//  Copyright © 2017 Adarsh. All rights reserved.
//

#import "AppDelegate.h"

#import <Applozic/ALUserDefaultsHandler.h>
#import <Applozic/ALRegisterUserClientService.h>
#import <Applozic/ALPushNotificationService.h>
#import <Applozic/ALUtilityClass.h>
#import "ApplozicLoginViewController.h"
#import "Applozic/ALDBHandler.h"
#import "Applozic/ALMessagesViewController.h"
#import "Applozic/ALPushAssist.h"
#import "Applozic/ALMessageService.h"
#import "Applozic/ALAppLocalNotifications.h"

#import <UserNotifications/UserNotifications.h>
#import <PushKit/PushKit.h>


#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)


@interface AppDelegate () <UNUserNotificationCenterDelegate, PKPushRegistryDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [self registerForNotification];
    // check wheather app version is updated/changed then makes server call setting VERSION_CODE
    [ALRegisterUserClientService isAppUpdated];
    
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
    
    NSLog(@"launchOptions: %@", launchOptions);
    
    if (launchOptions != nil)
    {
        NSDictionary *dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (dictionary != nil)
        {
            NSLog(@"Launched from push notification: %@", dictionary);
            ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
            BOOL applozicProcessed = [pushNotificationService processPushNotification:dictionary
                                                                             updateUI:[NSNumber numberWithInt:APP_STATE_INACTIVE]];
            
            if (!applozicProcessed) {
                //Note: notification for app
            }
        }
        
        
        UILocalNotification *launchNote = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        if (launchNote){
            
            NSLog(@"LAUNCH_OPTIONS : RECEIVED NOTITIFICATION WHEN APP IS NOT RUNNING");
        }
        
    }
    
    return YES;
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)dictionary {
    
    NSLog(@"RECEIVED_NOTIFICATION :: %@", dictionary);
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
    [pushNotificationService notificationArrivedToApplication:application withDictionary:dictionary];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler{
    
    NSLog(@"RECEIVED_NOTIFICATION_WITH_COMPLETION :: %@", userInfo);
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
    [pushNotificationService notificationArrivedToApplication:application withDictionary:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSLog(@"APP_ENTER_IN_BACKGROUND");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"APP_ENTER_IN_BACKGROUND" object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [ALPushNotificationService applicationEntersForeground];
    
    NSLog(@"APP_ENTER_IN_FOREGROUND");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"APP_ENTER_IN_FOREGROUND" object:nil];
    [application setApplicationIconBadgeNumber:0];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[ALDBHandler sharedInstance] saveContext];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"DEVICE_TOKEN :: %@", deviceToken);
    
    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    NSString *apnDeviceToken = hexToken;
    
    NSLog(@"APN_DEVICE_TOKEN :: %@", hexToken);
    
    if ([[ALUserDefaultsHandler getApnDeviceToken] isEqualToString:apnDeviceToken])
    {
        return;
    }
    
    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService updateApnDeviceTokenWithCompletion:apnDeviceToken withCompletion:^(ALRegistrationResponse *rResponse, NSError *error) {
        
        if (error)
        {
            NSLog(@"REGISTRATION ERROR :: %@",error.description);
            return;
        }
        
        NSLog(@"Registration response from server : %@", rResponse);
    }];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

-(void)registerForNotification
{
    
    UIUserNotificationSettings * APNSetting = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:APNSetting];
    
}



//============================================================================================================================
#pragma mark : UNUserNotificationCenterDelegate : REMOTE NOTIFICATIONS
//============================================================================================================================
/*
 "Use UserNotifications Framework's -[UNUserNotificationCenterDelegate willPresentNotification:withCompletionHandler:]
 or -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:] for user visible notifications
 and -[UIApplicationDelegate application:didReceiveRemoteNotification:fetchCompletionHandler:] for silent remote notifications"
 
 */

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    // The method will be called on the delegate only if the application is in the foreground.
    // If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented.
    // The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list.
    // This decision should be based on whether the information in the notification is otherwise visible to the user.
    
    NSLog(@"APPDELEGATE : WILL_PRESENT_NOTIFICATION");
    UIApplication * application = [UIApplication sharedApplication];
    UNNotificationContent * content = notification.request.content;
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
    [pushNotificationService notificationArrivedToApplication:application withDictionary:content.userInfo];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)())completionHandler {
    // The method will be called on the delegate when the user responded to the notification by opening the application,
    // dismissing the notification or choosing a UNNotificationAction.
    // The delegate must be set before the application returns from applicationDidFinishLaunching:.
    
    NSLog(@"APPDELEGATE : DID_RECEIVE_NOTIFICATION_RESPONSE");
    UIApplication * application = [UIApplication sharedApplication];
    UNNotificationContent * content = response.notification.request.content;
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
    [pushNotificationService notificationArrivedToApplication:application withDictionary:content.userInfo];
}

//====================================================================================================================================
#pragma mark : UILOCALNOTIFICATION DELEGATES
//====================================================================================================================================

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
    NSLog(@"DID_RECEIVE_LOCAL_NOTIFICATION"); //  CALLED if this is NOT SET center.delegate = self;
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
    [pushNotificationService notificationArrivedToApplication:application withDictionary:notification.userInfo];
}

//====================================================================================================================================
#pragma mark : PUSHKIT DELEGATES
//====================================================================================================================================

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(nonnull UIUserNotificationSettings *)notificationSettings {
    
    PKPushRegistry * pushKitVOIP = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushKitVOIP.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    pushKitVOIP.delegate = self;
}

-(void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type {
    
    NSLog(@"PUSHKIT : VOIP_TOKEN_DATA : %@",credentials.token);
    const unsigned *tokenBytes = [credentials.token bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    NSLog(@"PUSHKIT : VOIP_TOKEN : %@",hexToken);
    if ([[ALUserDefaultsHandler getApnDeviceToken] isEqualToString:hexToken])
    {
        return;
    }
    
    NSLog(@"PUSHKIT : VOIP_TOKEN_UPDATE_CALL");
    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService updateApnDeviceTokenWithCompletion:hexToken withCompletion:^(ALRegistrationResponse *rResponse, NSError *error) {
        
        if (error)
        {
            NSLog(@"PUSHKIT : VOIP TOKEN : REGISTRATION ERROR :: %@",error.description);
            return;
        }
        
        NSLog(@"PUSHKIT : VOIP_TOKEN_UPDATE : %@", rResponse);
    }];
}

-(void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
    
    NSLog(@"PUSHKIT : INVALID_PUSHKIT_TOKEN");
}

-(void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type {
    
    NSLog(@"PUSHKIT : INCOMING VOIP NOTIFICATION : %@",payload.dictionaryPayload.description);
    
    UIApplication * application = [UIApplication sharedApplication];
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
    [pushNotificationService notificationArrivedToApplication:application withDictionary:[payload dictionaryPayload]];
    
    NSDictionary *payloadDict = [[payload dictionaryPayload] objectForKey:@"aps"];
    NSString * alert = [payloadDict objectForKey:@"alert"];
    NSString * sound = [payloadDict objectForKey:@"sound"];
    
    if (alert)
    {
        if(SYSTEM_VERSION_LESS_THAN(@"10.0"))
        {
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertBody = alert;
            if (sound)
            {
                localNotification.soundName = UILocalNotificationDefaultSoundName;
            }
            localNotification.userInfo = [payload dictionaryPayload];
            [application presentLocalNotificationNow:localNotification];
        }
        else
        {
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            NSArray * msgContent = [alert componentsSeparatedByString:@":"];
            content.title = [NSString localizedUserNotificationStringForKey:(msgContent[0] ? msgContent[0] : alert) arguments:nil];
            content.body = [NSString localizedUserNotificationStringForKey:(msgContent[1] ? msgContent[1] : alert) arguments:nil];
            content.userInfo = [payload dictionaryPayload];
            if (sound)
            {
                content.sound = [UNNotificationSound defaultSound];
            }
            
            UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:@"VOIP_APNS" content:content trigger:nil];
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            center.delegate = self;
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"PUSHKIT : Add NotificationRequest Succeeded!");
                }
            }];
        }
    }
}

@end
