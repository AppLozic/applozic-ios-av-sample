//
//  ALAudioVideoCallVC.h
//  Applozic
//
//  Created by Abhishek Thapliyal on 1/9/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ALAudioVideoUtils.h"
#import <Applozic/Applozic.h>
#import <TwilioVideo/TwilioVideo.h>
#import <AVFoundation/AVFoundation.h>

extern NSString * const AL_CALL_DIALED;
extern NSString * const AL_CALL_ANSWERED;
extern NSString * const AL_CALL_REJECTED;
extern NSString * const AL_CALL_MISSED;
extern NSString * const AL_CALL_END;

@interface ALAudioVideoCallVC : ALAudioVideoBaseVC <TVIRemoteParticipantDelegate, TVIRoomDelegate, TVIVideoViewDelegate, TVICameraSourceDelegate>

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
@property (weak, nonatomic) IBOutlet UILabel *audioCallType;

@property (weak, nonatomic) IBOutlet UILabel *callStatus;

@property (strong, nonatomic) NSUUID * uuid;
@property (strong, nonatomic) NSString *imageURL;
@property (strong, nonatomic) NSString *displayName;
@property (weak, nonatomic) ALMQTTConversationService * alMQTTObject;

- (IBAction)callAcceptRejectAction:(id)sender;
- (IBAction)callAcceptAction:(id)sender;
- (IBAction)callRejectAction:(id)sender;
- (IBAction)loudSpeakerAction:(id)sender;
- (IBAction)micMuteAction:(id)sender;
- (IBAction)cameraToggleAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *callView;
@property (weak, nonatomic) IBOutlet TVIVideoView *previewView;

-(void)disconnectRoom;

//==============================================================================================================================
#pragma mark Video SDK components
//==============================================================================================================================

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *tokenUrl;
@property (nonatomic, strong) NSString *roomID;
@property (nonatomic, strong) NSString *receiverID;
@property (nonatomic, strong) TVICameraSource *camera;
@property (nonatomic, strong) TVILocalVideoTrack *localVideoTrack;
@property (nonatomic, strong) TVILocalAudioTrack *localAudioTrack;
@property (nonatomic, strong) TVIRemoteParticipant *remoteParticipant;
@property (nonatomic, weak) TVIVideoView *remoteView;
@property (nonatomic, strong) TVIRoom *room;

@end

