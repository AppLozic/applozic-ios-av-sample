//
//  ALAVCallModel.m
//  ALAudioVideo
//
//  Created by apple on 14/12/20.
//  Copyright © 2020 Adarsh. All rights reserved.
//

#import "ALAVCallModel.h"

@implementation ALAVCallModel

- (instancetype)initWithUserId:(NSString *)userId
                        roomId:(NSString *)roomId
                      callUUID:(NSUUID *)callUUID
                 launchForType:(NSNumber *)launchFor
                  callForAudio:(BOOL)audioCall
           withUserDisplayName:(nonnull NSString *)displayName
                  withImageURL:(nonnull NSString *)imageURL {
    self = [super init];
    if (self) {
        self.userId = userId;
        self.roomId = roomId;
        self.callUUID = callUUID;
        self.launchFor = launchFor;
        self.callForAudio = audioCall;
        self.displayName = displayName;
        self.imageURL = imageURL;
    }
    return self;
}

-(void)setUnansweredCallTimerActive:(BOOL)unansweredCallTimerActive {
    if (unansweredCallTimerActive) {
        self.unansweredCallBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        self.unansweredTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                                target:self
                                                              selector:@selector(callEndTimer:)
                                                              userInfo:nil
                                                               repeats:NO];
    } else {
        [self invalidateCallUnansweredNotifying];
    }
}

-(void)callEndTimer:(NSTimer *)timer {
    if (self.unansweredCallBackgroundTaskId != UIBackgroundTaskInvalid) {
        self.unansweredHandlerCallBack(self);
    }
    [self invalidateCallUnansweredNotifying];
}

-(void)invalidateCallUnansweredNotifying {
    if (self.unansweredTimer &&
        self.unansweredTimer.isValid) {
        [self.unansweredTimer invalidate];
    }

    if (self.unansweredCallBackgroundTaskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.unansweredCallBackgroundTaskId];
        self.unansweredCallBackgroundTaskId = UIBackgroundTaskInvalid;
    }
}

@end
