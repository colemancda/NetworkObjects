//
//  ClientStore.h
//  NetworkObjectsClient
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NetworkObjects/NetworkObjects.h>
@import CoreData;

@class NOAPI, User, NOAPICachedStore;

@interface ClientStore : NSObject

+ (ClientStore *)sharedStore;

#pragma mark

@property (readonly) NOAPICachedStore *store;

@property (readonly) User *user;

#pragma mark - Authentication

-(void)loginWithUsername:(NSString *)username
                password:(NSString *)password
              completion:(void (^)(NSError *error))completionBlock;

-(void)registerWithUsername:(NSString *)username
                   password:(NSString *)password
                 completion:(void (^)(NSError *error))completionBlock;

#pragma mark - Requests

-(void)fetchPostsOfUser:(User *)user
             completion:(void (^)(NSError *error))completionBlock;



@end
