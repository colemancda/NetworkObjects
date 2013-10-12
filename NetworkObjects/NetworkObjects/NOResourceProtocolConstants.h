//
//  NOResourceProtocolConstants.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/12/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#ifndef NetworkObjects_NOResourceProtocolConstants_h
#define NetworkObjects_NOResourceProtocolConstants_h

typedef NS_ENUM(NSUInteger, NOResourcePermission) {
    
    NoAccessPermission = 0,
    ReadOnlyPermission = 1,
    EditPermission
    
};

typedef NS_ENUM(NSUInteger, NOResourceFunctionCode) {
    
    FunctionPerformedSuccesfully = 200,
    FunctionRecievedInvalidJSONObject = 400,
    CannotPerformFunction = 403,
    InternalErrorPerformingFunction = 500
};

#endif
