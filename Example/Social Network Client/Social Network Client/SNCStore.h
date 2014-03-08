//
//  SNCStore.h
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/21/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NetworkObjects/NetworkObjects.h>
@class User;

@interface SNCStore : NOAPICachedStore

+(instancetype)sharedStore;

#pragma mark - Session Properties

// properties set after successful authentication

@property (readonly) User *user;

#pragma mark - Logout

-(void)logout;

#pragma mark - Authentication

-(void)loginWithUsername:(NSString *)username
                     password:(NSString *)password
                    serverURL:(NSURL *)serverURL
                     clientID:(NSUInteger)clientID
                 clientSecret:(NSString *)secret
                   URLSession:(NSURLSession *)urlSession
                   completion:(void (^)(NSError *error))completionBlock;

-(void)registerWithUsername:(NSString *)username
                        password:(NSString *)password
                       serverURL:(NSURL *)serverURL
                        clientID:(NSUInteger)clientID
                    clientSecret:(NSString *)secret
                      URLSession:(NSURLSession *)urlSession
                      completion:(void (^)(NSError *error))completionBlock;

#pragma mark - Specialized Requests

/** Fetches current user */
-(NSURLSessionDataTask *)fetchUserWithURLSession:(NSURLSession *)urlSession
                                      completion:(void (^)(NSError *error))completionBlock;


@end
