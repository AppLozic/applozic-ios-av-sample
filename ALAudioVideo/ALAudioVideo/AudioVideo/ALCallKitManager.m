#import "ALCallKitManager.h"
#import "Applozic/ALContactDBService.h"
#import "ALAudioVideoCallVC.h"

@implementation ALCallKitManager

+ (ALCallKitManager *)sharedManager {
    static ALCallKitManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        CXProviderConfiguration *configuration;
        if (@available(iOS 14.0, *)) {
            configuration = [[CXProviderConfiguration alloc] init];
        } else {
            configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:NSLocalizedStringWithDefaultValue(@"appName", nil, [NSBundle mainBundle], @"Applozic", @"")];
        }
        configuration.supportsVideo = YES;
        configuration.maximumCallGroups = 1;
        configuration.maximumCallsPerCallGroup = 1;
        configuration.ringtoneSound = @"Marimba.m4r";
        configuration.supportedHandleTypes = [[NSSet alloc] initWithObjects:[NSNumber numberWithInt:(int)CXHandleTypeGeneric], nil];
        self.callKitProvider = [[CXProvider alloc] initWithConfiguration:configuration];
        [self.callKitProvider setDelegate:self queue:nil];
        self.callKitCallController = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
        self.callListModels = [[NSMutableDictionary alloc] init];
        self.audioDevice = [TVIDefaultAudioDevice audioDevice];
        TwilioVideoSDK.audioDevice = self.audioDevice;
    }
    return self;
}

- (void)dealloc {
    [self.callKitProvider invalidate];
    self.audioDevice = nil;
}

// Report new call receieved can be used for reporting new calls.
- (void)reportNewIncomingCall:(NSUUID *)callUUID
                   withUserId:(NSString *)userId
             withCallForAudio:(BOOL)callForAudio
                   withRoomId:(NSString *)roomId
                withLaunchFor:(NSNumber *)launchFor
          withUserDisplayName:(NSString *)displayName
                 withImageURL:(NSString *)imageURL {
    
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    
    if (userId) {
        CXHandle * handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:displayName];
        callUpdate.remoteHandle = handle;
        callUpdate.supportsDTMF = YES;
        callUpdate.supportsHolding = NO;
        callUpdate.supportsGrouping = NO;
        callUpdate.supportsUngrouping = NO;
        callUpdate.hasVideo = !callForAudio;
        NSString *callUUIDString = callUUID.UUIDString;
        ALAVCallModel *callModel = [[ALAVCallModel alloc] initWithUserId:userId
                                                                  roomId:roomId
                                                                callUUID:callUUID
                                                           launchForType:launchFor
                                                            callForAudio:callForAudio
                                                     withUserDisplayName:displayName
                                                            withImageURL:imageURL];
        
        __weak typeof(self) weakSelf = self;
        callModel.unansweredHandlerCallBack = ^(ALAVCallModel *model) {
            [weakSelf sendEndCallWithCallModel:model
                                withCompletion:^(NSError *error) {
                [weakSelf removeModelWithCallUUID:callUUIDString];
                [weakSelf reportOutgoingCall:model.callUUID withCXCallEndedReason:CXCallEndedReasonUnanswered];
            }];
        };
        
        self.callListModels[callUUIDString] = callModel;
        [self.callKitProvider reportNewIncomingCallWithUUID:callUUID update:callUpdate completion:^(NSError * error) {
            if (error) {
                NSLog(@"Error in callKitProvider reportNewIncomingCall: %@", error.localizedDescription);
            } else {
                NSLog(@"New call reported for userId successsfully %@",userId);
            }
        }];
        callModel.unansweredCallTimerActive = YES;
    }
}

