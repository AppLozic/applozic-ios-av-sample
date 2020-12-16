//
//  ALVOIPNotificationHandler.m
//  Applozic
//
//  Created by Abhishek Thapliyal on 1/13/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import "ALVOIPNotificationHandler.h"
#import "ALCallKitManager.h"

@implementation ALVOIPNotificationHandler
{
    UIApplication *appObject;
}

+(instancetype)sharedManager
{
    static ALVOIPNotificationHandler *sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

-(id)init
{
    if (self = [super init])
    {
        
    }
    return self;
}

//==============================================================================================================================================
#pragma mark - LAUNCH AUDIO/VIDEO VC
//==============================================================================================================================================

-(void)launchAVViewController:(NSString *)userID andLaunchFor:(NSNumber *)type
                     orRoomId:(NSString *)roomId andCallAudio:(BOOL)flag andViewController:(UIViewController *)viewSelf
{
    NSArray *parts = [roomId componentsSeparatedByString:@":"];
    if (parts.count > 1) {
        NSString *uuIDString = parts[0];
        NSUUID * uuid = [[NSUUID alloc] initWithUUIDString:uuIDString];
        ALCallKitManager * callkitManager = [ALCallKitManager sharedManager];
        [callkitManager reportNewIncomingCall:uuid
                                   withUserId:userID
                             withCallForAudio:flag
                                   withRoomId:roomId
                                withLaunchFor:type];
    }
}

//==============================================================================================================================
#pragma mark - SEND AUDIO/VIDEO MESSAGE WITH META DATA
//==============================================================================================================================

+(void)sendMessageWithMetaData:(NSMutableDictionary *)dictionary
                 andReceiverId:(NSString *)userId
                andContentType:(short)contentType
                    andMsgText:(NSString *)msgText
                withCompletion:(void(^)(NSError * error)) completion {
    
    ALMessage * messageWithMetaData = [ALMessageService createMessageWithMetaData:dictionary
                                                                   andContentType:contentType
                                                                    andReceiverId:userId
                                                                   andMessageText:msgText];
    
    [[ALMessageService sharedInstance] sendMessages:messageWithMetaData withCompletion:^(NSString *message, NSError *error) {
        
        ALSLog(ALLoggerSeverityInfo, @"AUDIO/VIDEO MSG_RESPONSE :: %@",message);
        ALSLog(ALLoggerSeverityError, @"ERROR IN AUDIO/VIDEO MESSAGE WITH META-DATA : %@", error);
        completion(error);
    }];
}

+(NSMutableDictionary *)getMetaData:(NSString *)msgType
                       andCallAudio:(BOOL)flag
                          andRoomId:(NSString *)metaRoomID {
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:msgType forKey:@"MSG_TYPE"];
    [dict setObject:metaRoomID forKey:@"CALL_ID"];
    [dict setObject:flag ? @"true": @"false" forKey:@"CALL_AUDIO_ONLY"];
    
    return dict;
}

