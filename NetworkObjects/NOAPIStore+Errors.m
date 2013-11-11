//
//  NOAPIStore+Errors.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOAPIStore+Errors.h"

@implementation NOAPIStore (Errors)

-vali
{
    NSString *description = NSLocalizedString(@"The fetched entity is not a ", );
    
    return [NSError errorWithDomain:NetworkObjectsErrorDomain
                               code:NOAPIStoreFetchedEntityIsNotResourceErrorCode
                           userInfo:<#(NSDictionary *)#>];
}

@end
