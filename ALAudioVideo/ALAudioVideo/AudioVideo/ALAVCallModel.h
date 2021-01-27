//
//  ALAVCallModel.h
//  ALAudioVideo
//
//  Created by Sunil on 14/12/20.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALAVCallModel : NSObject

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSUUID *callUUID;
@property (strong, nonatomic) NSString *roomId;
@property (nonatomic, strong) NSNumber *launchFor;
@property (strong, nonatomic) NSString *imageURL;
@property (strong, nonatomic) NSString *displayName;
@property (nonatomic) BOOL callForAudio;
@property (nonatomic) UIBackgroundTaskIdentifier unansweredCallBackgroundTaskId;
@property (nonatomic) BOOL unansweredCallTimerActive;
@property (nonatomic, strong) void(^unansweredHandlerCallBack)(ALAVCallModel*);
@property (strong, nonatomic) NSTimer *unansweredTimer;
@property (strong, nonatomic) NSNumber *startTime;

- (instancetype)initWithUserId:(NSString *)userId
                        roomId:(NSString *)roomId
                      callUUID:(NSUUID *)callUUID
                 launchForType:(NSNumber *)launchFor
                  callForAudio:(BOOL)audioCall
           withUserDisplayName:(NSString *)displayName
                  withImageURL:(NSString *)imageURL;

@end

NS_ASSUME_NONNULL_END
