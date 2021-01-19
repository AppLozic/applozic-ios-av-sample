//
//  ALVOIPNotificationHandler.h
//  Applozic
//
//  Created by Abhishek Thapliyal on 1/13/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALAudioVideoCallVC.h"
#import <Applozic/Applozic.h>

@interface ALVOIPNotificationHandler : NSObject

+(instancetype)sharedManager;

+(void)sendMessageWithMetaData:(NSMutableDictionary *)dictionary
                 andReceiverId:(NSString *)userId
                andContentType:(short)contentType
                    andMsgText:(NSString *)msgText
                withCompletion:(void(^)(NSError * error)) completion;

+(NSMutableDictionary *)getMetaData:(NSString *)msgType
                       andCallAudio:(BOOL)flag
                          andRoomId:(NSString *)metaRoomID;

-(void)handleAVMsg:(ALMessage *)alMessage;


@end
