//
//  ALAudioVideoCallVC.m
//  Applozic
//
//  Created by Abhishek Thapliyal on 1/9/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import "ALAudioVideoCallVC.h"


@interface ALAudioVideoCallVC ()

@property (weak, nonatomic) NSTimer * timer;
@property (weak, nonatomic) NSTimer * audioTimer;
@property (strong, nonatomic) NSString * callDuration;

@end

@implementation ALAudioVideoCallVC
{
    BOOL buttonHide;
    BOOL speakerEnable;
    BOOL micEnable;
    BOOL frontCameraEnable;
    int count;
    NSDate *startDate;
    SystemSoundID soundID;
    NSString *soundPath;
    NSNumber *startTime;
    NSNumber *endTime;
    UITapGestureRecognizer *tapGesture;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [ALAudioVideoBaseVC setChatRoomEngage:YES];
    
    self.receiverID = self.userID;
    
    self.alMQTTObject = [ALMQTTConversationService sharedInstance];
    [self.alMQTTObject subscribeToConversation];
    
    // Configure access token manually for testing, if desired! Create one manually in the console
    self.accessToken = @"TWILIO_ACCESS_TOKEN";
    
    // Using the PHP server to provide access tokens? Make sure the tokenURL is pointing to the correct location -
    // the default is http://localhost:8000/token.php
//    self.tokenUrl = @"http://localhost:8000/token.php";
    self.tokenUrl = [NSString stringWithFormat:@"%@/twilio/token",[ALUserDefaultsHandler getBASEURL]];
    
    
      
    [self startPreview];

    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(animate)];
    
    buttonHide = NO;
    speakerEnable = NO;
    frontCameraEnable = NO;
    micEnable = NO;
    self.audioTimerLabel.text = @"";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.userProfile.layer.cornerRadius = self.userProfile.frame.size.width/2;
        self.userProfile.layer.masksToBounds = YES;
    });
    
    ALContactService * contactService = [[ALContactService alloc] init];
    self.alContact = [contactService loadContactByKey:@"userId" value:self.receiverID];
    [self.UserDisplayName setText:[self.alContact getDisplayName]];
    if (self.alContact.contactImageUrl.length)
    {
        [ALUtilityClass setImageFromURL:self.alContact.contactImageUrl andImageView:self.userProfile];
    }
    
    [self.callAcceptReject setHidden:YES];
    self.roomID = self.baseRoomId;
    count = 0;
    
    if([self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]])
    {
        [self handleCallButtonVisiblity]; //  WHEN SOMEONE IS CALLING
        [self connectButtonPressed];
        soundPath = [[NSURL URLWithString:@"/System/Library/Audio/UISounds/nano/ringback_tone_aus.caf"] path];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
    }
    else
    {
        soundPath = [[NSURL URLWithString:@"/Library/Ringtones/Marimba.m4r"] path];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
        self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                      target:self
                                                    selector:@selector(playRingtone)
                                                    userInfo:nil
                                                     repeats:YES];
    }

    [self.previewView setHidden:YES];
    [self buttonVisiblityForCallType:YES];
    [ALAudioVideoBaseVC setChatRoomEngage:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDataConnectivity)
                                                 name:@"NETWORK_DISCONNECTED"
                                               object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.alMQTTObject unsubscribeToConversation];
    [ALAudioVideoBaseVC setChatRoomEngage:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NETWORK_DISCONNECTED" object:nil];
}

-(void)dismissAVViewController:(BOOL)animated
{
    [super dismissAVViewController:animated];
    [self.timer invalidate];
    AudioServicesDisposeSystemSoundID(soundID);
    [self.room disconnect];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_VOIP_MSG" object:nil];
}

//==============================================================================================================================
#pragma mark BUTTON ACTIONS
//==============================================================================================================================

- (IBAction)toggleVideoShare:(id)sender {
 
    if (self.localVideoTrack.enabled)
    {
        [self.videoShare setImage:[UIImage imageNamed:@"video_strip.png"] forState:UIControlStateNormal];
    }
    else
    {
        [self.videoShare setImage:[UIImage imageNamed:@"video_filled.png"] forState:UIControlStateNormal];
    }
    self.localVideoTrack.enabled = !self.localVideoTrack.enabled;
}

- (IBAction)callAcceptRejectAction:(id)sender {
    [self callRejectAction:sender];
}

