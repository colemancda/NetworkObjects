//
//  NetworkObjectsConstants.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 11/10/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#ifndef NetworkObjects_NetworkObjectsConstants_h
#define NetworkObjects_NetworkObjectsConstants_h

#define NetworkObjectsErrorDomain @"com.ColemanCDA.NetworkObjects.ErrorDomain"

// search parameters

typedef NS_ENUM(NSUInteger, NOSearchParameter) {
    
    NOSearchPredicateKeyParameter,
    NOSearchPredicateValueParameter,
    NOSearchPredicateOperatorParameter,
    NOSearchPredicateOptionParameter,
    NOSearchPredicateModifierParameter,
    NOSearchFetchLimitParameter,
    NOSearchFetchOffsetParameter,
    NOSearchIncludesSubentitiesParameter,
    NOSearchSortDescriptorsParameter
    
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

#endif
