//
//  ALAVCallModel.h
//  ALAudioVideo
//
//  Created by Sunil on 14/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALAVCallModel : NSObject

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSUUID *callUUID;
@property (strong, nonatomic) NSString *roomId;
@property (nonatomic, strong) NSNumber *launchFor;
@property (strong, nonatomic) NSString *imageURL;
@property (strong, nonatomic) NSString *displayName;
@property (nonatomic) BOOL callForAudio;

- (instancetype)initWithUserId:(NSString *)userId
                        roomId:(NSString *)roomId
                      callUUID:(NSUUID *)callUUID
                 launchForType:(NSNumber *)launchFor
                  callForAudio:(BOOL)audioCall
           withUserDisplayName:(NSString *)displayName
                  withImageURL:(NSString *)imageURL;

@end

NS_ASSUME_NONNULL_END
