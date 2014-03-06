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
                      URLSession:(NSURLSession *)urlSession
                      completion:(void (^)(NSError *error))completionBlock;

#pragma mark - Complex Requests

-(NSURLSessionDataTask *)fetchUserWithURLSession:(NSURLSession *)urlSession
                                      completion:(void (^)(NSError *error))completionBlock;

-(NSArray *)fetchPostsOfUser:(User *)user
                  URLSession:(NSURLSession *)urlSession
                  completion:(void (^)(NSError *error))completionBlock;

@end
