//
//  NOIncrementalStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 3/28/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

@import CoreData;

// Initialization Options

/** Option used upon initializaton that specifies the @c NSURLSession the incremental store will be use. */

extern NSString *const NOIncrementalStoreURLSessionOption ;

extern NSString *const NOIncrementalStoreUserEntityNameOption;

extern NSString *const NOIncrementalStoreSessionEntityNameOption;

extern NSString *const NOIncrementalStoreClientEntityNameOption;

extern NSString *const NOIncrementalStoreLoginPathOption;

extern NSString *const NOIncrementalStoreSearchPathOption;

/**
 NOIncrementalStore error codes.
 */

typedef NS_ENUM(NSUInteger, NOIncrementalStoreErrorCode) {
    
    NOIncrementalStoreInvalidServerResponseErrorCode = 1000,
    NOIncrementalStoreLoginFailedErrorCode,
    NOIncrementalStoreBadRequestErrorCode,
    NOIncrementalStoreUnauthorizedErrorCode,
    NOIncrementalStoreForbiddenErrorCode,
    NOIncrementalStoreNotFoundErrorCode,
    NOIncrementalStoreServerInternalErrorCode,
    
};

/** Incremental store for communicating with a NetworkObjects server. */

@interface NOIncrementalStore : NSIncrementalStore

+(NSString *)storeType;

#pragma mark - Incremental Store Properties

@property (readonly) NSURLSession *urlSession;

#pragma mark - Server Schema and Authentication Properties

/**
 The name of the entity in the Managed Object Model that conforms to NOSessionProtocol. There should only be only entity that conforms to NOSessionProtocol in the Managed Object Model.
 */

@property (readonly) NSString *sessionEntityName;

/**
 The name of the entity in the Managed Object Model that conforms to NOUserProtocol. There should only be only entity that conforms to NOUserProtocol in the Managed Object Model.
 */

@property (readonly) NSString *userEntityName;

/**
 The name of the entity in the Managed Object Model that conforms to NOClientProtocol. There should only be only entity that conforms to NOClientProtocol in the Managed Object Model.
 */

@property (readonly) NSString *clientEntityName;

#pragma mark - Connection Info

/** The URL path that the NetworkObjects server uses for authentication. */

@property (readonly) NSString *loginPath;

/** The URL path that the NetworkObjects server uses for search requests. */

@property (readonly) NSString *searchPath;

/**
 This setting determines whether JSON requests made to the server will contain whitespace or not.
 
 @see NSJSONWritingPrettyPrinted
 */

@property BOOL prettyPrintJSON;

/**
 The resource ID of the client that this store will authenticate as. Can be @c nil. If set, @c clientSecret must be set to a valid value too.
 */

@property NSNumber *clientResourceID;

/**
 The secret of the client this store will authenticate as. This must be set to a valid value if @c clientResourceID is set.
 */

@property NSString *clientSecret;

/**
 The username of the user this store will use for authentication. If this is @c nil then the store will authenticate as a client only and not as a user. Note that if this is set then @c clientResourceID and @c clientSecret must be set to valid values.
 */

@property NSString *username;

/**
 The password of the user that this store will use for authentication. If this is set then @c username, @c clientResourceID and @c clientSecret must be set to valid values.
 */

@property NSString *userPassword;

/**
 The token for the current session. This will be set to a valid value when authentication is performed with @c -loginWithCompletion:. This can also be set to a value obtained from a session not in memory (archived value).
 */

@property NSString *sessionToken;

/**
 The Resource ID of the user that was authenticated. This will be set to a value when you authenticate as a user with @c -loginWithCompletion:.
 */

@property NSNumber *userResourceID;

#pragma mark - Special Requests

// These requests use JSON compatible values

/**
 Used to authenticate. Upon successful authentication this the session properties will set to a valid value.
 
 @param completionBlock This completion block must be non-nil.
 
 @return The data task that is communicating with the server. The data task returned is already resumed.
 
 */

-(NSURLSessionDataTask *)loginWithModel:(NSManagedObjectModel *)model
                             completion:(void (^)(NSError *error))completionBlock;

/**
 Performs a function on the instance of the specified resource. Functions are like Objective-C selectors. If that function is not defined then the server returns an error.
 
 @param functionName The name of the function that the specified resource instance will perform.
 
 @param resourceName Name of the entity that will be will perform the function. If this does not match a entity description in @c self.model then an exception is raised.
 
 @param resourceID An integer representing the unique identifier of an instance of the specified entity.
 
 @param jsonObject An optional JSON-compatible dictionary that can be used to add argument to the execution of the specified function.
 
 @param completionBlock The completion block that will be called when a response is recieved from the server. If an error occurred then the completion block's @c error argument will be set to an @c NSError instance. If there is no error then the completion block's @c statusCode argument will be set to a @c NOResourceFunctionCode value and the @c response argmument may be set to a JSON-compatible dictionary.
 
 @return The data task that is communicating with the server. The data task returned is already resumed.
 
 */

-(NSURLSessionDataTask *)performFunction:(NSString *)functionName
                              onResource:(NSString *)resourceName
                                  withID:(NSUInteger)resourceID
                          withJSONObject:(NSDictionary *)jsonObject
                                   model:(NSManagedObjectModel *)model
                              completion:(void (^)(NSError *error, NSNumber *statusCode, NSDictionary *response))completionBlock;

@end
