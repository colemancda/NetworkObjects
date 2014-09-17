//
//  NODefines.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/14/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

// search parameters

typedef NS_ENUM(NSUInteger, NOSearchParameter) {
    
    NOSearchParameterPredicateKey,
    NOSearchParameterPredicateValue,
    NOSearchParameterPredicateOperator,
    NOSearchParameterPredicateOption,
    NOSearchParameterPredicateModifier,
    NOSearchParameterFetchLimit,
    NOSearchParameterFetchOffset,
    NOSearchParameterIncludesSubentities,
    NOSearchParameterSortDescriptors
    
};

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

typedef NS_ENUM(NSInteger, NOServerConnectionType) {
    
    NOServerConnectionTypeHTTP = 1,
    NOServerConnectionTypeWebSocket
};


/** Identifies the server request type */

typedef NS_ENUM(NSInteger, NOServerRequestType) {
    
    /** Undetermined request */
    NOServerRequestTypeUndetermined = -1,
    
    /** GET request */
    NOServerRequestTypeGET = 1,
    
    /** PUT (edit) request */
    NOServerRequestTypePUT,
    
    /** DELETE request */
    NOServerRequestTypeDELETE,
    
    /** POST (create new) request */
    NOServerRequestTypePOST,
    
    /** Search request */
    NOServerRequestTypeSearch,
    
    /** Function request */
    NOServerRequestTypeFunction
    
};

/**
 Permission constants
 */

typedef NS_ENUM(NSInteger, NOServerPermission) {
    
    /**  No access permission */
    NOServerPermissionNoAccess = 0,
    
    /**  Read Only permission */
    NOServerPermissionReadOnly = 1,
    
    /**  Read and Write permission */
    NOServerPermissionEditPermission
    
};

/**
 Resource Function constants
 */
typedef NS_ENUM(NSUInteger, NOServerFunctionCode) {
    
    /** The function performed successfully */
    NOServerFunctionCodePerformedSuccesfully = 200,
    
    /** The function recieved an invalid JSON object */
    NOServerFunctionCodeRecievedInvalidJSONObject = 400,
    
    /** The function cannot be performed, possibly due to session permissions */
    NOServerFunctionCodeCannotPerformFunction = 403,
    
    /** There was an internal error while performing the function */
    NOServerFunctionCodeInternalErrorPerformingFunction = 500
};