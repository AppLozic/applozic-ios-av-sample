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

+ (void)retrieveAccessTokenFromURL:(NSString *)tokenURLStr completion:(void (^)(NSString* token, NSError *err)) completionHandler
{
    tokenURLStr = [NSString stringWithFormat:@"%@?identity=%@&device=%@",tokenURLStr,
                   [ALUserDefaultsHandler getUserId],[[NSUUID UUID] UUIDString]];
    
    NSURL *tokenURL = [NSURL URLWithString:tokenURLStr];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    NSURLSessionDataTask *task = [session dataTaskWithURL:tokenURL
                                        completionHandler: ^(NSData * _Nullable data,
                                                             NSURLResponse * _Nullable response,
                                                             NSError * _Nullable error) {
                                            NSError *err = error;
                                            NSString *accessToken;
                                            NSString *identity;
                                            if (!err) {
                                                if (data != nil) {
                                                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                                                         options:0
                                                                                                           error:&err];
                                                    if (!err) {
                                                        accessToken = json[@"token"];
                                                        identity = json[@"identity"];
                                                        NSLog(@"Logged in as %@",identity);
                                                    }
                                                }
                                            }
                                            completionHandler(accessToken, err);
                                        }];
    [task resume];
}

@end
