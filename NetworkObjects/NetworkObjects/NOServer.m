//
//  NOServer.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOServer.h"
#import "RoutingHTTPServer.h"
#import "NOStore.h"
#import "NOResourceProtocol.h"
#import "NOSessionProtocol.h"
#import "NOUserProtocol.h"
#import "NOClientProtocol.h"

@implementation NOServer (NSJSONWritingOption)

-(NSJSONWritingOptions)jsonWritingOption
{
    if (self.prettyPrintJSON) {
        return NSJSONWritingPrettyPrinted;
    }
    
    return 0;
}

@end

@implementation NOServer

@synthesize resourcePaths = _resourcePaths;

- (id)initWithStore:(NOStore *)store
{
    self = [super init];
    if (self) {
        
        NSAssert(store, @"NOStore cannot be nil");
        
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

-(NSDictionary *)resourcePaths
{
    // build a cache of NOResources and URLs
    if (!_resourcePaths) {
        
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
        
        _resourcePaths = [NSDictionary dictionaryWithDictionary:urlsDict];
    }
    
    return _resourcePaths;
}

#pragma mark 

-(void)setupServerRoutes
{
    // configure internal HTTP server routes
    for (NSString *path in _resourcePaths) {
        
        // get entity description
        
        NSEntityDescription *entityDescription = _resourcePaths[path];
        
        Class entityClass = NSClassFromString(entityDescription.managedObjectClassName);
        
        // setup routes for resources
        
        NSString *allInstancesPathExpression = [NSString stringWithFormat:@"/%@", path];
        
        void (^allInstancesRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
            
            [self handleRequest:request
forResourceWithEntityDescription:entityDescription
                     resourceID:nil
                       function:nil
                       response:response];
        };
        
        // POST (create new resource)
        [_httpServer post:allInstancesPathExpression
                withBlock:allInstancesRequestHandler];
        
        // setup routes for resource instances
        
        NSString *instancePathExpression = [NSString stringWithFormat:@"/%@/(\\d+)", path];
        
        void (^instanceRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
            
            NSArray *captures = request.params[@"captures"];
            
            NSString *capturedResourceID = captures[0];
            
            NSNumber *resourceID = [NSNumber numberWithInteger:capturedResourceID.integerValue];
            
            [self handleRequest:request
forResourceWithEntityDescription:entityDescription
                     resourceID:resourceID
                       function:nil
                       response:response];
        };
        
        // GET (read resource)
        [_httpServer get:instancePathExpression
               withBlock:instanceRequestHandler];
        
        // PUT (edit resource)
        [_httpServer put:instancePathExpression
               withBlock:instanceRequestHandler];
        
        // DELETE (delete resource)
        [_httpServer delete:instancePathExpression
                  withBlock:instanceRequestHandler];
        
        // add function routes
        
        for (NSString *functionName in [entityClass resourceFunctions]) {
            
            NSString *functionExpression = [NSString stringWithFormat:@"/%@/(\\d+)/%@", path, functionName];
            
            void (^instanceFunctionRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
                
                NSArray *captures = request.params[@"captures"];
                
                NSString *capturedResourceID = captures[0];
                
                NSNumber *resourceID = [NSNumber numberWithInteger:capturedResourceID.integerValue];
                
                [self handleRequest:request
   forResourceWithEntityDescription:entityDescription
                         resourceID:resourceID
                           function:functionName
                           response:response];

            };
            
            // functions use POST
            [_httpServer post:functionExpression
                    withBlock:instanceFunctionRequestHandler];
            
        }
    }
}

-(void)handleRequest:(RouteRequest *)request
forResourceWithEntityDescription:(NSEntityDescription *)entityDescription
          resourceID:(NSNumber *)resourceID
            function:(NSString *)functionName
            response:(RouteResponse *)response
{
    // get the session info
    
    NSString *token = request.headers[@"Authorization"];
    
    // determine the attribute name the entity uses for storing tokens
    
    Class sessionEntityClass = NSClassFromString(self.sessionEntityDescription.managedObjectClassName);
    
    NSString *tokenKey = [sessionEntityClass sessionTokenKey];
    
    // search the store for session with token
    
    NSFetchRequest *sessionWithTokenFetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityDescription.name];
    
    sessionWithTokenFetchRequest.predicate = [NSPredicate predicateWithFormat:@"%@ == %@", tokenKey, token];
    
    __block id<NOSessionProtocol> session;
    
    [self.store.context performBlockAndWait:^{
        
        NSError *fetchError;
        NSArray *result = [self.store.context executeFetchRequest:sessionWithTokenFetchRequest
                                                             error:&fetchError];
        
        if (!result) {
            
            [NSException raise:@"Fetch Request Failed"
                        format:@"%@", fetchError.localizedDescription];
            return;
        }
        
        if (!result.count) {
            return;
        }
        
        session = result[0];
        
    }];
    
    // check if the resource requires sessions
    if (!session && [NSClassFromString(entityDescription.managedObjectClassName) requireSession]) {
        
        response.statusCode = UnauthorizedStatusCode;
        
        return;
    }
    
    // determine what handler to call
    
    // get JSON body
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:request.body
                                                               options:NSJSONReadingAllowFragments
                                                                 error:nil];
    
    // create new instance
    if (!resourceID && [request.method isEqualToString:@"POST"]) {
        
        [self handleCreateResourceWithEntityDescription:entityDescription
                                     recievedJsonObject:jsonObject
                                                session:session
                                               response:response];
        return;
        
    }
    
    // methods that manipulate a instance
    if (resourceID) {
        
        // get the resource
        id<NOResourceProtocol> resource = [_store resourceWithEntityDescription:entityDescription
                                                                     resourceID:resourceID.integerValue];
        
        if (!resource) {
            
            response.statusCode = NotFoundStatusCode;
            
            return;
        }
        
        if (functionName) {
            
            [self handleFunction:functionName
              recievedJsonObject:jsonObject
                        resource:resource
                         session:session
                        response:response];
        }
        
        // requires a body
        if ([request.method isEqualToString:@"PUT"]) {
            
            if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
                
                response.statusCode = BadRequestStatusCode;
                
                return;
            }
            
            [self handleEditResource:resource
                  recievedJsonObject:jsonObject
                             session:session
                            response:response];
        }
        
        if ([request.method isEqualToString:@"GET"]) {
            
            [self handleGetResource:resource
                            session:session
                           response:response];
        }
        
        
        if ([request.method isEqualToString:@"DELETE"]) {
            
            [self handleDeleteResource:resource
                               session:session
                              response:response];
            
        }
    }
    
    // no recognized request was recieved
    response.statusCode = MethodNotAllowedStatusCode;
}

