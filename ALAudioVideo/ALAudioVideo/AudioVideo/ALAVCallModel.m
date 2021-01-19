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

@end
