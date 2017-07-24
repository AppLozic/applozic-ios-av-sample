# applozic-ios-video-call-sample-code

Project contains Applozic.framework supporting Audio, Video call with sample in Objective C.

## Installation 

### Using cocoapods

Add below pod dependency:
```
  pod 'TwilioVideo', '~> 1.1.0'
  pod 'Applozic', '~> 3.9.1'
```
NOTE: Continue follwing integration steps and skip using framework step.
 
### Using Framework 

#### Installing lfs

i)  To fetch framowrk files(larger-file), you need to install lfs. You can install it by running below command:

```
brew install git-lfs 
```
ii)  You can verify installation was successful, by running below command on terminal.

```
git lfs install
```

iii) Once you complete checkout of sample-repo, go to project's root folder and run below command:

```
git lfs pull
```


##### 2) navigate to your Xcode project's General settings page and add Applozic.framework,Twillio.framework from [sample project root folder](https://github.com/AppLozic/applozic-ios-video-call-sample/tree/master/ALAudioVideo) as Embeded binaries.

#### 3) Add below libraries in Linked Frameworks and Libraries.

- AudioToolbox.framework
- VideoToolbox.framework
- AVFoundation.framework
- CoreTelephony.framework
- GLKit.framework
- CoreMedia.framework
- SystemConfiguration.framework
- libc++.tbd


## Integration Steps: 

#### 1) Add Audio/Video code to your project.
 - Copy paste [AudioVideo](https://github.com/AppLozic/applozic-ios-video-call-sample/tree/master/ALAudioVideo/ALAudioVideo/AudioVideo) folder from sample project and paste it into your root directory of your project. Go to Add Files to project, select all files present in Folder and add it to your project.

#### 2) Follow basic integration steps:
- After above steps, follow our documentaion page from steps 2) onward for integration:

https://www.applozic.com/docs/ios-chat-sdk.html#step-2-login-register-user


#### 3) Notification setup:

  Apart from basic notification setup done in [step 4](https://www.applozic.com/docs/ios-chat-sdk.html#step-4-push-notification-setup). Add below Pushkit delegates.

#### Objective-C
  
 ``` 
  //=====================================
#pragma mark : PUSHKIT DELEGATES
//=======================================
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
 ```

#### Swift

```
extension AppDelegate: PKPushRegistryDelegate {
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        let pushKitVOIP = PKPushRegistry(queue: DispatchQueue.main)
        pushKitVOIP.desiredPushTypes = Set<PKPushType>([PKPushType.voIP])
        pushKitVOIP.delegate = self
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, forType type: PKPushType) {
        NSLog("PUSHKIT : VOIP_TOKEN_DATA : %@",credentials.token.description)

        let hexToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        NSLog("PUSHKIT : VOIP_TOKEN : %@",hexToken)

        if let apnToken = ALUserDefaultsHandler.getApnDeviceToken(), apnToken == hexToken {
            return
        }
        NSLog("PUSHKIT : VOIP_TOKEN_UPDATE_CALL")

        let registerUserClientService = ALRegisterUserClientService()
        registerUserClientService.updateApnDeviceToken(withCompletion: hexToken, withCompletion: {
            response, error in
            if error != nil {
                NSLog("PUSHKIT : VOIP TOKEN : REGISTRATION ERROR :: %@", error.debugDescription)
                return
            }

            NSLog("PUSHKIT : VOIP_TOKEN_UPDATE : %@", response?.description ?? "")
        })
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenForType type: PKPushType) {
        NSLog("PUSHKIT : INVALID_PUSHKIT_TOKEN")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {
        NSLog("PUSHKIT : INCOMING VOIP NOTIFICATION : %@",payload.dictionaryPayload.description)

        let application = UIApplication.shared
        let pushNotificationService = ALPushNotificationService()
        pushNotificationService.notificationArrived(to: application, with: payload.dictionaryPayload)

        let payloadDict = payload.dictionaryPayload["aps"] as? [String: Any]
        let notifAlert = payloadDict?["alert"]
        let notifSound = payloadDict?["sound"]

        guard let alert = notifAlert as? String  else { return }

        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            let messageContent = alert.components(separatedBy: ":")

            content.title = messageContent.count > 0 ? messageContent[0]: alert
            if notifSound != nil {
                content.sound = UNNotificationSound.default()
            }

            content.body = messageContent.count > 1 ? messageContent[1]: alert
            content.userInfo = payload.dictionaryPayload
	    center.delegate = self
            let request = UNNotificationRequest(identifier: "VOIP_APNS", content: content, trigger: nil)
            center.add(request, withCompletionHandler: {
                error in
                if error == nil {
                    NSLog("PUSHKIT : Add NotificationRequest Succeeded!")
                }
            })
        } else {
            let localNotification = UILocalNotification()
            localNotification.alertBody = alert
            if notifSound != nil {
                localNotification.soundName = UILocalNotificationDefaultSoundName
            }

            localNotification.userInfo = payload.dictionaryPayload
            application.presentLocalNotificationNow(localNotification)
        }
    }
}
```

**NOTE: You need to upload VoIP Services Certificate in both development and distribution section on Applozic Dashboard**

#### 4) Add below setting in ALChatManger.m's in ALDefaultChatViewSettings.

    [ALApplozicSettings setAudioVideoClassName:@"ALAudioVideoCallVC"];
    [ALApplozicSettings setAudioVideoEnabled:YES];

    
