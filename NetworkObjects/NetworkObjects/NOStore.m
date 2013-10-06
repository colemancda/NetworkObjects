//
//  NOStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/2/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOStore.h"

@implementation NOStore

-(id)initWithManagedObjectModel:(NSManagedObjectModel *)model;
{
    self = [super init];
    if (self) {
        
        // load model
        if (!model) {
            model = [NSManagedObjectModel mergedModelFromBundles:nil];
        }
        
        // create context
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        _context.undoManager = nil;
        
    }
    return self;
}

-(id)init
{
    self = [self initWithManagedObjectModel:nil];
    return self;
}

#pragma mark

-(NSUInteger)numberOfInstancesOfResourceWithEntityDescription:(NSEntityDescription *)entityDescription
{
    __block NSUInteger count = 0;
    
    [_context performBlockAndWait:^{
        
        
        
    }];
    
    return count;
}



@end
