//
//  NOAPICachedStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 11/16/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NetworkObjects/NOAPI.h>
#import <NetworkObjects/NOResourceProtocol.h>

@interface NOAPICachedStore : NSObject

@property NOAPI *api;

// have to add a persistent store for it to work

@property (readonly) NSManagedObjectContext *context;

#pragma mark - Requests

-(void)getResource:(NSString *)resourceName
        resourceID:(NSUInteger)resourceID
        completion:(void (^)(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource))completionBlock;

-(void)editResource:(NSManagedObject<NOResourceKeysProtocol>*)resource
            changes:(NSDictionary *)values
         completion:(void (^)(NSError *error))completionBlock;

-(void)deleteResource:(NSManagedObject<NOResourceKeysProtocol>*)resource
           completion:(void (^)(NSError *error))completionBlock;

-(void)createResource:(NSString *)resourceName
        initialValues:(NSDictionary *)initialValues
           completion:(void (^)(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource))completionBlock;

@end
