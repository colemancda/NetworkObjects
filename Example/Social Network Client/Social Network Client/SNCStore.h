//
//  SNCStore.h
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/21/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NOAPICachedStore, User;

@interface SNCStore : NSObject

+ (instancetype)sharedStore;

#pragma mark

@property (readonly) NOAPICachedStore *cacheStore;

#pragma mark - Session Properties

// properties set after successful authentication

@property (readonly) NSURL *serverURL;

@property (readonly) NSUInteger clientID;

@property (readonly) NSString *clientSecret;

@property (readonly) User *user;

#pragma mark - Authentication

-(NSArray *)loginWithUsername:(NSString *)username
                password:(NSString *)password
               serverURL:(NSURL *)serverURL
                clientID:(NSUInteger)clientID
            clientSecret:(NSString *)secret
              completion:(void (^)(NSError *error))completionBlock;

-(NSArray *)registerWithUsername:(NSString *)username
                   password:(NSString *)password
                  serverURL:(NSURL *)serverURL
                   clientID:(NSUInteger)clientID
               clientSecret:(NSString *)secret
                 completion:(void (^)(NSError *error))completionBlock;

#pragma mark - Complex Requests

-(NSURLSessionDataTask *)fetchUserWithCompletion:(void (^)(NSError *error))completionBlock;

@end
