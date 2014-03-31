//
//  NOAPI.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

@import Foundation;
@import CoreData;

// Initialization Options

extern NSString *const NOAPIModelOption;

extern NSString *const NOAPIUserEntityNameOption;

extern NSString *const NOAPISessionEntityNameOption;

extern NSString *const NOAPIClientEntityNameOption;

extern NSString *const NOAPILoginPathOption;

extern NSString *const NOAPISearchPathOption;

/**
 NOAPI error codes.
 */

typedef NS_ENUM(NSUInteger, NOAPIErrorCode) {
    
    NOAPIInvalidServerResponseErrorCode = 1000,
    NOAPILoginFailedErrorCode,
    NOAPIBadRequestErrorCode,
    NOAPIUnauthorizedErrorCode,
    NOAPIForbiddenErrorCode,
    NOAPINotFoundErrorCode,
    NOAPIServerInternalErrorCode,
    
};

/**
 This is a store that clients can use to communicate with a NetworkObjects server. This returns JSON objects for requests. This object represents a server's schema and holds authentication parameters.
 
 @see NOAPICachedStore
 */

@interface NOAPI : NSObject

#pragma mark - Initialization

/** Default initializer to use. Do not use -init. */

- (instancetype)initWithOptions:(NSDictionary *)options;





@end
