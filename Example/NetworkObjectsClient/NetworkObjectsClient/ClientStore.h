//
//  ClientStore.h
//  NetworkObjectsClient
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

@class NOAPI, User;

@interface ClientStore : NSObject

+ (ClientStore *)sharedStore;

#pragma mark

@property (readonly) NOAPI *api;

@property (readonly) NSManagedObjectContext *context;

@property (readonly) User *user;

@property (readonly) NSString *token;

#pragma mark - Authentication

-(void)loginWithUsername:(NSString *)username
                password:(NSString *)password
              completion:(void (^)(NSError *error))completionBlock;

-(void)registerWithUsername:(NSString *)username
                   password:(NSString *)password
                 completion:(void (^)(NSError *error))completionBlock;

#pragma mark - Cache or 




@end