// Perform start call from call kit
-(void)perfromStartCallAction:(NSUUID *)callUUID
                   withUserId:(NSString *)userId
             withCallForAudio:(BOOL)callForAudio
                   withRoomId:(NSString *)roomId
                withLaunchFor:(NSNumber *)launchFor {
    
    ALContactDBService * contactDB = [ALContactDBService new];
    ALContact *alContact = [contactDB loadContactByKey:@"userId" value:userId];
    
    NSString * displayName = alContact.getDisplayName;
    CXHandle * handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:displayName];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:callUUID handle:handle];
    startCallAction.video = !callForAudio;
    startCallAction.contactIdentifier = userId;
    
    NSString *callUUIDString = callUUID.UUIDString;
    ALAVCallModel *callModel = [[ALAVCallModel alloc] initWithUserId:userId
                                                              roomId:roomId
                                                            callUUID:callUUID
                                                       launchForType:launchFor
                                                        callForAudio:callForAudio
                                                 withUserDisplayName:displayName
                                                        withImageURL:alContact.contactImageUrl];
    self.callListModels[callUUIDString] = callModel;
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];
    [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
        if (error) {
            NSLog(@"Error in perfromStartCallAction for CXStartCallAction: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self removeModelWithCallUUID:callUUIDString];
            });
        } else {
            CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
            callUpdate.remoteHandle = handle;
            callUpdate.supportsDTMF = YES;
            callUpdate.supportsHolding = NO;
            callUpdate.supportsGrouping = NO;
            callUpdate.supportsUngrouping = NO;
            callUpdate.hasVideo = !callForAudio;
            [self.callKitProvider reportCallWithUUID:callUUID updated:callUpdate];
            NSLog(@"perfrom Start Call for userId successsfully %@",userId);
        }
    }];
}

-(void) sendEndCallWithCallModel:(ALAVCallModel *)callModel
                  withCompletion:(void(^)(NSError * error)) completion {
    if ([callModel.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]] && !callModel.startTime)
    {
        //        SELF CALLED AND SELF REJECT : SEND MISSED MSG : WITHOUT TALK
        NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:AL_CALL_MISSED
                                                                     andCallAudio:callModel.callForAudio
                                                                        andRoomId:callModel.roomId];
        
        [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                             andReceiverId:callModel.userId
                                            andContentType:AV_CALL_CONTENT_TWO
                                                andMsgText:callModel.roomId withCompletion:^(NSError *error) {
            [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                                 andReceiverId:callModel.userId
                                                andContentType:AV_CALL_CONTENT_THREE
                                                    andMsgText:@"CALL MISSED" withCompletion:^(NSError *error) {
                completion(error);
                return;
            }];
        }];
    }
    else if ([callModel.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_RECEIVED]] && !callModel.startTime)
    {
        //        SELF IS RECEIVER AND REJECT CALL : SEND REJECT MSG : WITHOUT TALK
        NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:AL_CALL_REJECTED
                                                                     andCallAudio:callModel.callForAudio
                                                                        andRoomId:callModel.roomId];
        
        [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                             andReceiverId:callModel.userId
                                            andContentType:AV_CALL_CONTENT_TWO
                                                andMsgText:callModel.roomId withCompletion:^(NSError *error) {
            completion(error);
            return;
        }];
    } else {
        
        if ([callModel.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]] ||
            [callModel.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_RECEIVED]]) {
            
            if (callModel.startTime.integerValue >0) {
                NSNumber *endTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
                long int timeDuration = (endTime.integerValue - callModel.startTime.integerValue);
                NSString *callDuration = [NSString stringWithFormat:@"%li",timeDuration];
                NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:AL_CALL_END
                                                                             andCallAudio:callModel.callForAudio
                                                                                andRoomId:callModel.roomId];
                
                [dictionary setObject:callDuration forKey:@"CALL_DURATION"];
                [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                                     andReceiverId:callModel.userId
                                                    andContentType:AV_CALL_CONTENT_THREE
                                                        andMsgText:@"CALL ENDED"
                                                    withCompletion:^(NSError *error) {
                    completion(error);
                    return;
                }];
            } else {
                completion(nil);
                return;
            }
        }
    }
}

