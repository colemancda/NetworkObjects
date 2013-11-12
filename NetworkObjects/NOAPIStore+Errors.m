//
//  NOAPIStore+Errors.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOAPIStore+Errors.h"

@implementation NOAPIStore (Errors)

-(NSError *)entityNotFoundError
{
    NSString *description = NSLocalizedString(@"Requested entity was not found in model",
                                              @"Requested entity was not found in model");
    
    return [NSError errorWithDomain:NetworkObjectsErrorDomain
                               code:NOAPIStoreFetchRequestEntityNotFoundErrorCode
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

-(NSError *)entityNotResourceError
{
    NSString *description = NSLocalizedString(@"The fetched entity is not a NOResource",
                                              @"The fetched entity is not a NOResource");
    
    return [NSError errorWithDomain:NetworkObjectsErrorDomain
                               code:NOAPIStoreFetchRequestEntityIsNotResourceErrorCode
                           userInfo:@{NSLocalizedDescriptionKey: description}];
    
}

@end