- (IBAction)callAcceptAction:(id)sender
{
    if(count < 60)
    {
        AudioServicesDisposeSystemSoundID(soundID);
        [self.timer invalidate];
    }
    [self connectButtonPressed];
    [self handleCallButtonVisiblity]; // WHEN SOMEONE IS ACCEPTING CALL
    [self buttonVisiblityForCallType:NO];
    [self.callView addGestureRecognizer:tapGesture];
}

- (IBAction)callRejectAction:(id)sender
{
    if([self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]] && !self.participant)
    {
        //        SELF CALLED AND SELF REJECT : SEND MISSED MSG : WITHOUT TALK

        NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:@"CALL_MISSED"
                                                                     andCallAudio:self.callForAudio
                                                                        andRoomId:self.roomID];
        
        [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                             andReceiverId:self.receiverID
                                            andContentType:AV_CALL_CONTENT_TWO
                                                 andMsgText:self.roomID];
        
        [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                             andReceiverId:self.receiverID
                                            andContentType:AV_CALL_CONTENT_THREE
                                                 andMsgText:@"CALL MISSED"];
    }
    else if ([self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_RECEIVED]] && !self.participant)
    {
        //        SELF IS RECEIVER AND REJECT CALL : SEND REJECT MSG : WITHOUT TALK

        NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:@"CALL_REJECTED"
                                                                     andCallAudio:self.callForAudio
                                                                        andRoomId:self.roomID];
        
        [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                             andReceiverId:self.receiverID
                                            andContentType:AV_CALL_CONTENT_TWO
                                                 andMsgText:self.roomID];
    }
    else
    {
       [self sendCallEndMessage];
    }
    
    [self dismissAVViewController:YES];
}

- (IBAction)loudSpeakerAction:(id)sender
{
    if (!speakerEnable)
    {
        speakerEnable = YES;
        [self.loudSpeaker setImage:[UIImage imageNamed:@"loudspeaker_solid.png"] forState:UIControlStateNormal];
    }
    else
    {
        speakerEnable = NO;
        [self.loudSpeaker setImage:[UIImage imageNamed:@"loudspeaker_strip.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)micMuteAction:(id)sender
{
    if (self.localAudioTrack)
    {
        self.localAudioTrack.enabled = !self.localAudioTrack.isEnabled;
        
        if (self.localAudioTrack.isEnabled)
        {
            [self.muteUnmute setImage:[UIImage imageNamed:@"mic_active.png"] forState:UIControlStateNormal];
        }
        else
        {
            [self.muteUnmute setImage:[UIImage imageNamed:@"mic_mute.png"] forState:UIControlStateNormal];
        }
    }
}

- (IBAction)cameraToggleAction:(id)sender
{
    if (!frontCameraEnable)
    {
        frontCameraEnable = YES;
        [self.cameraToggle setImage:[UIImage imageNamed:@"camera_front.png"] forState:UIControlStateNormal];
    }
    else
    {
        frontCameraEnable = NO;
        [self.cameraToggle setImage:[UIImage imageNamed:@"camera_default.png"] forState:UIControlStateNormal];
    }
    [self flipCamera];
}

//==============================================================================================================================
#pragma mark - SUPPORT/HELPER METHODS
//==============================================================================================================================

- (void)handleDataConnectivity
{
    [super handleDataConnectivity];
    BOOL flag = [self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_RECEIVED]];
    
    if (flag && self.participant)
    {
        [self dismissAVViewController:YES];
        [ALNotificationView showNotification:@"No Internet Connectivity"];
    }
}

-(void)sendCallEndMessage
{
    if ([self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]])
    {
        endTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
        long int timeDuration = (endTime.integerValue - startTime.integerValue);
        self.callDuration = [NSString stringWithFormat:@"%li",timeDuration];
        /* TODO : CHECK MSG SHOULD BE REFELECT IN UI AS CURRENTLY NOT COMING ALSO SOMETIME DURATION IS WRONG */
        NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:@"CALL_END"
                                                                     andCallAudio:self.callForAudio
                                                                        andRoomId:self.roomID];
        
        [dictionary setObject:self.callDuration forKey:@"CALL_DURATION"];
        [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                             andReceiverId:self.receiverID
                                            andContentType:AV_CALL_CONTENT_THREE
                                                andMsgText:@"CALL ENDED"];
    }
    
    if (self.callForAudio)
    {
        [self.audioTimer invalidate];
    }
}

-(void)animate
{
    if(!buttonHide)
    {
        buttonHide = YES;
    }
    else
    {
        buttonHide = NO;
    }
    [ALUtilityClass movementAnimation:self.muteUnmute andHide:buttonHide];
    [ALUtilityClass movementAnimation:self.loudSpeaker andHide:buttonHide];
    if (!self.callForAudio)
    {
       [ALUtilityClass movementAnimation:self.cameraToggle andHide:buttonHide];
       [ALUtilityClass movementAnimation:self.videoShare andHide:buttonHide];
    }
}

-(void)playRingtone
{
    NSLog(@"COUNT :: %i",count);
    if (count > 60)
    {
        [self.timer invalidate];
        AudioServicesDisposeSystemSoundID(soundID);
        
        if ([self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]])
        {
            //        SELF IS CALLED/RECEIVER AND TIMEOUT (count > 60) : SEND MISSED MSG
            
            NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:@"CALL_MISSED"
                                                                         andCallAudio:self.callForAudio
                                                                            andRoomId:self.roomID];
            
            [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                                 andReceiverId:self.receiverID
                                                andContentType:AV_CALL_CONTENT_TWO
                                                     andMsgText:self.roomID];
            
            [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                                 andReceiverId:self.receiverID
                                                andContentType:AV_CALL_CONTENT_THREE
                                                     andMsgText:self.roomID];
        }

        [self.room disconnect];
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }
    count = count + 3;
    AudioServicesPlaySystemSound(soundID);
}

