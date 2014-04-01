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

@interface SNCStore : NSObject

+(instancetype)sharedStore;

#pragma mark - Properties

@property (readonly) User *user;

@property (readonly) NSManagedObjectContext *cacheContext;

@property (readonly) NSManagedObjectContext *incrementalContext;

@property (readonly) NOIncrementalStore *incrementalStore;

#pragma mark - Actions

/** Creates a new incremental store and context that will sync with the cache */

-(NOIncrementalStore *)newIncrementalStoreWithURLSession:(NSURLSession *)urlSession context:(NSManagedObjectContext **)context;

-(void)deleteIncrementalContext:(NSManagedObjectContext *)context;

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


@end
