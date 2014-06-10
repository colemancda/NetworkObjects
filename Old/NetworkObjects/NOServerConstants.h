//
//  NOServerConstants.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 11/10/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#ifndef NetworkObjects_NOServerConstants_h
#define NetworkObjects_NOServerConstants_h

/**
 These are HTTP status codes used with NOServer instances.
 */
typedef NS_ENUM(NSUInteger, NOServerStatusCode) {
    
    /** OK status code. */
    NOServerOKStatusCode = 200,
    
    /** Bad request status code. */
    NOServerBadRequestStatusCode = 400,
    
    /** Unauthorized status code. e.g. Used when authentication is required. */
    NOServerUnauthorizedStatusCode, // not logged in
    
    NOServerPaymentRequiredStatusCode,
    
    /** Forbidden status code. e.g. Used when permission is denied. */
    NOServerForbiddenStatusCode, // item is invisible to user or api app
    
    /** Not Found status code. e.g. Used when a Resource instance cannot be found. */
    NOServerNotFoundStatusCode, // item doesnt exist
    
    /** Method Not Allowed status code. e.g. Used for invalid requests. */
    NOServerMethodNotAllowedStatusCode,
    
    /** Conflict status code. e.g. Used when a user with the specified username already exists. */
    NOServerConflictStatusCode = 409, // user already exists
    
    /** Internal Server Error status code. e.g. Used when a JSON cannot be converted to NSData for a HTTP response. */
    NOServerInternalServerErrorStatusCode = 500
    
};

typedef NS_ENUM(NSInteger, NOServerRequestType) {
    
    /** GET request */
    NOServerGETRequestType,
    
    /** PUT (edit) request */
    NOServerPUTRequestType,
    
    /** DELETE request */
    NOServerDELETERequestType,
    
    /** POST (create new) request */
    NOServerPOSTRequestType,
    
    /** Login request */
    NOServerLoginRequestType,
    
    /** Search request */
    NOServerSearchRequestType,
    
    /** Search request */
    NOServerFunctionRequestType,
    
    /** Undetermined request */
    NOServerUndeterminedRequestType
    
};

#endif