-(void)handleAVMsg:(ALMessage *)alMessage andViewController:(UIViewController *)viewSelf
{
    appObject = [UIApplication sharedApplication];
    self.presenterVC = viewSelf;

    if (alMessage.contentType == AV_CALL_CONTENT_TWO)
    {
        if(![ALApplozicSettings isAudioVideoEnabled] )
        {
            ALSLog(ALLoggerSeverityInfo, @" video/audio call not enables  ");
            return;
        }

        NSString *msgType = (NSString *)[alMessage.metadata objectForKey:@"MSG_TYPE"];
        BOOL isAudio = [[alMessage.metadata objectForKey:@"CALL_AUDIO_ONLY"] boolValue];
        NSString *roomId = (NSString *)[alMessage.metadata objectForKey:@"CALL_ID"];

        if([msgType isEqualToString:@"CALL_DIALED"])
        {
            if ([alMessage.type isEqualToString:@"5"] || [self isNotificationStale:alMessage])
            {
                return;
            }

            // TODO: Remove this later keeping this for testing the Call kit with notification for forground. Once we add support on server backend for new notification and on device we will remove this code and handle the new notification from VOIP notification delegate callback for CALL_DIALED.

            ALVOIPNotificationHandler *voipHandler = [ALVOIPNotificationHandler sharedManager];
            [voipHandler launchAVViewController:alMessage.to
                                   andLaunchFor:[NSNumber numberWithInt:AV_CALL_RECEIVED]
                                       orRoomId:roomId
                                   andCallAudio:isAudio
                              andViewController:viewSelf];
        }
        else if ([msgType isEqualToString:@"CALL_ANSWERED"])
        {
            // MULTI_DEVICE (WHEN RECEIVER CALL_ANSWERED FROM ANOTHER DEVICE)
            // STOP RINGING AND DISMISSVIEW : CHECK INCOMING CALL_ID and CALL_ID OF OPEPENED VIEW
            if ([alMessage.type isEqualToString:@"5"]) {
                ALCallKitManager *callkit = [ALCallKitManager sharedManager];
                NSArray *parts = [roomId componentsSeparatedByString:@":"];
                if (parts.count > 1) {
                    NSString *uuidString = parts[0];
                    NSUUID * uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
                    [callkit endActiveCallVCWithCallReason:CXCallEndedReasonAnsweredElsewhere withRoomID:roomId withCallUUID:uuid];
                }
            }
        }
        else if ([msgType isEqualToString:@"CALL_REJECTED"])
        {
            // MULTI_DEVICE (WHEN RECEIVER CUTS FROM ANOTHER DEVICE)
            // STOP RINGING AND DISMISSVIEW : CHECK INCOMING CALL_ID and CALL_ID OF OPEPENED VIEW

            NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:@"CALL_REJECTED"
                                                                         andCallAudio:isAudio
                                                                            andRoomId:roomId];

            ALSLog(ALLoggerSeverityInfo, @"CALL_IS_REJECTED");
            [ALNotificationView showNotification:@"Participant Busy"];

            ALCallKitManager *callkit = [ALCallKitManager sharedManager];

            if (callkit.activeCallModel && [callkit.activeCallModel.roomId isEqualToString:roomId]) {
                [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                                     andReceiverId:alMessage.to
                                                    andContentType:AV_CALL_CONTENT_THREE
                                                        andMsgText:roomId withCompletion:^(NSError *error) {
                }];
            }

            NSArray *parts = [roomId componentsSeparatedByString:@":"];
            if (parts.count > 1) {
                NSString *uuidString = parts[0];
                NSUUID * uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
                [callkit endActiveCallVCWithCallReason:CXCallEndedReasonDeclinedElsewhere withRoomID:roomId withCallUUID:uuid];
            }
        }
        else if ([msgType isEqualToString:@"CALL_MISSED"])
        {
            ALSLog(ALLoggerSeverityInfo, @"CALL_IS_MISSED");
            ALCallKitManager *callkit = [ALCallKitManager sharedManager];
            NSArray *parts = [roomId componentsSeparatedByString:@":"];
            if (parts.count > 1) {
                NSString *uuidString = parts[0];
                NSUUID * uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
                [callkit endActiveCallVCWithCallReason:CXCallEndedReasonRemoteEnded withRoomID:roomId withCallUUID:uuid];
            }
        } else if ([msgType isEqualToString:@"CALL_END"]) {
            ALCallKitManager *callkit = [ALCallKitManager sharedManager];
            NSArray *parts = [roomId componentsSeparatedByString:@":"];
            if (parts.count > 1) {
                NSString *uuidString = parts[0];
                NSUUID * uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
                [callkit endActiveCallVCWithCallReason:CXCallEndedReasonRemoteEnded withRoomID:roomId withCallUUID:uuid];
            }
        }
    }
}

-(BOOL)isNotificationStale:(ALMessage*)alMessage
{
    ALSLog(ALLoggerSeverityInfo, @"[[NSDate date]timeIntervalSince1970] - [alMessage.createdAtTime doubleValue] ::%f", [[NSDate date]timeIntervalSince1970]*1000 - [alMessage.createdAtTime doubleValue]);
    return ( ([[NSDate date] timeIntervalSince1970] - [alMessage.createdAtTime doubleValue]/1000) > 30);
}

@end
