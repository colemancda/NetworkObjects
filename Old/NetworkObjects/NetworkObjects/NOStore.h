//
//  NOStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/13/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol NOStoreWebSocketDelegate;

@interface NOStore : NSObject

#pragma mark - Initialization

/** Default initializer to use. Do not use -init. */

- (instancetype)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)psc
               managedObjectContextConcurrencyType:(NSManagedObjectContextConcurrencyType)managedObjectContextConcurrencyType
                                         serverURL:(NSURL *)serverURL
                            entitiesByResourcePath:(NSDictionary *)entitiesByResourcePath
                                   prettyPrintJSON:(BOOL)prettyPrintJSON
                           resourceIDAttributeName:(NSString *)resourceIDAttributeName
                           dateCachedAttributeName:(NSString *)dateCachedAttributeName NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

// must initialize the persistent store coordinator

/**
 Upon initialization, a @c NSManagedObjectContext is initialized without a persistent store coordinator. In order for this class to function properly assign a @c NSPersistentStoreCoordinator to this property. When initializng the @c NSPersistentStoreCoordinator make sure to use the same @c NSManagedObjectModel instance specified in @c self.model
 
 @see NSManagedObjectContext
 
 */

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

/** The string value that will be used to add a date attribute to all the resources that NOStore caches. */

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

/**  Resource path strings mapped to entity descriptions. */

@property (nonatomic, readonly) NSDictionary *entitiesByResourcePath;

/** The Web Socket that is connected to the server. */

@property (nonatomic, readonly) id webSocket;

@property (nonatomic) id<NOStoreWebSocketDelegate> webSocketDelegate;

#pragma mark - HTTP Requests

/** Performs a fetch request on the server and returns the results in the completion block. The fetch request results are filtered by the permissions the session has.
 
 @param fetchRequest The fetch request that will be used to perform the search.
 
 @param urlSession The URL session that will be used to create the data task. If this parameter is nil than the default URL session is used.
 
 @param completionBlock The completion block that will be called when a response is recieved from the server. If an error occurred then the completion block's @c error argument will be set to an @c NSError instance. If there is no error then the completion block's @c results argument will be set to an array of cached resource instances. Note that performing a search does not update the cached results' data which must be retrieved separately.
 
 @return The data task that is communicating with the server. The data task returned is already resumed.
 
 @warning Some of the properties of the fetch request have to use specific values. The entity specified in the fetch request must match an entity description in the store's @c model property. The only valid predicate class that can be used is @c NSComparisonPredicate and never set the predicate's @c predicateOperatorType to @c NSCustomSelectorPredicateOperatorType.
 */

-(NSURLSessionDataTask *)performSearchWithFetchRequest:(NSFetchRequest *)fetchRequest
                                            URLSession:(NSURLSession *)urlSession
                                            completion:(void (^)(NSError *error, NSArray *results))completionBlock;

-(NSURLSessionDataTask *)fetchEntityWithName:(NSString *)entityName
                                  resourceID:(NSNumber *)resourceID
                                  URLSession:(NSURLSession *)urlSession
                                  completion:(void (^)(NSError *error, NSManagedObject *managedObject))completionBlock;

-(NSURLSessionDataTask *)editManagedObject:(NSManagedObject *)managedObject
                                   changes:(NSDictionary *)values
                                URLSession:(NSURLSession *)urlSession
                                completion:(void (^)(NSError *error))completionBlock;

-(NSURLSessionDataTask *)deleteManagedObject:(NSManagedObject *)managedObject
                                  URLSession:(NSURLSession *)urlSession
                                  completion:(void (^)(NSError *error))completionBlock;

-(NSURLSessionDataTask *)createEntityWithName:(NSString *)entityName
                                initialValues:(NSDictionary *)initialValues
                                   URLSession:(NSURLSession *)urlSession
                                   completion:(void (^)(NSError *error, NSManagedObject *resource)) completionBlock;

-(NSURLSessionDataTask *)performFunction:(NSString *)functionName
                        forManagedObject:(NSManagedObject*)managedObject
                          withJSONObject:(NSDictionary *)jsonObject
                              URLSession:(NSURLSession *)urlSession
                              completion:(void (^)(NSError *error, NSNumber *statusCode, NSDictionary *jsonResponse))completionBlock;

#pragma mark - Web Socket Requests

-(void)connectToWebSocket;

-(void)performSearchWithFetchRequest:(NSFetchRequest *)fetchRequest;

-(void)fetchEntityWithName:(NSString *)entityName
                resourceID:(NSNumber *)resourceID;

-(void)editManagedObject:(NSManagedObject *)managedObject
                 changes:(NSDictionary *)values;

-(void)deleteManagedObject:(NSManagedObject *)managedObject;

-(void)createEntityWithName:(NSString *)entityName
              initialValues:(NSDictionary *)initialValues;

-(void)performFunction:(NSString *)functionName
      forManagedObject:(NSManagedObject*)managedObject
        withJSONObject:(NSDictionary *)jsonObject;

@end

@protocol NOStoreWebSocketDelegate <NSObject>

-(void)store:(NOStore *)store didConnectToWebSocketWithError:(NSError *)error;

-(void)store:(NOStore *)store didPerformSearchWithFetchRequest:(NSFetchRequest *)fetchRequest results:(NSArray *)results error:(NSError *)error;

@end