// Perform the call end from local view controller.
-(void)performEndCallAction:(NSUUID *)callUUID
             withCompletion:(void(^)(NSError *error))completion {
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:callUUID];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
    [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
        if (error) {
            NSLog(@"EndCallAction transaction request failed: %@", [error localizedDescription]);
        } else {
            NSLog(@"EndCallAction transaction request successful");
        }
        completion(error);
    }];
}

- (BOOL)isCallActive:(NSUUID *)callUUID {
    if (!callUUID) {
        NSLog(@"Call UUID is nil in isCallActive");
        return NO;
    }
    CXCallObserver *callObserver = self.callKitCallController.callObserver;
    for (CXCall *call in callObserver.calls) {
        if ([[call.UUID UUIDString] caseInsensitiveCompare:callUUID.UUIDString] == NSOrderedSame ) {
            return YES;
        }
    }
    return NO;
}

-(void)sendMessageAndEndActiveCallWithCompletion:(void(^)(NSError * error))completion {
    if (self.activeCallModel) {
        [self sendEndCallWithCallModel:self.activeCallModel
                        withCompletion:^(NSError *error) {
            if (error) {
                completion(error);
            } else {
                if (self.activeCallViewController) {
                    [self.activeCallViewController disconnectRoom];
                    [self.activeCallViewController dismissViewControllerAnimated:YES completion:^{
                        [self removeModelWithCallUUID:self.activeCallModel.callUUID.UUIDString];
                        self.activeCallModel = nil;
                        self.activeCallViewController = nil;
                        completion(nil);
                    }];
                } else {
                    self.activeCallModel = nil;
                    [self removeModelWithCallUUID:self.activeCallModel.callUUID.UUIDString];
                    completion(nil);
                }
            }
        }];
    } else {
        completion(nil);
    }
}

-(void)endActiveCallVCWithCallReason:(CXCallEndedReason)reason
                          withRoomID:(NSString *)roomId
                        withCallUUID:(NSUUID *)callUUID {
    if (self.activeCallModel &&
        self.activeCallViewController &&
        [self.activeCallModel.roomId isEqualToString:roomId]) {
        [self reportOutgoingCall:self.activeCallModel.callUUID
           withCXCallEndedReason:reason];
        [self.activeCallViewController disconnectRoom];
        [self.activeCallViewController dismissViewControllerAnimated:YES completion:^{
            [self removeModelWithCallUUID:self.activeCallModel.callUUID.UUIDString];
            self.activeCallModel = nil;
            self.activeCallViewController = nil;
        }];
    } else {
        
        /// Invalidate  the call timer in case if its active if some one disconnect the call from other end
        if (self.callListModels.count > 0 &&
            [self.callListModels valueForKey: callUUID.UUIDString]) {
            ALAVCallModel *callModel = [self.callListModels valueForKey:callUUID.UUIDString];
            callModel.unansweredCallTimerActive = NO;
        }
        [self reportOutgoingCall:callUUID withCXCallEndedReason:reason];
    }
}

