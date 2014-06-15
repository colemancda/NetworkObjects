//
//  NOError.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/14/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString const* NOErrorDomain;

/**
 NetworkObjects Error code
 */
typedef NS_ENUM(NSUInteger, NOErrorCode) {
    
    /** OK status code. */
    NOErrorCodeServerStatusCodeOK = 200,
    
    /** Bad request status code. */
    NOErrorCodeServerStatusCodeBadRequest = 400,
    
    /** Unauthorized status code. e.g. Used when authentication is required. */
    NOErrorCodeServerStatusCodeUnauthorized, // not logged in
    
    NOErrorCodeServerStatusCodePaymentRequired,
    
    /** Forbidden status code. e.g. Used when permission is denied. */
    NOErrorCodeServerStatusCodeForbidden, // item is invisible to user or api app
    
    /** Not Found status code. e.g. Used when a Resource instance cannot be found. */
    NOErrorCodeServerStatusCodeNotFound, // item doesnt exist
    
    /** Method Not Allowed status code. e.g. Used for invalid requests. */
    NOErrorCodeServerStatusCodeMethodNotAllowed,
    
    /** Conflict status code. e.g. Used when a user with the specified username already exists. */
    NOErrorCodeServerStatusCodeConflict = 409, // user already exists
    
    /** Internal Server Error status code. e.g. Used when a JSON cannot be converted to NSData for a HTTP response. */
    NOErrorCodeServerStatusCodeInternalServerError = 500,
    
    /** Server returned an invalid response. */
    NOErrorCodeInvalidServerResponse = 1000
    
};