//
//  NOServer.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOServer.h"

@implementation NOServer

@synthesize resourceUrls = _resourceUrls;

-(id)initWithContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        
        _context = context;
        
    }
    return self;
}

-(id)init
{
    self = [super init];
    if (self) {
        
        // created defualt context
        
        NSManagedObjectModel *model = [NSManagedObjectModel modelByMergingModels:nil];
        
        
        
    }
    return self;
}

#pragma mark 

-(NSDictionary *)resourceUrls
{
    // build a cache of NOResources and URLs
    if (!_resourceUrls) {
        
        // scan through entity descriptions
        NSManagedObjectModel *model = _context.persistentStoreCoordinator.managedObjectModel;
        
        for (NSEntityDescription *entityDescription in model.entities) {
            
            // check if entity class 
            
            entityDescription.name
            
        }
        
    }
    
    return _resourceUrls;
}

@end
