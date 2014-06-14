//
//  NOStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/13/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NOStore : NSObject

#pragma mark - Initialization

/** Default initializer to use. Do not use -init. */

- (instancetype)initWithOptions:(NSDictionary *)options;

#pragma mark - Cache

// must initialize the persistent store coordinator

/**
 Upon initialization, a @c NSManagedObjectContext is initialized without a persistent store coordinator. In order for this class to function properly assign a @c NSPersistentStoreCoordinator to this property. When initializng the @c NSPersistentStoreCoordinator make sure to use the same @c NSManagedObjectModel instance specified in @c self.model
 
 @see NSManagedObjectContext
 
 */

@property (nonatomic, readonly) NSManagedObjectContext *context;

/** The string value that will be used to add a date attribute to all the resources NOAPICachedStore caches. */

@property (nonatomic, readonly) NSString *dateCachedAttributeName;

/** The name of the Integer attribute that holds that resource identifier. */

@property (nonatomic, readonly) NSString *resourceIDAttributeName;

#pragma mark - Connection Info

/** The URL path that the NetworkObjects server uses for search requests. */

@property (nonatomic, readonly) NSString *searchPath;

/**
 This setting determines whether JSON requests made to the server will contain whitespace or not.
 
 @see NSJSONWritingPrettyPrinted
 */

@property (nonatomic, readonly) BOOL prettyPrintJSON;

/**
 The URL of the NetworkObjects server that this client will connect to.
 */

@property (nonatomic, readonly) NSURL *serverURL;

/**
 The resource ID of the client that this store will authenticate as. Can be @c nil. If set, @c clientSecret must be set to a valid value too.
 */

#pragma mark - Requests

/** Performs a fetch request on the server and returns the results in the completion block. The fetch request results are filtered by the permissions the session has.
 
 @param fetchRequest The fetch request that will be used to perform the search.
 
 @param urlSession The URL session that will be used to create the data task. If this parameter is nil than the default URL session is used.
 
 @param completionBlock The completion block that will be called when a response is recieved from the server. If an error occurred then the completion block's @c error argument will be set to an @c NSError instance. If there is no error then the completion block's @c results argument will be set to an array of cached resource instances. Note that performing a search does not update the cached results' data which must be retrieved separately.
 
 @return The data task that is communicating with the server. The data task returned is already resumed.
 
 @warning Some of the properties of the fetch request have to use specific values. The entity specified in the fetch request must match an entity description in the store's @c model property. The only valid predicate class that can be used is @c NSComparisonPredicate and never set the predicate's @c predicateOperatorType to @c NSCustomSelectorPredicateOperatorType.
 */

-(NSURLSessionDataTask *)searchForCachedResourceWithFetchRequest:(NSFetchRequest *)fetchRequest
                                                      URLSession:(NSURLSession *)urlSession
                                                      completion:(void (^)(NSError *error, NSArray *results))completionBlock;

-(NSURLSessionDataTask *)getCachedResource:(NSString *)resourceName
                                resourceID:(NSNumber *)resourceID
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
                              completion:(void (^)(NSError *error, NSNumber *statusCode, NSDictionary *jsonResponse))completionBlock

@end
