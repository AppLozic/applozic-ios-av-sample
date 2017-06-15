//
//  TVIAudioOptions.h
//  TwilioVideo
//
//  Copyright © 2016-2017 Twilio, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  `TVIAudioOptionsBuilder` constructs `TVIAudioOptions`.
 */
@interface TVIAudioOptionsBuilder : NSObject

/**
 *  @brief Audio receiver jitter buffer (NetEq) fast accelerate mode. Defaults to `NO`.
 */
@property (nonatomic, assign) BOOL audioJitterBufferFastAccelerate;

/**
 *  @brief Audio receiver jitter buffer (NetEq) max capacity in number of packets. Defaults to `50`.
 */
@property (nonatomic, assign) int audioJitterBufferMaxPackets;

/**
 *  @brief Audio processing to remove background noise of lower frequencies. Defaults to `YES`.
 */
@property (nonatomic, assign) BOOL highpassFilter;

/**
 *  @brief Enable audio level control. Defaults to `NO`.
 */
@property (nonatomic, assign) BOOL levelControl;

/**
 *  @brief An optional initialization value for the level controller in order to compute the signal gain. The unit for
 *  the peak level is dBFS and the allowed range is -100..0. Defaults to `-6.0206f`.
 */
@property (nonatomic, assign) CGFloat levelControlInitialPeakLevelDBFS;

- (null_unspecified instancetype)init __attribute__((unavailable("Use a TVIAudioOptionsBuilderBlock instead.")));

@end

/**
 *  `TVIAudioOptionsBuilderBlock` allows you to construct `TVIAudioOptions` using the builder pattern.
 *
 *  @param builder The builder
 */
typedef void (^TVIAudioOptionsBuilderBlock)(TVIAudioOptionsBuilder * _Nonnull builder);

/**
 *  `TVIAudioOptions` specifies options for `TVILocalAudioTrack`.
 */
@interface TVIAudioOptions : NSObject

/**
 *  @brief Audio receiver jitter buffer (NetEq) max capacity in number of packets. Defaults to `50`.
 */
@property (nonatomic, assign, readonly) int audioJitterBufferMaxPackets;

/**
 *  @brief Audio receiver jitter buffer (NetEq) fast accelerate mode. Defaults to `NO`.
 */
@property (nonatomic, assign, readonly) BOOL audioJitterBufferFastAccelerate;

/**
 *  @brief Audio processing to remove background noise of lower frequencies. Defaults to `YES`.
 */
@property (nonatomic, assign, readonly) BOOL highpassFilter;

/**
 *  @brief Enable audio level control. Defaults to `NO`.
 */
@property (nonatomic, assign, readonly) BOOL levelControl;

/**
 *  @brief An optional initialization value for the level controller in order to compute the signal gain. The unit for
 *  the peak level is dBFS and the allowed range is -100..0. Defaults to `-6.0206f`.
 */
@property (nonatomic, assign, readonly) CGFloat levelControlInitialPeakLevelDBFS;

/**
 *  @brief Creates default options.
 *
 *  @return An instance of `TVIAudioOptions`.
 */
+ (null_unspecified instancetype)options;

/**
 *  @brief Constructs `TVIAudioOptions` using the builder pattern.
 *
 *  @param block You can pass audio options to the builder using this block. The builder will construct a
 *  `TVIAudioOptions` object using the options provided.
 *
 *  @return An instance of `TVIAudioOptions`.
 */
+ (null_unspecified instancetype)optionsWithBlock:(nonnull TVIAudioOptionsBuilderBlock)block;

@end
