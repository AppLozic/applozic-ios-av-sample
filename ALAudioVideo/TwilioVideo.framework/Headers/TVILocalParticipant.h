//
//  TVILocalParticipant.h
//  TwilioVideo
//
//  Copyright © 2016-2017 Twilio, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TVILocalAudioTrack;
@class TVILocalVideoTrack;

/**
 *  `TVILocalParticipant` represents your Client in a Room which you are connected to.
 */
@interface TVILocalParticipant : NSObject

/**
 *  @brief The identity of the `TVILocalParticipant`.
 */
@property (nonatomic, readonly, copy, nonnull) NSString *identity;

/**
 *  @brief The LocalParticipant's server identifier. This value uniquely identifies your Client in a Room and is often
 *  useful for debugging purposes.
 */
@property (nonatomic, readonly, copy, nonnull) NSString *sid;

/**
 *  @brief Developers shouldn't initialize this class directly.
 *
 *  @discussion Use `TwilioVideo` connectWith* methods to join a `TVIRoom` and query its `localParticipant` property.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Use TwilioVideo connectWith* methods to join a TVIRoom and query its `localParticipant` property.")));

/**
 *  @brief The collection of local audio tracks being shared in the Room.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<TVILocalAudioTrack *> *audioTracks;

/**
 *  @brief The collection of local video tracks being shared in the Room.
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<TVILocalVideoTrack *> *videoTracks;

/**
 *  @brief Adds a Track to the LocalParticipant, sharing it in the Room.
 *
 *  @param track The `TVILocalAudioTrack` which you would like to share.
 *
 *  @return `YES` if the track was added successfully, `NO` otherwise.
 */
- (BOOL)addAudioTrack:(nonnull TVILocalAudioTrack *)track;

/**
 *  @brief Adds a Track to the LocalParticipant, sharing it in the Room.
 *
 *  @param track The `TVILocalVideoTrack` which you would like to share.
 *
 *  @return `YES` if the track was added successfully, `NO` otherwise.
 */
- (BOOL)addVideoTrack:(nonnull TVILocalVideoTrack *)track;

/**
 *  @brief Removes a Track from the LocalParticipant, un-sharing it from the Room.
 *
 *  @param track The `TVILocalVideoTrack` which you would like to remove.
 *
 *  @return `YES` if the track was removed successfully, `NO` otherwise.
 */
- (BOOL)removeAudioTrack:(nonnull TVILocalAudioTrack *)track;

/**
 *  @brief Removes a Track from the LocalParticipant, un-sharing it from the Room.
 *
 *  @param track The `TVILocalVideoTrack` which you would like to remove.
 *
 *  @return `YES` if the track was removed successfully, `NO` otherwise.
 */
- (BOOL)removeVideoTrack:(nonnull TVILocalVideoTrack *)track;


@end
