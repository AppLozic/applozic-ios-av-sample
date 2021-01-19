//
//  ALAudioVideoPushNotificationService.h
//  ALAudioVideo
//
//  Created by apple on 19/01/21.
//  Copyright © 2021 Adarsh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    AL_AUDIO_VIDEO_CALL_DIAL = 0,
} AL_AUDIO_VIDEO_SDK_PUSH_NOTIFICATION_TYPE;

extern NSString * const ALCallMessageTypeKey;
extern NSString * const ALCallerIDKey;
extern NSString * const ALCallAudioOnlyKey;

@interface ALAudioVideoPushNotificationService : NSObject
-(BOOL) isApplozicNotification:(NSDictionary *)userInfoDictionary;
-(BOOL) processPushNotification:(NSDictionary *)userInfoDictionary;

@end
