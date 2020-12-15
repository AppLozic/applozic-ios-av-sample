//
//  ALAudioVideoCallHandler.m
//  ALAudioVideo
//
//  Created by apple on 02/12/20.
//  Copyright © 2020 Adarsh. All rights reserved.
//

#import "ALAudioVideoCallHandler.h"
#import "Applozic/ALUtilityClass.h"
#import "ALCallKitManager.h"
#import "ALVOIPNotificationHandler.h"
@implementation ALAudioVideoCallHandler

static NSString *const ALDidSelectStartCallOption = @"ALDidSelectStartCallOption";

+(ALAudioVideoCallHandler *)shared
{
    static ALAudioVideoCallHandler * audioVideoCallHandler = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        audioVideoCallHandler = [[self alloc] init];
    });

    return audioVideoCallHandler;
}


-(void) dataConnectionNotificationHandler {

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSelectCallOptionHandler:)
                                                 name:ALDidSelectStartCallOption
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transferVOIPMessage:)
                                                 name:NEW_MESSAGE_NOTIFICATION
                                               object:nil];

}

-(void)onSelectCallOptionHandler:(NSNotification *) notfication {
    NSDictionary *callUserInfo = notfication.userInfo;

    if (!callUserInfo) {
        return;
    }

    NSString *callForUserId = [callUserInfo valueForKey:@"USER_ID"];
    NSNumber * isAudioCall = [callUserInfo valueForKey:@"CALL_FOR_AUDIO"];

    NSUUID * uuid = [NSUUID UUID];
    NSString * roomID =  [NSString stringWithFormat:@"%@:%@", uuid.UUIDString,
                          [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000]];
    ALCallKitManager * callkit = [ALCallKitManager sharedManager];
    [callkit perfromStartCallAction:uuid
                         withUserId:callForUserId
                   withCallForAudio:isAudioCall.boolValue
                         withRoomId:roomID
                      withLaunchFor:[NSNumber numberWithInt:AV_CALL_DIALLED]];

}

-(void)transferVOIPMessage:(NSNotification *)notification {
    NSMutableArray * messageArray = notification.object;
    ALVOIPNotificationHandler * voipHandler = [ALVOIPNotificationHandler sharedManager];
    ALPushAssist * assist = [[ALPushAssist alloc] init];
    for (ALMessage *msg in messageArray) {
        [voipHandler handleAVMsg:msg andViewController:assist.topViewController];
    }
}

@end
