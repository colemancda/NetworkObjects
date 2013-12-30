//
//  NOResourceProtocolConstants.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/12/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#ifndef NetworkObjects_NOResourceProtocolConstants_h
#define NetworkObjects_NOResourceProtocolConstants_h

/**
 Permission constants for Resources
 */

typedef NS_ENUM(NSUInteger, NOResourcePermission) {
    
    /**  No access permission */
    NoAccessPermission = 0,
    
    /**  Read Only permission */
    ReadOnlyPermission = 1,
    
    /**  Read and Write permission */
    EditPermission
    
};

/**
 Resource Function constants
 */
typedef NS_ENUM(NSUInteger, NOResourceFunctionCode) {
    
    /** The function performed successfully */
    FunctionPerformedSuccesfully = 200,
    
    /** The function recieved an invalid JSON object */
    FunctionRecievedInvalidJSONObject = 400,
    
    /** The function cannot be performed, possibly due to session permissions */
    CannotPerformFunction = 403,
    
    // ** There was an internal error while performing the function */
    InternalErrorPerformingFunction = 500
};

#endif
