//
//  NOServer.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOServer.h"
#import "RoutingHTTPServer.h"
#import "NOResourceProtocol.h"

@implementation NOServer

@synthesize resourceUrls = _resourceUrls;

-(void)startOnPort:(NSUInteger)port
{
    
}

-(void)stop
{
    
    
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
            
            // check if entity class conforms to NOResourceProtocol
            
            Class entityClass = NSClassFromString(entityDescription.managedObjectClassName);
            
            BOOL conformsToNOResourceProtocol = [entityClass conformsToProtocol:@protocol(NOResourceProtocol)];
            
            if (conformsToNOResourceProtocol) {
                
                // map enitity to url path
                NSString *path = [entityClass resourcePath];
                
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
    // by defualt the url path is the entity's name, subclasses can override this to give them custom paths
    
    return entityDescription.name;
}

#pragma mark 

-(void)setupServerRoutes
{
    // make server handle
    for (NSString *path in _resourceUrls) {
        
        NSString *pathExpression = [NSString stringWithFormat:@"/%@/(\\d+)", path];
        NSString *postPathExpression = [NSString stringWithFormat:@"/%@", path];
        
        void (^requestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
            
            [self handleRequest:request
                       response:response];
            
        };
        
        // GET (read resource)
        [_httpServer get:pathExpression withBlock:requestHandler];
        
        // PUT (edit resource)
        [_httpServer put:pathExpression withBlock:requestHandler];
        
        // DELETE (delete resource)
        [_httpServer delete:pathExpression withBlock:requestHandler];
        
        // POST (create new resource)
        [_httpServer post:postPathExpression withBlock:requestHandler];
    }
}


@end
