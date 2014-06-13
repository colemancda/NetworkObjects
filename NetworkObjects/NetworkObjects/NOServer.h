//
//  NOServer.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/12/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol NOServerDelegate;
@protocol NOServerDataSource;

@class RouteRequest, RouteResponse;

/**
 These are HTTP status codes used with NOServer instances.
 */
typedef NS_ENUM(NSUInteger, NOServerStatusCode) {
    
    /** OK status code. */
    NOServerStatusCodeOK = 200,
    
    /** Bad request status code. */
    NOServerStatusCodeBadRequest = 400,
    
    /** Unauthorized status code. e.g. Used when authentication is required. */
    NOServerStatusCodeUnauthorized, // not logged in
    
    NOServerStatusCodePaymentRequired,
    
    /** Forbidden status code. e.g. Used when permission is denied. */
    NOServerStatusCodeForbidden, // item is invisible to user or api app
    
    /** Not Found status code. e.g. Used when a Resource instance cannot be found. */
    NOServerStatusCodeNotFound, // item doesnt exist
    
    /** Method Not Allowed status code. e.g. Used for invalid requests. */
    NOServerStatusCodeMethodNotAllowed,
    
    /** Conflict status code. e.g. Used when a user with the specified username already exists. */
    NOServerStatusCodeConflict = 409, // user already exists
    
    /** Internal Server Error status code. e.g. Used when a JSON cannot be converted to NSData for a HTTP response. */
    NOServerStatusCodeInternalServerError = 500
    
};

typedef NS_ENUM(NSInteger, NOServerRequestType) {
    
    /** Undetermined request */
    NOServerRequestTypeUndetermined = -1,
    
    /** GET request */
    NOServerRequestTypeGET = 1,
    
    /** PUT (edit) request */
    NOServerRequestTypePUT,
    
    /** DELETE request */
    NOServerRequestTypeDelete,
    
    /** POST (create new) request */
    NOServerRequestTypePOST,
    
    /** Search request */
    NOServerRequestTypeSearch,
    
    /** Function request */
    NOServerRequestTypeFunction
    
};

@interface NOServer : NSObject



@end


@protocol NOServerDelegate <NSObject>

-(void)server:(NOServer *)server didEncounterInternalError:(NSError *)error forRequestType:(NOServerRequestType)requestType;

-(BOOL)server:(NOServer *)server canPerformRequest:(RouteRequest *)request withType:(NOServerRequestType)requestType entity:(NSEntityDescription *)entity contetxt:(NSManagedObjectContext *)context;

-(void)server:(NOServer *)server didPerformRequest:(RouteRequest *)request withType:(NOServerRequestType)requestType;


@end