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

@property (nonatomic, strong) UIViewController *presenterVC;

+(instancetype)sharedManager;

-(void)launchAVViewController:(NSString *)userID
                 andLaunchFor:(NSNumber *)type
                     orRoomId:(NSString *)roomId
                 andCallAudio:(BOOL)flag
            andViewController:(UIViewController *)viewSelf;

+(void)sendMessageWithMetaData:(NSMutableDictionary *)dictionary
                 andReceiverId:(NSString *)userId
                andContentType:(short)contentType
                    andMsgText:(NSString *)msgText
                withCompletion:(void(^)(NSError * error)) completion;

+(NSMutableDictionary *)getMetaData:(NSString *)msgType
                       andCallAudio:(BOOL)flag
                          andRoomId:(NSString *)metaRoomID;

-(void)handleAVMsg:(ALMessage *)alMessage andViewController:(UIViewController *)viewSelf;


@end
