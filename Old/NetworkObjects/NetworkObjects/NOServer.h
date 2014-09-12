//
//  NOServer.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/12/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <NetworkObjects/NODefines.h>

#import "RoutingConnection.h"
#import "RoutingHTTPServer.h"
#import "WebSocket.h"

@protocol NOServerDelegate;
@protocol NOServerDataSource;

@class NOHTTPServer, NOWebSocket, NOServerRequest, NOServerResponse;

extern NSString const* NOServerFetchRequestKey;

extern NSString const* NOServerResourceIDKey;

extern NSString const* NOServerManagedObjectKey;

extern NSString const* NOServerManagedObjectContextKey;

extern NSString const* NOServerNewValuesKey;

extern NSString const* NOServerFunctionNameKey;

extern NSString const* NOServerFunctionJSONInputKey;

extern NSString const* NOServerFunctionJSONOutputKey;

@interface NOServer : NSObject
{
    NSDictionary *_entitiesByResourcePath;
}

#pragma mark - Initializer

-(instancetype)initWithDataSource:(id<NOServerDataSource>)dataSource
                         delegate:(id<NOServerDelegate>)delegate
               managedObjectModel:(NSManagedObjectModel *)managedObjectModel
                       searchPath:(NSString *)searchPath
          resourceIDAttributeName:(NSString *)resourceIDAttributeName
                  prettyPrintJSON:(BOOL)prettyPrintJSON
       sslIdentityAndCertificates:(NSArray *)sslIdentityAndCertificates NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

@property (nonatomic, readonly) id<NOServerDataSource> dataSource;

@property (nonatomic, readonly) id<NOServerDelegate> delegate;

@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;

/** The URL that clients will use to perform a remote fetch request. Must not conflict with the resourcePath of entities.
 */

@property (nonatomic, readonly) NSString *searchPath;

/**
 This setting defines whether the JSON output generated should be pretty printed (contain whitespacing for human readablility) or not.
 
 @see NSJSONWritingPrettyPrinted
 
 */

@property (nonatomic, readonly) BOOL prettyPrintJSON;

/**
 * To enable HTTPS for all incoming connections set this value to an array appropriate for use in kCFStreamSSLCertificates SSL Settings.
 * It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
 **/

@property (nonatomic, readonly) NSArray *sslIdentityAndCertificates;

@property (nonatomic, readonly) NOHTTPServer *httpServer;

@property (nonatomic, readonly) NSString *resourceIDAttributeName;

#pragma mark - Server Control

/**
 Start the HTTP REST server on the specified port.
 
 @param port Can be 0 for a random port or a specific port.
 
 @return An @c NSError describing the error if there was one or @c nil if there was none.
 
 @see CocoaHTTPServer
 */

-(BOOL)startOnPort:(NSUInteger)port
             error:(NSError **)error;

/**
 Stops broadcasting the NOStore over the network.
 */

-(void)stop;

#pragma mark - Caches

/**  Resource path strings mapped to entity descriptions. */

@property (nonatomic, readonly) NSDictionary *entitiesByResourcePath;

#pragma mark - Request Handlers

-(NOServerResponse *)responseForSearchRequest:(NOServerRequest *)request userInfo:(NSDictionary **)userInfo;

-(NOServerResponse *)responseForCreateNewInstanceRequest:(NOServerRequest *)request userInfo:(NSDictionary **)userInfo;

-(NOServerResponse *)responseForGetInstanceRequest:(NOServerRequest *)request userInfo:(NSDictionary **)userInfo;

-(NOServerResponse *)responseForEditInstanceRequest:(NOServerRequest *)request userInfo:(NSDictionary **)userInfo;

-(NOServerResponse *)responseForDeleteInstanceRequest:(NOServerRequest *)request userInfo:(NSDictionary **)userInfo;

-(NOServerResponse *)responseForFunctionInstanceRequest:(NOServerRequest *)request userInfo:(NSDictionary **)userInfo;

@end

#pragma mark - Protocols

@protocol NOServerDelegate <NSObject>

-(void)server:(NOServer *)server didEncounterInternalError:(NSError *)error forRequest:(NOServerRequest *)request userInfo:(NSDictionary *)userInfo;

-(NOServerStatusCode)server:(NOServer *)server statusCodeForRequest:(NOServerRequest *)request userInfo:(NSDictionary *)userInfo;

-(void)server:(NOServer *)server didPerformRequest:(NOServerRequest *)request withResponse:(NOServerResponse *)response userInfo:(NSDictionary *)userInfo;

@optional

-(NOServerPermission)server:(NOServer *)server permissionForRequest:(NOServerRequest *)request managedObject:(NSManagedObject *)managedObject context:(NSManagedObjectContext *)context key:(NSString *)key;


@end

@protocol NOServerDataSource <NSObject>

-(NSManagedObjectContext *)server:(NOServer *)server managedObjectContextForRequest:(NOServerRequest *)request;

-(NSNumber *)server:(NOServer *)server newResourceIDForEntity:(NSEntityDescription *)entity;

-(NSString *)server:(NOServer *)server resourcePathForEntity:(NSEntityDescription *)entity;

-(NSSet *)server:(NOServer *)server functionsForEntity:(NSEntityDescription *)entity;

@optional

-(NOServerFunctionCode)server:(NOServer *)server performFunction:(NSString *)functionName forManagedObject:(NSManagedObject *)managedObject context:(NSManagedObjectContext *)context recievedJsonObject:(NSDictionary *)recievedJsonObject response:(NSDictionary **)jsonObjectResponse;

@end

#pragma mark - Related Classes

typedef void (^NOWebSocketCommandBlock)(NSDictionary *parameters, NOWebSocket *webSocket);

@interface NOHTTPServer : RoutingHTTPServer
{
    NSMutableArray *_webSocketCommands;
}

@property (nonatomic) NOServer *server;

@property (nonatomic, readonly) NSArray *webSocketCommands;

-(void)addWebSocketCommandForExpression:(NSString *)expressionString
                                  block:(NOWebSocketCommandBlock)block;

- (void)webSocket:(NOWebSocket *)webSocket didReceiveMessage:(NSString *)message;

@end

@interface NOHTTPConnection : RoutingConnection

@end

/** This class abstracts the requests objects that vary according the to connection protocol. It contains the request parameters that are common to any request regardless of what connection protocol is being used.
 */

@interface NOServerRequest : NSObject

@property (nonatomic) NOServerRequestType requestType;

@property (nonatomic) NOServerConnectionType connectionType;

@property (nonatomic) NSEntityDescription *entity;

/** The resourceID of the requested instance. Will be nil for @c POST (search or create instance) requests. */

@property (nonatomic) NSNumber *resourceID;

@property (nonatomic) NSDictionary *JSONObject;

@property (nonatomic) NSString *functionName;

/** The original request object.
 
 If the reciever's connectionType is @c NOServerConnectionTypeHTTP, then this will be an instance of @c RouteRequest.
 
 */

@property (nonatomic) id underlyingRequest;

@end

@interface NOServerResponse : NSObject

@property (nonatomic) NOServerStatusCode statusCode;

/** A JSON-compatible array or dictionary that will be sent as a response. */

@property (nonatomic) id JSONResponse;

@end

@interface NOWebSocket : WebSocket

@property (nonatomic) NOHTTPServer *server;

@end

@interface NOWebSocketCommand : NSObject

@property (nonatomic) NSRegularExpression *regularExpression;

@property (nonatomic, copy) NOWebSocketCommandBlock block;

@property (nonatomic) NSArray *keys;

@end


