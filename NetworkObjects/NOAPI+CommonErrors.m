//
//  NOAPI+CommonErrors.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 3/26/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOAPI+CommonErrors.h"

@implementation NOAPI (CommonErrors)

-(NSError *)invalidServerResponseError
{
    
    NSString *description = NSLocalizedString(@"The server returned a invalid response",
                                              @"The server returned a invalid response");
    
    NSError *error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                code:NOAPIInvalidServerResponseErrorCode
                            userInfo:@{NSLocalizedDescriptionKey: description}];
    
    return error;
}

-(NSError *)badRequestError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"Invalid request",
                                                  @"Invalid request");
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOAPIBadRequestErrorCode
                                userInfo:@{NSLocalizedDescriptionKey: description}];
        
    }
    
    return error;
}

-(NSError *)serverError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"The server suffered an internal error",
                                                  @"The server suffered an internal error");
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOAPIServerInternalErrorCode
                                userInfo:@{NSLocalizedDescriptionKey: description}];
        
    }
    
    return error;
}

-(NSError *)unauthorizedError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"Authentication is required",
                                                  @"Authentication is required");
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOAPIUnauthorizedErrorCode
                                userInfo:@{NSLocalizedDescriptionKey: description}];
    }
    
    return error;
}

-(NSError *)notFoundError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"Resource was not found",
                                                  @"Resource was not found");
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOAPINotFoundErrorCode
                                userInfo:@{NSLocalizedDescriptionKey: description}];
    }
    
    return error;
}

@end