-(void)handleGetResource:(NSManagedObject<NOResourceProtocol> *)resource
                 session:(NSManagedObject<NOSessionProtocol> *)session
                response:(RouteResponse *)response
{
    NSManagedObject<NOUserProtocol> *user = [session valueForKey:[session.class sessionUserKey]];
    
    NSManagedObject<NOClientProtocol> *client = [session valueForKey:[session.class sessionClientKey]];
    
    if (![resource isVisibleToUser:user
                            client:client]) {
        
        response.statusCode = ForbiddenStatusCode;
        
        return;
    }
    
    // build JSON object...
    
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    // first the attributes
    for (NSString *attributeName in resource.entity.attributesByName) {
        
        if ([resource attribute:attributeName
                isVisibleToUser:user
                         client:client]) {
            
            [jsonObject setObject:[resource valueForKey:attributeName]
                           forKey:attributeName];
        }
        
    }
    
    // then the relationships
    for (NSString *relationshipName in resource.entity.relationshipsByName) {
        
        if ([resource relationship:relationshipName
                   isVisibleToUser:user
                            client:client]) {
            
            NSArray *relationship = [resource valueForKey:relationshipName];
            
            NSMutableArray *visibleDestinationResources = [[NSMutableArray alloc] init];
            
            for (NSManagedObject<NOResourceProtocol> *destinationResource in relationship) {
                
                // add to JSON object if the item is visible so we dont reveal the existence of hidden resources
                if ([destinationResource isVisibleToUser:user
                                                  client:client]) {
                    
                    // get resourceID
                    
                    NSString *resourceIDKey = [destinationResource.class resourceIDKey];
                    
                    NSNumber *resourceID = [destinationResource valueForKey:resourceIDKey];
                    
                    [visibleDestinationResources addObject:resourceID];
                }
                
            }
            
            [jsonObject setObject:visibleDestinationResources
                           forKey:relationshipName];
            
        }
    }

    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:self.jsonWritingOption
                                                         error:nil];
    if (!jsonData) {
        
        NSLog(@"Error writing JSON data!");
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    [response respondWithData:jsonData];
}




@end