-(void)timerForAudioCall:(NSTimer *)timer
{
    NSDate *currentDate = [NSDate date];
    NSTimeInterval elapsedTime = [currentDate timeIntervalSinceDate:startDate];
    NSInteger hours = elapsedTime / 3600;
    NSInteger minutes = elapsedTime / 60;
    NSInteger seconds = ((int)elapsedTime) % 60;
    self.audioTimerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",(long)hours, (long)minutes, (long)seconds];
}

-(void)startAudioTimer
{
    // FOR AUDIO CALL WHEN SESSION STARTS IN BETWEEN THEM
    startDate = [NSDate date];
    self.audioTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(timerForAudioCall:)
                                                     userInfo:nil
                                                      repeats:YES];
}

-(void)handleCallButtonVisiblity
{
    [self.callReject setHidden:YES];
    [self.callAccept setHidden:YES];
    [self.callAcceptReject setHidden:NO];
}

-(void)buttonVisiblityForCallType:(BOOL)flag
{
    [self.muteUnmute setHidden:flag];
    [self.loudSpeaker setHidden:flag];
    if (self.callForAudio)
    {
        [self.cameraToggle setHidden:self.callForAudio];
        [self.videoShare setHidden:self.callForAudio];
    }
    else
    {
        [self.cameraToggle setHidden:flag];
        [self.videoShare setHidden:flag];
    }
}

//==============================================================================================================================
#pragma mark - TWILIO : Public
//==============================================================================================================================

- (void)connectButtonPressed
{
    [self showRoomUI:YES];
    
    if ([self.accessToken isEqualToString:@"TWILIO_ACCESS_TOKEN"])
    {
        [self logMessage:[NSString stringWithFormat:@"Fetching an access token"]];
        [ALAudioVideoUtils retrieveAccessTokenFromURL:self.tokenUrl completion:^(NSString *token, NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!err)
                {
                    self.accessToken = token;
                    [self processConnection];
                }
                else
                {
                    [self logMessage:[NSString stringWithFormat:@"Error retrieving the access token"]];
                    [self showRoomUI:NO];
                }
            });
        }];
    } else {
        [self doConnect];
    }
}

-(void)processConnection
{
    if([self.launchFor isEqualToNumber:[NSNumber numberWithInt:AV_CALL_DIALLED]])
    {
        NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:@"CALL_DIALED"
                                                                     andCallAudio:self.callForAudio
                                                                        andRoomId:self.roomID];
        [self doConnect];
        [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                             andReceiverId:self.receiverID
                                            andContentType:AV_CALL_CONTENT_TWO
                                                 andMsgText:self.roomID];
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                      target:self
                                                    selector:@selector(playRingtone)
                                                    userInfo:nil
                                                     repeats:YES];
    }
    else
    {
        NSMutableDictionary * dictionary = [ALVOIPNotificationHandler getMetaData:@"CALL_ANSWERED"
                                                                     andCallAudio:self.callForAudio
                                                                        andRoomId:self.roomID];
        [self doConnect];
        [ALVOIPNotificationHandler sendMessageWithMetaData:dictionary
                                             andReceiverId:self.receiverID
                                            andContentType:AV_CALL_CONTENT_TWO
                                                 andMsgText:self.roomID];
    }
}

