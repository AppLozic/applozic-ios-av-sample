//
//  ALAudioVideoCallVC.h
//  Applozic
//
//  Created by Abhishek Thapliyal on 1/9/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ALAudioVideoUtils.h"
#import <Applozic/Applozic.h>
#import <TwilioVideo/TwilioVideo.h>
#import <AVFoundation/AVFoundation.h>

#define CALL_DIALED @"CALL_DIALED"
#define CALL_ANSWERED @"CALL_ANSWERED"
#define CALL_REJECTED @"CALL_REJECTED"
#define CALL_MISSED @"CALL_MISSED"
#define CALL_END @"CALL_END"

@interface ALAudioVideoCallVC : ALAudioVideoBaseVC <TVIRoomDelegate, TVIParticipantDelegate,TVIVideoViewDelegate,TVICameraCapturerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *callAcceptReject;
@property (weak, nonatomic) IBOutlet UIButton *callReject;
@property (weak, nonatomic) IBOutlet UIButton *callAccept;
@property (weak, nonatomic) IBOutlet UIImageView *userProfile;
@property (weak, nonatomic) IBOutlet UIButton *muteUnmute;
@property (weak, nonatomic) IBOutlet UIButton *loudSpeaker;
@property (weak, nonatomic) IBOutlet UILabel *UserDisplayName;
@property (weak, nonatomic) IBOutlet UIButton *cameraToggle;
@property (weak, nonatomic) IBOutlet UILabel *audioTimerLabel;
@property (weak, nonatomic) IBOutlet UIButton *videoShare;

@property (strong, nonatomic) ALContact * alContact;
@property (weak, nonatomic) ALMQTTConversationService * alMQTTObject;

- (IBAction)callAcceptRejectAction:(id)sender;
- (IBAction)callAcceptAction:(id)sender;
- (IBAction)callRejectAction:(id)sender;
- (IBAction)loudSpeakerAction:(id)sender;
- (IBAction)micMuteAction:(id)sender;
- (IBAction)cameraToggleAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *callView;
@property (weak, nonatomic) IBOutlet TVIVideoView *previewView;

@property (nonatomic, weak) TVIVideoView *remoteView;

//==============================================================================================================================
#pragma mark Video SDK components
//==============================================================================================================================

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *tokenUrl;
@property (nonatomic, strong) NSString *roomID;
@property (nonatomic, strong) NSString *receiverID;

@property (nonatomic, strong) TVIRoom *room;

@property (nonatomic, strong) TVILocalVideoTrack *localVideoTrack;
@property (nonatomic, strong) TVILocalAudioTrack *localAudioTrack;

@property (nonatomic, strong) TVICameraCapturer *camera;
@property (nonatomic, strong) TVIParticipant *participant;

@end
