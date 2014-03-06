//
//  NOAPICachedStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 11/16/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

@import Foundation;
@import CoreData;
#import <NetworkObjects/NOAPI.h>
#import <NetworkObjects/NOResourceProtocol.h>

/**
 This class uses a NOAPI property behind the scenes to communicate with a NetworkObjects server and cache them to a NSManagedObjectContext. It returns NSManagedObject instances that conform to NOResourceProtocol.
 */

@interface NOAPICachedStore : NOAPI
{
    /** Hierarchy of dictionaries with dates a resource with a particular resource ID was cached. */
    NSDictionary *_dateCached;
    
    /** Dictionary of NSOperationQueue for accessing a sub dictionary in @c _dateCached */
    NSDictionary *_dateCachedOperationQueues;
}

// must initialize the persistent store coordinator

/**
 Upon initialization, a @c NSManagedObjectContext is initialized without a persistent store coordinator. In order for this class to function properly assign a @c NSPersistentStoreCoordinator to this property. When initializng the @c NSPersistentStoreCoordinator make sure to use the same @c NSManagedObjectModel instance specified in @c self.model
 
 @see NSManagedObjectContext
 
 */

#pragma mark - Cache

@property (readonly) NSManagedObjectContext *context;

/** Returns the date when this Resource was cached (either downloaded or created) */

-(NSDate *)dateCachedForResource:(NSString *)resourceName
                      resourceID:(NSUInteger)resourceID;

#pragma mark - Requests

-(NSURLSessionDataTask *)getCachedResource:(NSString *)resourceName
                                resourceID:(NSUInteger)resourceID
                                URLSession:(NSURLSession *)urlSession
                                completion:(void (^)(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource))completionBlock;

-(NSURLSessionDataTask *)editCachedResource:(NSManagedObject<NOResourceKeysProtocol>*)resource
                                    changes:(NSDictionary *)values
                                 URLSession:(NSURLSession *)urlSession
                                 completion:(void (^)(NSError *error))completionBlock;

-(NSURLSessionDataTask *)deleteCachedResource:(NSManagedObject<NOResourceKeysProtocol>*)resource
                                   URLSession:(NSURLSession *)urlSession
                                   completion:(void (^)(NSError *error))completionBlock;

-(NSURLSessionDataTask *)createCachedResource:(NSString *)resourceName
                          initialValues:(NSDictionary *)initialValues
                             URLSession:(NSURLSession *)urlSession
                             completion:(void (^)(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource)) completionBlock;

-(NSURLSessionDataTask *)performFunction:(NSString *)functionName
                        onCachedResource:(NSManagedObject<NOResourceKeysProtocol>*)resource
                          withJSONObject:(NSDictionary *)jsonObject
                              URLSession:(NSURLSession *)urlSession
                              completion:(void (^)(NSError *error, NSNumber *statusCode, NSDictionary *jsonResponse))completionBlock;

@end