//==============================================================================================================================
#pragma mark - TWILIO : Private
//==============================================================================================================================

- (void)startPreview {
    // TVICameraCapturer is not supported with the Simulator.
//    if ([PlatformUtils isSimulator]) {
//        [self.previewView removeFromSuperview];
//        return;
//    }
//    
    self.camera = [[TVICameraCapturer alloc] initWithSource:TVICameraCaptureSourceFrontCamera delegate:self];
    self.localVideoTrack = [TVILocalVideoTrack trackWithCapturer:self.camera];
    if (!self.localVideoTrack) {
        [self logMessage:@"Failed to add video track"];
    } else {
        // Add renderer to video track for local preview
        [self.localVideoTrack addRenderer:self.previewView];
        
        [self logMessage:@"Video track created"];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(flipCamera)];
        [self.previewView addGestureRecognizer:tap];
    }
}


- (void)flipCamera {
    if (self.camera.source == TVICameraCaptureSourceFrontCamera) {
        [self.camera selectSource:TVICameraCaptureSourceBackCameraWide];
    } else {
        [self.camera selectSource:TVICameraCaptureSourceFrontCamera];
    }
}

- (void)prepareLocalMedia
{
    
    // We will share local audio and video when we connect to room.
    
    // Create an audio track.
    if (!self.localAudioTrack) {
        self.localAudioTrack = [TVILocalAudioTrack track];
        
        if (!self.localAudioTrack) {
            [self logMessage:@"Failed to add audio track"];
        }
    }
    
    // Create a video track which captures from the camera.
    if (!self.localVideoTrack) {
        [self startPreview];
    }
}

- (void)doConnect {
    if ([self.accessToken isEqualToString:@"TWILIO_ACCESS_TOKEN"]) {
        [self logMessage:@"Please provide a valid token to connect to a room"];
        return;
    }
    
    // Prepare local media which we will share with Room Participants.
    [self prepareLocalMedia];
    
    TVIConnectOptions *connectOptions = [TVIConnectOptions optionsWithToken:self.accessToken
                                                                      block:^(TVIConnectOptionsBuilder * _Nonnull builder) {
                                                                          
                                                                          // Use the local media that we prepared earlier.
                                                                          builder.audioTracks = self.localAudioTrack ? @[ self.localAudioTrack ] : @[ ];
                                                                          builder.videoTracks = self.localVideoTrack ? @[ self.localVideoTrack ] : @[ ];
                                                                          
                                                                          // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
                                                                          // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
                                                                          builder.roomName = self.roomID;
                                                                      }];
    
    // Connect to the Room using the options we provided.
    self.room = [TwilioVideo connectWithOptions:connectOptions delegate:self];
    
   // [self logMessage:[NSString stringWithFormat:@"Attempting to connect to room %@", self.roomTextField.text]];
}


// Reset the client ui status
- (void)showRoomUI:(BOOL)inRoom
{
//    [UIApplication sharedApplication].idleTimerDisabled = inRoom;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)cleanupRemoteParticipant {
    
    if (self.participant) {
        if ([self.participant.videoTracks count] > 0 &&  !self.callForAudio) {
            [self.participant.videoTracks[0] removeRenderer:self.remoteView];
            [self.remoteView removeFromSuperview];
        }
        self.participant = nil;
    }
}

- (void)logMessage:(NSString *)msg
{
    NSLog(@"LOG_MESSAGE : %@",msg);
}

//==============================================================================================================================
#pragma mark - TVIRoomDelegate : PARTICIPANT : CONNECT/DISCONNECT
//==============================================================================================================================

- (void)didConnectToRoom:(TVIRoom *)room {
    // At the moment, this example only supports rendering one Participant at a time.
    // HERE CURRENT USER CONNECTS TO ROOM
    
    [self logMessage:[NSString stringWithFormat:@"Connected to room %@ as %@", room.name, room.localParticipant.identity]];
    
    if (room.participants.count > 0) {
        self.participant = room.participants[0];
        self.participant.delegate = self;
    }
    
    if (self.participant)
    {
        if (self.callForAudio)
        {
            [self startAudioTimer];
        }
        else
        {
            [self.previewView setHidden:NO];
        }
    }
}

- (void)room:(TVIRoom *)room didDisconnectWithError:(nullable NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Disconnected from room %@, error = %@", room.name, error]];
    
    [self cleanupRemoteParticipant];
    self.room = nil;
    
    [self showRoomUI:NO];
}

- (void)room:(TVIRoom *)room didFailToConnectWithError:(nonnull NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Failed to connect to room, error = %@", error]];
    
    self.room = nil;
    
    [self showRoomUI:NO];
}