-(void)presentCallVCWithCallUUIDString:(NSUUID *)callUUID
                     withFromStartCall:(BOOL) fromStartCall
                        withCompletion:(void(^)(BOOL success))completion  {
    NSString *callUUIDString = [callUUID UUIDString];
    if (self.callListModels.count > 0 &&
        [self.callListModels valueForKey:callUUIDString]) {
        ALAVCallModel *callModel = [self.callListModels valueForKey:callUUIDString];
        ALPushAssist * pushAssist = [[ALPushAssist alloc] init];
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"AudioVideo" bundle:nil];
        ALAudioVideoCallVC * audioVideoCallVC = (ALAudioVideoCallVC *)[storyboard instantiateViewControllerWithIdentifier:[ALApplozicSettings getAudioVideoClassName]];
        audioVideoCallVC.userID = callModel.userId;
        audioVideoCallVC.launchFor = callModel.launchFor;
        audioVideoCallVC.callForAudio = callModel.callForAudio;
        audioVideoCallVC.baseRoomId = callModel.roomId;
        audioVideoCallVC.uuid = callModel.callUUID;
        audioVideoCallVC.displayName = callModel.displayName;
        audioVideoCallVC.imageURL = callModel.imageURL;
        
        audioVideoCallVC.modalPresentationStyle = UIModalPresentationFullScreen;
        if (fromStartCall) {
            [self.callKitProvider reportOutgoingCallWithUUID:callUUID startedConnectingAtDate:nil];
        }
        
        if (!pushAssist.topViewController) {
            completion(NO);
            return;
        }
        [UIView transitionWithView:pushAssist.topViewController.view
                          duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            [pushAssist.topViewController presentViewController:audioVideoCallVC
                                                       animated:YES
                                                     completion:^{
                self.activeCallModel = callModel;
                self.activeCallViewController = audioVideoCallVC;
                completion(YES);
            }];
        } completion:nil];
    } else {
        completion(NO);
    }
}

-(void) reportOutgoingCall:(NSUUID *)callUUID withCXCallEndedReason:(CXCallEndedReason) reason {
    
    // Check if call call is active
    if ([self isCallActive:callUUID]) {
        [self.callKitProvider reportCallWithUUID:callUUID endedAtDate:nil reason:reason];
    }
}

-(void) reportOutgoingCall:(NSUUID *)callUUID {
    CXCallObserver *callObserver = self.callKitCallController.callObserver;
    for (CXCall *call in callObserver.calls) {
        if ([call.UUID isEqual:callUUID] && call.isOutgoing) {
            [self.callKitProvider reportOutgoingCallWithUUID:callUUID connectedAtDate:nil];
            [self updateCallStartTimeWithCallUUID:callUUID];
            break;
        }
    }
}

-(void)updateCallStartTimeWithCallUUID:(NSUUID *)callUUID {
    NSString *callUUIDString = callUUID.UUIDString;
    if (self.callListModels.count > 0 &&
        [self.callListModels valueForKey:callUUIDString]) {
        ALAVCallModel *callModel = [self.callListModels valueForKey:callUUIDString];
        if (callModel) {
            callModel.startTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
            self.callListModels[callUUIDString] = callModel;
        }
    }
}
-(void)removeModelWithCallUUID:(NSString *) callUUIDString {
    if (self.callListModels.count > 0 &&
        [self.callListModels valueForKey:callUUIDString]) {
        [self.callListModels removeObjectForKey:callUUIDString];
    }
}

- (void)setAudioOutputSpeaker:(BOOL)enabled {
    
    self.audioDevice.block =  ^ {
        // We will execute `kTVIDefaultAVAudioSessionConfigurationBlock` first.
        kTVIDefaultAVAudioSessionConfigurationBlock();
        
        // Overwrite the audio route
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;
        if (![session setMode:AVAudioSessionModeVoiceChat error:&error]) {
            NSLog(@"AVAudiosession setMode %@",error);
        }
        AVAudioSessionPortOverride portMode = AVAudioSessionPortOverrideNone;
        if (enabled) {
            portMode = AVAudioSessionPortOverrideSpeaker;
        }
        if (![session overrideOutputAudioPort:portMode error:&error]) {
            NSLog(@"AVAudiosession overrideOutputAudioPort %@",error);
        }
    };
    self.audioDevice.block();
}

#pragma mark - CXProviderDelegate
- (void)providerDidReset:(CXProvider *)provider {
    NSLog(@"providerDidReset:@");
    
    //Clearing all the resource and disconnecting from room
    self.callListModels = [[NSMutableDictionary alloc] init];
    if (self.activeCallViewController) {
        [self.activeCallViewController disconnectRoom];
        [self.activeCallViewController dismissViewControllerAnimated:YES
                                                          completion:^{
            self.activeCallModel = nil;
            self.activeCallViewController = nil;
        }];
    }
}

