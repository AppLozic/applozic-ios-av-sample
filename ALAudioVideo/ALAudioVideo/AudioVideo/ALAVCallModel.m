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
                  callForAudio:(BOOL)audioCall {
    self = [super init];
    if (self) {
        self.userId = userId;
        self.roomId = roomId;
        self.callUUID = callUUID;
        self.launchFor = launchFor;
        self.callForAudio = audioCall;
    }
    return self;
}

@end
