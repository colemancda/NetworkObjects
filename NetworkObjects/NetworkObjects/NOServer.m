//
//  NOServer.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOServer.h"
#import "RoutingHTTPServer.h"

@implementation NOServer

@synthesize resourceUrls = _resourceUrls;

- (id)initWithStore:(NOStore *)store
{
    self = [super init];
    if (self) {
        
        _store = store;
        
    }
    return self;
}

- (id)init
{
    [NSException raise:@"Wrong initialization method"
                format:@"You cannot use %@ with '-%@', you have to use '-%@'",
     self,
     NSStringFromSelector(_cmd),
     NSStringFromSelector(@selector(initWithStore:))];
    return nil;
}

#pragma mark

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
        NSManagedObjectModel *model = self.store.context.persistentStoreCoordinator.managedObjectModel;
        
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

#pragma mark 

-(void)setupServerRoutes
{
    // make server handle
    for (NSString *path in _resourceUrls) {
        
        NSString *instancePathExpression = [NSString stringWithFormat:@"/%@/(\\d+)", path];
        NSString *allInstancesPathExpression = [NSString stringWithFormat:@"/%@", path];
        
        void (^requestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
            
            [self handleRequest:request
                       response:response];
            
        };
        
        
        // GET (read resource)
        [_httpServer get:instancePathExpression
               withBlock:requestHandler];
        
        // PUT (edit resource)
        [_httpServer put:instancePathExpression
               withBlock:requestHandler];
        
        // DELETE (delete resource)
        [_httpServer delete:instancePathExpression
                  withBlock:requestHandler];
        
        
        // POST (create new resource)
        [_httpServer post:allInstancesPathExpression
                withBlock:requestHandler];
        
        // GET (get number of instances)
        [_httpServer get:allInstancesPathExpression
               withBlock:requestHandler];
    }
}

-(void)handleRequest:(RouteRequest *)request
            response:(RouteResponse *)response
{
    // determine what client and what user is making the request
    
    
    
    
    // determine what resource is being requested and whether it is requesting a specific instance...
    
    NSString *instancePathExpression = [NSString stringWithFormat:@"/:resource/(\\d+)", path];
    NSString *allInstancesPathExpression = [NSString stringWithFormat:@"/:resource", path];
    
    NSRegularExpression *instanceurlExpresson = [NSRegularExpression regularExpressionWithPattern:<#(NSString *)#> options:<#(NSRegularExpressionOptions)#> error:nil]
    
    
}


@end
