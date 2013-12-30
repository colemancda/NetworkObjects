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
    OKStatusCode = 200,
    
    /** Bad request status code. */
    BadRequestStatusCode = 400,
    
    /** Unauthorized status code. e.g. Used when authentication is required. */
    UnauthorizedStatusCode, // not logged in
    
    PaymentRequiredStatusCode,
    
    /** Forbidden status code. e.g. Used when permission is denied. */
    ForbiddenStatusCode, // item is invisible to user or api app
    
    /** Not Found status code. e.g. Used when a Resource instance cannot be found. */
    NotFoundStatusCode, // item doesnt exist
    
    /** Method Not Allowed status code. e.g. Used for invalid requests. */
    MethodNotAllowedStatusCode,
    
    /** Conflict status code. e.g. Used when a user with the specified username already exists. */
    ConflictStatusCode = 409, // user already exists
    
    /** Internal Server Error status code. e.g. Used when a JSON cannot be converted to NSData for a HTTP response. */
    InternalServerErrorStatusCode = 500
    
};

#endif