- (void)room:(TVIRoom *)room participantDidConnect:(TVIParticipant *)participant {
    
    // HERE RECEIVER USER CONNECT
    if (!self.participant) {
        self.participant = participant;
        self.participant.delegate = self;
    }
    [self logMessage:[NSString stringWithFormat:@"Room %@ participant %@ connected", room.name, participant.identity]];
    
    if(count < 60)
    {
        AudioServicesDisposeSystemSoundID(soundID);
        [self.timer invalidate];
        [self buttonVisiblityForCallType:NO];
        [self.remoteView addGestureRecognizer:tapGesture];
        startTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
        
        // FOR AUDIO CALL
        if (self.callForAudio)
        {
            [self startAudioTimer];
        }
        else
        {
            [self.previewView setHidden:NO];
        }
    }
}

- (void)room:(TVIRoom *)room participantDidDisconnect:(TVIParticipant *)participant {
    
    // HERE RECEIVER USER DIS-CONNECT
    if (self.participant == participant) {
        [self sendCallEndMessage];
        [self cleanupRemoteParticipant];
    }
    
    [self logMessage:[NSString stringWithFormat:@"Room %@ participant %@ disconnected", room.name, participant.identity]];
    [self.room disconnect];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

//==============================================================================================================================
#pragma mark - TVIParticipantDelegate : AUDIO/VIDEO : ENABLE/DISABLE
//==============================================================================================================================

- (void)participant:(TVIParticipant *)participant addedVideoTrack:(TVIVideoTrack *)videoTrack {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ added video track.", participant.identity]];
    
    /*if (self.participant == participant && !self.callForAudio) {
        [videoTrack attach:self.remoteView];
    }*/
    
    
    if (self.participant == participant && !self.callForAudio) {
        [self setupRemoteView];
        [videoTrack addRenderer:self.remoteView];
    }
}

- (void)participant:(TVIParticipant *)participant removedVideoTrack:(TVIVideoTrack *)videoTrack {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ removed video track.", participant.identity]];
    
    if (self.participant == participant) {
        [videoTrack removeRenderer:self.remoteView];
       [self.remoteView removeFromSuperview];
    }
}

- (void)participant:(TVIParticipant *)participant addedAudioTrack:(TVIAudioTrack *)audioTrack {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ added audio track.", participant.identity]];
}

- (void)participant:(TVIParticipant *)participant removedAudioTrack:(TVIAudioTrack *)audioTrack {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ removed audio track.", participant.identity]];
}

- (void)participant:(TVIParticipant *)participant enabledTrack:(TVITrack *)track {
    NSString *type = @"";
    if ([track isKindOfClass:[TVIAudioTrack class]]) {
        type = @"audio";
    } else {
        type = @"video";
    }
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ track.", participant.identity, type]];
}

- (void)participant:(TVIParticipant *)participant disabledTrack:(TVITrack *)track {
    NSString *type = @"";
    if ([track isKindOfClass:[TVIAudioTrack class]]) {
        type = @"audio";
    } else {
        type = @"video";
    }
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ track.", participant.identity, type]];
}


- (void)setupRemoteView {
    // Creating `TVIVideoView` programmatically
    TVIVideoView *remoteView = [[TVIVideoView alloc] init];
    
    // `TVIVideoView` supports UIViewContentModeScaleToFill, UIViewContentModeScaleAspectFill and UIViewContentModeScaleAspectFit
    // UIViewContentModeScaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
    self.remoteView.contentMode = UIViewContentModeScaleToFill;
    [self.view insertSubview:remoteView atIndex:0];
    
    if(!self.callForAudio){
        [self.callView setHidden:YES];
    }
    self.remoteView = remoteView;
    
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerX];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerY];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:1
                                                              constant:0];
    [self.view addConstraint:width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1
                                                               constant:0];
    [self.view addConstraint:height];
}

#pragma mark - TVIVideoViewDelegate

- (void)videoView:(TVIVideoView *)view videoDimensionsDidChange:(CMVideoDimensions)dimensions {
    NSLog(@"Dimensions changed to: %d x %d", dimensions.width, dimensions.height);
    [self.view setNeedsLayout];
}

#pragma mark - TVICameraCapturerDelegate

- (void)cameraCapturer:(TVICameraCapturer *)capturer didStartWithSource:(TVICameraCaptureSource)source {
    self.previewView.mirror= (source == TVICameraCaptureSourceFrontCamera);
}



@end
