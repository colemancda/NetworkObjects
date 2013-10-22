//
//  NOAPI.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOAPI : NSObject

@property NSManagedObjectModel *model;

@property NSURLSession *urlSession;

@property NSString *sessionEntityName;

@property NSString *userEntityName;

@property NSString *clientEntityName;

#pragma mark - Connection Info

@property BOOL prettyPrintJSON;

@property NSURL *serverURL;

@property NSString *loginPath;

@property NSNumber *clientResourceID;

@property NSString *clientSecret;

@property NSString *username;

@property NSString *userPassword;

@property NSString *sessionToken;

#pragma mark - Requests

-(void)loginWithCompletion:(void (^)(NSError *error))completionBlock;

-(void)getResource:(NSString *)resourceName
            withID:(NSUInteger)resourceID;

-(void)editResource:(NSString *)resourceName
             withID:(NSUInteger)resourceID
            changes:(NSDictionary *)changes;

-(void)deleteResource:(NSString *)resourceName
               withID:(NSUInteger)resourceID;

-(void)createResource:(NSString *)resourceName;

@end
