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

- (id)init
{
    [NSException raise:@"Wrong initialization method"
                format:@"You cannot use %@ with '-%@', you have to use '-%@'",
     self,
     NSStringFromSelector(_cmd),
     NSStringFromSelector(@selector(initWithContext:))];
    return nil;
}

#pragma mark - Mapping URLs to Entities

-(NSDictionary *)resourceUrls
{
    // build a cache of NOResources and URLs
    if (!_resourceUrls) {
        
        // scan through entity descriptions and get urls of NOResources
        NSManagedObjectModel *model = _context.persistentStoreCoordinator.managedObjectModel;
        
        NSMutableDictionary *urlsDict = [[NSMutableDictionary alloc] init];
        
        for (NSEntityDescription *entityDescription in model.entities) {
            
            // check if entity class is subclass of NOResource
            
            BOOL isNOResourceSubclass = [NSClassFromString(entityDescription.managedObjectClassName) isSubclassOfClass:[NOResource class]];
            
            if (isNOResourceSubclass) {
                
                // map enitity to url path
                NSString *path = [self pathForEntityDescription:entityDescription];
                
                // add to dictionary
                [urlsDict setValue:entityDescription
                            forKey:path];
            }
        }
        
        
        _resourceUrls = [NSDictionary dictionaryWithDictionary:urlsDict];
    }
    
    return _resourceUrls;
}

-(NSString *)pathForEntityDescription:(NSEntityDescription *)entityDescription
{
    // by defualt the url path is the entity's name, subclasses can override this to give have custom paths
    
    return entityDescription.name;
}

#pragma mark 



@end
