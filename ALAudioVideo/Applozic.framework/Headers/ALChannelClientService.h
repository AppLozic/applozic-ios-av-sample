//
//  ALChannelClientService.h
//  Applozic
//
//  Created by devashish on 28/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//  class for server calls

#import <Foundation/Foundation.h>
#import "ALConstant.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "ALChannel.h"
#import "ALChannelUserX.h"
#import "ALChannelDBService.h"
#import "ALChannelFeed.h"
#import "ALChannelCreateResponse.h"
#import "ALChannelSyncResponse.h"
#import "ALMuteRequest.h"
#import "ALAPIResponse.h"

@interface ALChannelClientService : NSObject

+(void)getChannelInfo:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey withCompletion:(void(^)(NSError *error, ALChannel *channel)) completion;

+(void)createChannel:(NSString *)channelName andParentChannelKey:(NSNumber *)parentChannelKey
  orClientChannelKey:(NSString *)clientChannelKey andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink
         channelType:(short)type andMetaData:(NSMutableDictionary *)metaData
      withCompletion:(void(^)(NSError *error, ALChannelCreateResponse *response))completion;

+(void)addMemberToChannel:(NSString *)userId orClientChannelKey:(NSString *)clientChannelKey andChannelKey:(NSNumber *)channelKey withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

+(void)removeMemberFromChannel:(NSString *)userId orClientChannelKey:(NSString *)clientChannelKey andChannelKey:(NSNumber *)channelKey withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

+(void)deleteChannel:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

+(void)leaveChannel:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey withUserId:(NSString *)userId andCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;


+(void)updateChannel:channelKey orClientChannelKey:clientChannelKey andNewName:newName andImageURL:imageURL metadata:metaData orChildKeys:childKeysList orChannelUsers:(NSMutableArray *)channelUsers andCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;


+(void)syncCallForChannel:(NSNumber *)channelKey andCompletion:(void(^)(NSError *error, ALChannelSyncResponse *response))completion;

-(void)markConversationAsRead:(NSNumber *)channelKey withCompletion:(void (^)(NSString *, NSError *))completion;

+(void)addChildKeyList:(NSMutableArray *)childKeyList andParentKey:(NSNumber *)parentKey
        withCompletion:(void (^)(id json, NSError * error))completion;

+(void)removeChildKeyList:(NSMutableArray *)childKeyList andParentKey:(NSNumber *)parentKey
           withCompletion:(void (^)(id json, NSError * error))completion;

+(void)addClientChildKeyList:(NSMutableArray *)clientChildKeyList andClientParentKey:(NSString *)clientParentKey
              withCompletion:(void (^)(id json, NSError * error))completion;

+(void)removeClientChildKeyList:(NSMutableArray *)clientChildKeyList andClientParentKey:(NSString *)clientParentKey
                 withCompletion:(void (^)(id json, NSError * error))completion;
    
-(void) muteChannel:(ALMuteRequest *)ALMuteRequest withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion;


@end