- (void)providerDidBegin:(CXProvider *)provider {
    NSLog(@"providerDidBegin:@");
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"provider:didActivateAudioSession:@");
    self.audioDevice.enabled = YES;
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"provider:didDeactivateAudioSession:@");
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
    NSLog(@"provider:timedOutPerformingAction:@");
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"provider:performStartCallAction:@");
    
    // Stop the audio unit by setting isEnabled to `false`.
    self.audioDevice.enabled = NO;
    
    // Configure the AVAudioSession by executign the audio device's `block`.
    self.audioDevice.block();
    
    [self sendMessageAndEndActiveCallWithCompletion:^(NSError *error) {
        if (error) {
            NSLog(@"Error in provider:performStartCallAction: %@", error.localizedDescription);
            [action fail];
        } else {
            [self presentCallVCWithCallUUIDString:action.callUUID
                                withFromStartCall:YES
                                   withCompletion:^(BOOL success) {
                if (success) {
                    [action fulfill];
                } else {
                    [action fail];
                }
            }];
        }
    }];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSLog(@"provider:performAnswerCallAction:@");
    
    // Stop the audio unit by setting isEnabled to `false`.
    self.audioDevice.enabled = NO;
    
    // Configure the AVAudioSession by executign the audio device's `block`.
    self.audioDevice.block();
    
    [self sendMessageAndEndActiveCallWithCompletion:^(NSError *error) {
        if (error) {
            NSLog(@"Error in provider:performAnswerCallAction: %@", error.localizedDescription);
            [action fail];
        } else {
            
            if (self.callListModels.count > 0 &&
                [self.callListModels valueForKey:[action.callUUID UUIDString]]) {
                ALAVCallModel *callModel = [self.callListModels valueForKey:[action.callUUID UUIDString]];
                callModel.unansweredCallTimerActive = NO;
            }
            
            [self presentCallVCWithCallUUIDString:action.callUUID
                                withFromStartCall:NO
                                   withCompletion:^(BOOL success) {
                if (success) {
                    [self updateCallStartTimeWithCallUUID:action.callUUID];
                    [action fulfill];
                } else {
                    NSLog(@"PerformAnswerCallAction is failed");
                    [action fail];
                }
            }];
        }
    }];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    NSLog(@"provider:performEndCallAction:@");
    NSString * callUUIDString = [action.callUUID UUIDString];
    
    if (self.callListModels.count > 0 &&
        [self.callListModels valueForKey:callUUIDString]) {
        UIBackgroundTaskIdentifier identifer = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        ALAVCallModel *callModel = [self.callListModels valueForKey:callUUIDString];
        callModel.unansweredCallTimerActive = NO;
        [self sendEndCallWithCallModel:callModel withCompletion:^(NSError *error) {
            [[UIApplication sharedApplication] endBackgroundTask:identifer];
            if (error) {
                NSLog(@"Error in provider:performEndCallAction: %@", error.localizedDescription);
                [action fail];
            } else {
                if (callModel.roomId == self.activeCallViewController.roomID) {
                    if (self.activeCallViewController) {
                        [self.activeCallViewController disconnectRoom];
                        [self.activeCallViewController dismissViewControllerAnimated:YES
                                                                          completion:^{
                            self.activeCallModel = nil;
                            self.activeCallViewController = nil;
                            [self removeModelWithCallUUID:callUUIDString];
                            [action fulfill];
                        }];
                    } else {
                        self.activeCallModel = nil;
                        [self removeModelWithCallUUID:callUUIDString];
                        [action fulfill];
                    }
                } else {
                    [self removeModelWithCallUUID:callUUIDString];
                    [action fulfill];
                }
            }
        }];
    } else {
        NSLog(@"Provider:performEndCallAction failed");
        [action fail];
    }
    
}

@end
