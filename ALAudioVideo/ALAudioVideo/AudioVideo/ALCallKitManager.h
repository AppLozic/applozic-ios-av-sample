#import <Foundation/Foundation.h>
#import <Applozic/Applozic.h>
#import <Applozic/ALMessage.h>
#import "ALAudioVideoCallVC.h"
#import "ALVOIPNotificationHandler.h"
#import "ALAVCallModel.h"

@import CallKit;

@interface ALCallKitManager : NSObject <CXProviderDelegate>
@property (nonatomic, strong) CXProvider *callKitProvider;
@property (nonatomic, strong) CXCallController *callKitCallController;
@property (strong, nonatomic) NSMutableDictionary<NSString *, ALAVCallModel *> *callListModels;
@property (strong, nonatomic) ALAVCallModel *activeCallModel;
@property (strong, nonatomic) ALAudioVideoCallVC *activeCallViewController;
@property (strong, nonatomic) TVIDefaultAudioDevice *audioDevice;

+ (ALCallKitManager *)sharedManager;

// Report new call receieved
- (void)reportNewIncomingCall:(NSUUID *)callUUID
                   withUserId:(NSString *)userId
             withCallForAudio:(BOOL)callForAudio
                   withRoomId:(NSString *)roomId
                withLaunchFor:(NSNumber *)launchFor;

// Start call
-(void)perfromStartCallAction:(NSUUID *)callUUID
                   withUserId:(NSString *)userId
             withCallForAudio:(BOOL)callForAudio
                   withRoomId:(NSString *)roomId
                withLaunchFor:(NSNumber *)launchFor;

// Report that an outgoing call connected.
-(void) reportOutgoingCall:(NSUUID *)callUUID;

// Report end call with reason.
-(void) reportOutgoingCall:(NSUUID *)callUUID withCXCallEndedReason:(CXCallEndedReason) reason;

// End call
-(void)performEndCallAction:(NSUUID *)callUUID
             withCompletion:(void(^)(NSError *error))completion;

// Send end call with model
-(void)sendEndCallWithCallModel:(ALAVCallModel *)callModel
                 withCompletion:(void(^)(NSError * error))completion;

// End the active call view controller and report to callKit Provider
-(void)endActiveCallVCWithCallReason:(CXCallEndedReason)reason
                          withRoomID:(NSString *)roomId
                        withCallUUID:(NSUUID *)callUUID;
// Audio output
- (void)setAudioOutputSpeaker:(BOOL)enabled;

- (void)clear;
@end

