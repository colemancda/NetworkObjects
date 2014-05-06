//
//  NOServer.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

@import Foundation;
@import CoreData;
#import <NetworkObjects/NOServerConstants.h>

@class NOStore, RouteRequest, RouteResponse, NOHTTPServer;

@protocol NOResourceProtocol;
@protocol NOSessionProtocol;
@protocol NOServerInternalErrorDelegate;

// Initialization Options

extern NSString *const NOServerStoreOption;

extern NSString *const NOServerUserEntityNameOption;

extern NSString *const NOServerSessionEntityNameOption;

extern NSString *const NOServerClientEntityNameOption;

extern NSString *const NOServerLoginPathOption;

extern NSString *const NOServerSearchPathOption;

/**
 This is the server class that broadcasts the Core Data entities in a NOStore (called Resources) over the network. You should always stop the server before modifying a nonatomic property.
 */

@interface NOServer : NSObject

/**
 The supported initializer for this class. Do not use -init as it will raise an exception. All parameters must not non-nil.
 
 @param store The NOStore this server will broadcast. Note that only subclasses of NSManagedObject that conform to NOResourceProtocol will be broadcasted.
 
 @param userEntityName The name of the entity that will represent users. It must conform to NOUserProtocol.
 
 @param sessionEntityName The name of the entity that will represent authentication sessions. It must conform to NOSessionProtocol.

 @param clientEntityName The name of the entity that will represents clients that can connect to the server. It must conform to NOClientProtocol.

 @param loginPath This string will be the URL that will be used to authenticate. It must not conflict with any of the resourcePath values that the Resources return.
 
 @return A fully initialized NOServer instance.
 
 @see NOStore

 */

-(instancetype)initWithOptions:(NSDictionary *)options;

/**
 The NOStore that NOServer will broadcast.
 
 @see NOStore
 */

@property (nonatomic, readonly) NOStore *store;

/**
 The underlying HTTP server that accepts incoming connections.
 
 @see CocoaHTTPServer
 
 */

@property (nonatomic, readonly) NOHTTPServer *httpServer;

/**
 The name of the entity in NOStore's Managed Object Model that conforms to NOSessionProtocol. There should only be only entity that conforms to NOSessionProtocol in the NOStore's Managed Object Model.
 */

@property (nonatomic, readonly) NSString *sessionEntityName;

/**
 The name of the entity in NOStore's Managed Object Model that conforms to NOUserProtocol. There should only be only entity that conforms to NOUserProtocol in the NOStore's Managed Object Model.
 */

@property (nonatomic, readonly) NSString *userEntityName;

/**
 The name of the entity in NOStore's Managed Object Model that conforms to NOClientProtocol. There should only be only entity that conforms to NOClientProtocol in the NOStore's Managed Object Model.
 */

@property (nonatomic, readonly) NSString *clientEntityName;

/**
 This will be the URL that clients will use to authenticate. This string must be different from the values that NOStore's Resources return in @c +(NSString *)resourcePath.
 */

@property (nonatomic, readonly) NSString *loginPath;

/** The URL that clients will use to perform a remote fetch request. This string must be different from the values that NOStore's Resources return in @c +(NSString *)resourcePath
 */

@property (nonatomic, readonly) NSString *searchPath;

/**
 This dictionary is lazily initialized and maps NSEntityDescriptions to resourcePaths for REST URL generation.
 
 @see NOResourceProtocol
 */

@property (nonatomic, readonly) NSDictionary *resourcePaths;

/**
 This setting defines whether the JSON output generated should be pretty printed (contain whitespacing for human readablility) or not.
 
 @see NSJSONWritingPrettyPrinted
 
 */

@property (nonatomic) BOOL prettyPrintJSON;

/**
 * To enable HTTPS for all incoming connections set this value to an array appropriate for use in kCFStreamSSLCertificates SSL Settings.
 * It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
 **/

@property (nonatomic) NSArray *sslIdentityAndCertificates;

/** Set of NSNumbers containing the value of a NSPredicateOperatorType that are valid comparators for the server's search capabilities. This can be used to disable conputationally intensive tasks, like string comparators. */

@property (nonatomic) NSSet *allowedOperatorsForSearch;

/** Delegate that conforms to @c NOServerInternalErrorDelegate that will be called when internal errors occur */

@property (nonatomic) id<NOServerInternalErrorDelegate> errorDelegate;

/**
 Start the HTTP REST server on the specified port.
 
 @param port Can be 0 for a random port or a specific port.
 
 @return An @c NSError describing the error if there was one or @c nil if there was none.
 
 @see CocoaHTTPServer
 */

-(NSError *)startOnPort:(NSUInteger)port;

/**
 Stops broadcasting the NOStore over the network.
 */

-(void)stop;

#pragma mark - Common methods for handlers

/**
 Fetches a Session Resource that has the specified token.
 
 @param token A NSString value representing the token of a session.
 
 @return Returns an NSManagedObject subclass that conforms to NOSessionProtocol for the specified token or @c nil if none was found.
 
 */
-(NSManagedObject<NOSessionProtocol> *)sessionWithToken:(NSString *)token
                                                  error:(NSError **)error;

/**
 Generates a JSON representation of a Resource based on the session requesting the Resource instance.
 
 @param resource A NSManagedObject subclass that conforms to NOResourceProtocol. This is the Resource that will be represented by the returned JSON dictionary.
 
 @param session The session that is requesting the JSON representation of the @c resource.
 
 @return Returns an NSDictionary with values that are JSON compatible representing the Resource instance requested and filters attributes or relationships that the requesting session does not have permission to view.
 
 Note that attributes are converted from their Core Data values to JSON compatible values. Transformable or Undefined attributes are ommitted. Relationships are represented by their Resource IDs.
 
 @see NOResourceProtocol
 
 */

-(NSDictionary *)JSONRepresentationOfResource:(NSManagedObject<NOResourceProtocol> *)resource
                                   forSession:(NSManagedObject<NOSessionProtocol> *)session;

/**
 Goes through the JSON dictionary representing edit values a session submits and checks for the session's permission to change those values and also if those values are valid.
 Returns a @c NOServerStatusCode based on the requesting session's permission to view the Resource and the validity of the subitted JSON object.
 
 @param resource The resource that the edits will be applied to.
 
 @param recievedJsonObject The JSON object representing the edits the @c session wants to apply.
 
 @param session The session that wants to apply the edits.
 
 @return Returns @c OKStatusCode if the session can apply the edit, @c BadRequestStatusCode if the JSON object is invalid, or @c ForbiddenStatusCode if the session does not have permission the edit the values.
 
 @see NOServerStatusCode
 
 */

-(NOServerStatusCode)verifyEditResource:(NSManagedObject<NOResourceProtocol> *)resource
                     recievedJsonObject:(NSDictionary *)recievedJsonObject
                                session:(NSManagedObject<NOSessionProtocol> *)session
                                  error:(NSError **)error;

/**
 Applies the the edits to a Resource instance from a valid JSON object. The JSON object should be verified first to avoid errors.
 
 */

-(BOOL)setValuesForResource:(NSManagedObject<NOResourceProtocol> *)resource
             fromJSONObject:(NSDictionary *)jsonObject
                    session:(NSManagedObject<NOSessionProtocol> *)session
                      error:(NSError **)error;


@end

#pragma mark - NOServerInternalErrorDelegate

@protocol NOServerInternalErrorDelegate <NSObject>

-(void)server:(NOServer *)server didEncounterInternalError:(NSError *)error forRequestType:(NOServerRequestType)requestType;

@end
