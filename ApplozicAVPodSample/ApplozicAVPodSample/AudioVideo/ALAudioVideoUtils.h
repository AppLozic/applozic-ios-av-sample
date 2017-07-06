//
//  ALAudioVideoUtils.h
//  Applozic
//
//  Created by Abhishek Thapliyal on 1/10/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Applozic/Applozic.h>

@interface ALAudioVideoUtils : NSObject

+ (void)retrieveAccessTokenFromURL:(NSString *)tokenURLStr completion:(void (^)(NSString* token, NSError *err)) completionHandler;

@end
