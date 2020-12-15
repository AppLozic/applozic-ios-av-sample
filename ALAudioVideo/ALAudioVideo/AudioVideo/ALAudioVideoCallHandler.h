//
//  ALAudioVideoCallHandler.h
//  ALAudioVideo
//
//  Created by Sunil on 02/12/20.
//  Copyright © 2020 Adarsh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALAudioVideoCallHandler : NSObject
+(ALAudioVideoCallHandler *)shared;
-(void) dataConnectionNotificationHandler;
@end

NS_ASSUME_NONNULL_END
