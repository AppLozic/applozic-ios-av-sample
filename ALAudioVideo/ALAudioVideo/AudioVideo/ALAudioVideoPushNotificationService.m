//
//  ALAudioVideoPushNotificationService.m
//  ALAudioVideo
//
//  Created by Sunil on 19/01/21.
//  Copyright © 2021 Adarsh. All rights reserved.
//

#import "ALAudioVideoPushNotificationService.h"
#import <Applozic/Applozic.h>
#import "ALCallKitManager.h"

NSString * const ALCallMessageTypeKey = @"MSG_TYPE";
NSString * const ALCallerIDKey = @"CALL_ID";
NSString * const ALCallAudioOnlyKey = @"CALL_AUDIO_ONLY";

@implementation ALAudioVideoPushNotificationService

-(BOOL) isApplozicNotification:(NSDictionary *)userInfoDictionary {
    NSString *type = (NSString *)[userInfoDictionary valueForKey:@"AL_KEY"];
    if (!type.length) {
        return NO;
    }
    BOOL prefixCheck = ([type hasPrefix:APPLOZIC_PREFIX]) || ([type hasPrefix:@"MT_"]);
    return (type != nil && ([self.notificationTypes.allValues containsObject:type] || prefixCheck));
}

-(BOOL) processPushNotification:(NSDictionary *)userInfoDictionary {

    NSString *type = (NSString *)[userInfoDictionary valueForKey:@"AL_KEY"];

    if ([type isEqualToString:self.notificationTypes[@(AL_AUDIO_VIDEO_CALL_DIAL)]]) {
        NSString *alValueJson = (NSString *)[userInfoDictionary valueForKey:@"AL_VALUE"];
        NSData* data = [alValueJson dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

        if (error) {
            NSLog(@"ALAudioVideoPushNotificationService: Error in JSON converting to NSDictionary:%@",[error localizedDescription]);
            return NO;
        }
        NSString *notificationMsg = [messageDictionary valueForKey:@"message"];
        NSDictionary * metadataDictionary =  [messageDictionary valueForKey:@"messageMetaData"];
        NSArray *messagePartsArray = [notificationMsg componentsSeparatedByString:@":"];

        if (messagePartsArray.count > 1) {
            NSString *callerUserId = messagePartsArray[0];
            NSString *displayName = messagePartsArray[1];
            NSString *imageURL = nil;
            if (messagePartsArray.count > 2) {
                imageURL = messagePartsArray[2];
            }

            NSString *callId = metadataDictionary[ALCallerIDKey];
            NSString *isCallForAudio = metadataDictionary[ALCallAudioOnlyKey];

            NSString *messageType = metadataDictionary[ALCallMessageTypeKey];
            if ([messageType isEqualToString:AL_CALL_DIALED]) {
                NSArray *callIdPartsArray = [callId componentsSeparatedByString:@":"];
                if (callIdPartsArray.count > 1) {
                    NSString *UUIDString = callIdPartsArray[0];
                    NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
                    UIBackgroundTaskIdentifier identifer = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
                    ALCallKitManager * callkitManager = [ALCallKitManager sharedManager];
                    [callkitManager reportNewIncomingCall:UUID
                                               withUserId:callerUserId
                                         withCallForAudio:[isCallForAudio isEqual:@"true"]
                                               withRoomId:callId
                                            withLaunchFor:[NSNumber numberWithInt:AV_CALL_RECEIVED] withUserDisplayName:displayName
                                             withImageURL:imageURL];
                    [[UIApplication sharedApplication] endBackgroundTask:identifer];
                    return YES;
                }
            }
        }
    }
    return NO;
}

-(NSDictionary *)notificationTypes {
    static  NSDictionary * notificationTypesDictionary;
    if (!notificationTypesDictionary)
    {
        notificationTypesDictionary = @{@(AL_AUDIO_VIDEO_CALL_DIAL):@"APPLOZIC_40",
        };
    }
    return  notificationTypesDictionary;
}

@end
