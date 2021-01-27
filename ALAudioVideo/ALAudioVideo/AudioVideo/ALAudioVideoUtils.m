//
//  ALAudioVideoUtils.m
//  Applozic
//
//  Created by Abhishek Thapliyal on 1/10/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import "ALAudioVideoUtils.h"
#import <Applozic/Applozic.h>

@implementation ALAudioVideoUtils

+ (void)retrieveAccessTokenFromURL:(NSString *)tokenURLStr
                        completion:(void (^)(NSString* token, NSError *err)) completionHandler {

    NSString * theUrlString = [NSString stringWithFormat:@"%@", tokenURLStr];


    NSString * theParamString = [NSString stringWithFormat:@"identity=%@&device=%@",[ALUserDefaultsHandler getUserId], [ALUserDefaultsHandler getDeviceKeyString]];

    NSMutableURLRequest *theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];

    [ALResponseHandler authenticateAndProcessRequest:theRequest andTag:@"AV_CALL_ACCESS_TOKEN" WithCompletionHandler:^(id theJson, NSError *theError) {
        if (theError) {
            completionHandler(nil, theError);
            return;
        }

        NSDictionary *json = theJson;
        if (!json) {
            NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                         code:1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to convert the json"}];
            completionHandler(nil, responseError);
            return;
        }

        if ([[json valueForKey:@"status"] isEqualToString:@"error"]) {
            NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                         code:1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to generate access token for audio video call"}];

            completionHandler(nil, responseError);
            return;
        }

        NSString *accessToken = [json valueForKey:@"token"];

        ALSLog(ALLoggerSeverityInfo, @"Response for CALL ACCESS TOKEN :: %@", (NSString *)theJson);
        completionHandler(accessToken, nil);
    }];
}

@end
