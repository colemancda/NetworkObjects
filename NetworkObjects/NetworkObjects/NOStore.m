//
//  NOStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/2/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOStore.h"

@implementation NOStore

-(id)initWithContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        
        _context = context;
        
    }
    return self;
}

- (id)init
{
    [NSException raise:@"Wrong initialization method"
                format:@"You cannot use %@ with '-%@', you have to use '-%@'",
     self,
     NSStringFromSelector(_cmd),
     NSStringFromSelector(@selector(initWithContext:))];
    return nil;
}

#pragma mark



@end
