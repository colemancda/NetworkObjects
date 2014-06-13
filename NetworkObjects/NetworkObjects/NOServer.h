//
//  NOServer.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/12/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <NetworkObjects/NetworkObjectsConstants.h>

@protocol NOServerDelegate;
@protocol NOServerDataSource;

@class RouteRequest, RouteResponse, NOHTTPServer, NOHTTPServer;

@interface NOServer : NSObject
{
    NSDictionary *_resourcePaths;
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

-(NSDictionary *)resourcePaths;

#pragma mark - Internal Methods

-(void)handleSearchRequest:(RouteRequest *)request
                 forEntity:(NSEntityDescription *)entity
                  response:(RouteResponse *)response;

-(void)handleCreateNewInstanceRequest:(RouteRequest *)request
                            forEntity:(NSEntityDescription *)entity
                             response:(RouteResponse *)response;

-(void)handleGetInstanceRequest:(RouteRequest *)request
                      forEntity:(NSEntityDescription *)entity
                     resourceID:(NSNumber *)resourceID
                       response:(RouteResponse *)response;

-(void)handleEditInstanceRequest:(RouteRequest *)request
                       forEntity:(NSEntityDescription *)entity
                      resourceID:(NSNumber *)resourceID
                        response:(RouteResponse *)response;

-(void)handleDeleteInstanceRequest:(RouteRequest *)request
                         forEntity:(NSEntityDescription *)entity
                        resourceID:(NSNumber *)resourceID
                          response:(RouteResponse *)response;

-(void)handleFunctionInstanceRequest:(RouteRequest *)request
                           forEntity:(NSEntityDescription *)entity
                          resourceID:(NSNumber *)resourceID
                        functionName:(NSString *)functionName
                            response:(RouteResponse *)response;

@end


@protocol NOServerDelegate <NSObject>

-(void)server:(NOServer *)server didEncounterInternalError:(NSError *)error forRequestType:(NOServerRequestType)requestType;

-(NOServerStatusCode)server:(NOServer *)server statusCodeForRequest:(RouteRequest *)request withType:(NOServerRequestType)requestType entity:(NSEntityDescription *)entity userInfo:(NSDictionary *)userInfo;

-(void)server:(NOServer *)server didPerformRequest:(RouteRequest *)request withType:(NOServerRequestType)requestType userInfo:(NSDictionary *)userInfo;


@end

@protocol NOServerDataSource <NSObject>

-(NSManagedObjectContext *)server:(NOServer *)server managedObjectContextForRequest:(RouteRequest *)request;

-(NSNumber *)server:(NOServer *)server newResourceIDForEntity:(NSEntityDescription *)entity;

-(NSString *)server:(NOServer *)server resourcePathForEntity:(NSEntityDescription *)entity;

-(NSSet *)server:(NOServer *)server functionsForEntity:(NSEntityDescription *)entity;

@end
