//
//  ClientStore.h
//  NetworkObjectsClient
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

@class NOAPI, NOAPIStore, User;

@interface ClientStore : NSObject

- (id)initWithURL:(NSURL *)url
            error:(NSError **)error;

#pragma mark

@property (readonly) NOAPIStore *apiStore;

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

#pragma mark




@end
