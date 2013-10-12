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
#import "NSManagedObject+CoreDataJSONCompatibility.h"
#import "RouteResponse+IPAddress.h"

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

#pragma mark - Start & Stop

-(NSError *)startOnPort:(NSUInteger)port
{
    _httpServer = [[RoutingHTTPServer alloc] init];
    
    [self setupServerRoutes];
    
    NSError *startServerError;
    BOOL didStart = [_httpServer start:&startServerError];
    
    if (!didStart) {
        
        return startServerError;
    }
    
    return nil;
}

-(void)stop
{
    [_httpServer stop];
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

-(void)setupServerRoutes
{
    // configure internal HTTP server routes
    for (NSString *path in self.resourcePaths) {
        
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

#pragma mark - Handlers

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
    
    if (session) {
        
        // get IP Address
        
        [session usedSessionFromIP:response.ipAddress
                    requestHeaders:request.headers];
    }
    
    // determine what handler to call
    
    // get JSON body
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:request.body
                                                               options:NSJSONReadingAllowFragments
                                                                 error:nil];
    
    // create new instance
    if (!resourceID && [request.method isEqualToString:@"POST"]) {
        
        // get initial values JSON object
        NSDictionary *initialValues = [NSJSONSerialization JSONObjectWithData:request.body
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
        // make sure initialValues is a dictionary
        if (![initialValues isKindOfClass:[NSDictionary class]]) {
            initialValues = nil;
        }
        
        [self handleCreateResourceWithEntityDescription:entityDescription
                                                session:session
                                          initialValues:initialValues
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
            
            // bad request if body data is not JSON
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
    if (![resource isVisibleToSession:session]) {
        
        response.statusCode = ForbiddenStatusCode;
        
        return;
    }
    
    // build json object
    NSDictionary *jsonObject = [self JSONRepresentationOfResource:resource
                                                       forSession:session];
    
    // serialize JSON data
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:self.jsonWritingOption
                                                         error:nil];
    if (!jsonData) {
        
        NSLog(@"Error writing JSON data!");
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    // return JSON representation of resource
    [response respondWithData:jsonData];
}

-(NSDictionary *)JSONRepresentationOfResource:(NSManagedObject<NOResourceProtocol> *)resource
                                   forSession:(NSManagedObject<NOSessionProtocol> *)session
{
    // notify object
    [resource wasAccessedBySession:session];
    
    // build JSON object...
    
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    // first the attributes
    for (NSString *attributeName in resource.entity.attributesByName) {
        
        // check access permissions
        if ([resource attribute:attributeName
             isVisibleToSession:session]) {
            
            [jsonObject setObject:[resource JSONCompatibleValueForAttribute:attributeName]
                           forKey:attributeName];
            
            // notify
            [resource attribute:attributeName
             wasEditedBySession:session];
        }
    }
    
    // then the to-one relationships
    for (NSString *toOneRelationshipName in resource.entity.toOneRelationshipKeys) {
        
        NSRelationshipDescription *toOneRelationshipDescription = resource.entity.relationshipsByName[toOneRelationshipName];
        
        NSEntityDescription *destinationEntity = toOneRelationshipDescription.destinationEntity;
        
        // make sure the destination entity class conforms to NOResourceProtocol
        if ([NSClassFromString(destinationEntity.managedObjectClassName) conformsToProtocol:@protocol(NOResourceProtocol)]) {
            
            // get destination resource
            NSManagedObject<NOResourceProtocol> *destinationResource = [resource valueForKey:toOneRelationshipName];
            
            // check access permissions (the relationship & the single distination object must be visible)
            if ([resource relationship:toOneRelationshipName isVisibleToSession:session] && [destinationResource isEditableBySession:session]) {
                
                // get resourceID
                NSString *destinationResourceIDKey = [destinationResource.class resourceIDKey];
                
                NSNumber *destinationResourceID = [resource valueForKey:destinationResourceIDKey];
                
                // add to json object
                [jsonObject setValue:destinationResourceID
                              forKey:toOneRelationshipName];
                
                // notify
                [resource relationship:toOneRelationshipName
                  wasAccessedBySession:session];
            }
        }
    }
    
    // finally the to-many relationships
    for (NSString *toManyRelationshipName in resource.entity.toManyRelationshipKeys) {
        
        // make sure relationship is visible
        if ([resource relationship:toManyRelationshipName isVisibleToSession:session]) {
            
            NSRelationshipDescription *toOneRelationshipDescription = resource.entity.relationshipsByName[toManyRelationshipName];
            
            NSEntityDescription *destinationEntity = toOneRelationshipDescription.destinationEntity;
            
            // make sure the destination entity class conforms to NOResourceProtocol
            if ([NSClassFromString(destinationEntity.managedObjectClassName) conformsToProtocol:@protocol(NOResourceProtocol)]) {
                
                NSArray *toManyRelationship = [resource valueForKey:toManyRelationshipName];
                
                // only add resources that are visible
                NSMutableArray *visibleRelationship = [[NSMutableArray alloc] init];
                
                for (NSManagedObject<NOResourceProtocol> *destinationResource in toManyRelationship) {
                    
                    if ([destinationResource isVisibleToSession:session]) {
                        
                        // get destination resource ID
                        
                        NSString *destinationResourceIDKey = [destinationResource.class resourceIDKey];
                        
                        NSNumber *destinationResourceID = [destinationResource valueForKey:destinationResourceIDKey];
                        
                        [visibleRelationship addObject:destinationResourceID];
                    }
                }
                
                // add to jsonObject
                [jsonObject setValue:visibleRelationship
                              forKey:toManyRelationshipName];
                
                // notify
                [resource relationship:toManyRelationshipName
                  wasAccessedBySession:session];
            }
            
        }
    }
    
    return jsonObject;
}

-(void)setValuesForResource:(NSManagedObject<NOResourceProtocol> *)resource
             fromJSONObject:(NSDictionary *)jsonObject
                    session:(NSManagedObject<NOSessionProtocol> *)session
{
    // notify
    [resource wasEditedBySession:session];
    
    for (NSString *key in jsonObject) {
        
        NSObject *value = jsonObject[key];
        
        // one of these will be nil
        NSRelationshipDescription *relationshipDescription = resource.entity.relationshipsByName[key];
        NSAttributeDescription *attributeDescription = resource.entity.attributesByName[key];
        
        // attribute
        if (attributeDescription) {
            
            [resource setJSONCompatibleValue:value
                                forAttribute:key];
            
            // notify
            [resource attribute:key
             wasEditedBySession:session];
            
        }
        
        // relationship
        else {
            
            // to one relationship
            if (!relationshipDescription.isToMany) {
                
                NSNumber *destinationResourceID = (NSNumber *)value;
                
                // get the destination resource
                NSManagedObject<NOResourceProtocol> *destinationResource = [_store resourceWithEntityDescription:relationshipDescription.destinationEntity resourceID:destinationResourceID.integerValue];
                
                [resource setValue:destinationResource
                            forKey:key];
                
                // notify
                [resource attribute:key
                 wasEditedBySession:session];
                
            }
            
            // to many relationship
            else {
                
                NSArray *resourceIDs = (NSArray *)value;
                
                // build array to replace old to-many relationsip
                NSMutableArray *newRelationshipValues = [[NSMutableArray alloc] init];
                
                for (NSNumber *destinationResourceID in resourceIDs) {
                    
                    // get the destination resource
                    NSManagedObject<NOResourceProtocol> *destinationResource = [_store resourceWithEntityDescription:relationshipDescription.destinationEntity resourceID:destinationResourceID.integerValue];
                    
                    [newRelationshipValues addObject:destinationResource];
                }
                
                // replace collection
                [resource setValue:newRelationshipValues
                            forKey:key];
                
                // notify
                [resource attribute:key
                 wasEditedBySession:session];
                
            }
        }
    }
    
    // notify
    [resource wasEditedBySession:session];
}

-(NOServerStatusCode)verifyEditResource:(NSManagedObject<NOResourceProtocol> *)resource
                     recievedJsonObject:(NSDictionary *)recievedJsonObject
                                session:(NSManagedObject<NOSessionProtocol> *)session
{
    if (![resource isVisibleToSession:session] ||
        ![resource isEditableBySession:session]) {
        
        return ForbiddenStatusCode;
    }
    
    for (NSString *key in recievedJsonObject) {
        
        NSObject *value = recievedJsonObject[key];
        
        // validate the recieved JSON object
        
        if (![NSJSONSerialization isValidJSONObject:recievedJsonObject]) {
            
            return BadRequestStatusCode;
        }
        
        BOOL isValidAttribute;
        BOOL isToManyRelationship;
        BOOL isToOneRelationship;
        
        for (NSString *attributeName in resource.entity.attributesByName) {
            
            // NSAttributeDescription *attributeDescription = resource.entity.attributesByName[attributeName];
            
            // found attribute with same name
            if ([key isEqualToString:attributeName]) {
                
                // check if this key is the resourceIDKey
                NSString *resourceIDKey = [[resource class] resourceIDKey];
                
                // resourceID cannot be edited by anyone
                if (![resourceIDKey isEqualToString:key]) {
                    
                    isValidAttribute = YES;
                    
                }
            }
        }
        
        for (NSString *toOneRelationshipName in resource.entity.toOneRelationshipKeys) {
            
            if ([key isEqualToString:toOneRelationshipName] &&
                [value isKindOfClass:[NSNumber class]]) {
                
                isToOneRelationship = YES;
            }
        }
        
        for (NSString *toManyRelationshipName in resource.entity.toManyRelationshipKeys) {
            
            if ([key isEqualToString:toManyRelationshipName]) {
                
                isToManyRelationship = YES;
            }
        }
        
        // no attribute or relationship with that name found
        if (!isValidAttribute && !isToOneRelationship && !isToManyRelationship) {
            
            return BadRequestStatusCode;
        }
        
        // check for permissions
        
        if (isValidAttribute) {
            
            if (![resource attribute:key isVisibleToSession:session] ||
                ![resource attribute:key isEditableBySession:session]) {
                
                return ForbiddenStatusCode;
            }
        }
        
        if (isToOneRelationship || isToManyRelationship) {
            
            if (![resource relationship:key isVisibleToSession:session] ||
                ![resource relationship:key isEditableBySession:session]) {
                
                return ForbiddenStatusCode;
            }
            
            if (isToOneRelationship) {
                
                NSManagedObject<NOResourceProtocol> *destinationResource = [resource valueForKey:key];
                
                if (![destinationResource isVisibleToSession:session] ||
                    ![destinationResource isEditableBySession:session]) {
                    
                    return ForbiddenStatusCode;
                }
                
            }
            
            if (isToManyRelationship) {
                
                NSSet *toManyRelationship = [resource valueForKey:key];
                
                for (NSManagedObject<NOResourceProtocol> *destinationResource in toManyRelationship) {
                    
                    if (![destinationResource isVisibleToSession:session] ||
                        ![destinationResource isEditableBySession:session]) {
                        
                        return ForbiddenStatusCode;
                    }
                }
            }
        }
    }
    
    return OKStatusCode;
}

-(void)handleEditResource:(NSManagedObject<NOResourceProtocol> *)resource
       recievedJsonObject:(NSDictionary *)recievedJsonObject
                  session:(NSManagedObject<NOSessionProtocol> *)session
                 response:(RouteResponse *)response
{
    // check if jsonObject has keys that dont exist in this resource or lacks permission to edit...
    
    NOServerStatusCode editStatusCode = [self verifyEditResource:resource
                                              recievedJsonObject:recievedJsonObject
                                                         session:session];
    
    // return HTTP error code if recieved JSON data is invalid
    if (editStatusCode != OKStatusCode) {
        
        response.statusCode = editStatusCode;
        
        return;
    }
    
    // since we verified the validity and access permissions of the recievedJsonObject, we then apply the edits...
    [self setValuesForResource:resource
                fromJSONObject:recievedJsonObject
                       session:session];
    
    
    // return 200
    response.statusCode = OKStatusCode;
}

-(void)handleDeleteResource:(NSManagedObject<NOResourceProtocol> *)resource
                    session:(NSManagedObject<NOSessionProtocol> *)session
                   response:(RouteResponse *)response
{
    // check permissions
    if (![resource isVisibleToSession:session] ||
        ![resource isEditableBySession:session]) {
        
        response.statusCode = ForbiddenStatusCode;
        return;
    }
    
    [_store deleteResource:resource];
    
    response.statusCode = OKStatusCode;
}

-(void)handleCreateResourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                         session:(NSManagedObject<NOSessionProtocol> *)session
                                   initialValues:(NSDictionary *)initialValues
                                        response:(RouteResponse *)response
{
    Class<NOResourceProtocol> entityClass = NSClassFromString(entityDescription.managedObjectClassName);
    
    // check permissions
    if (![entityClass canCreateNewInstanceWithSession:session]) {
        
        response.statusCode = ForbiddenStatusCode;
        
        return;
    }
    
    // check whether inital values are required
    if ([entityClass requireInitialValues] && !initialValues) {
        
        response.statusCode = BadRequestStatusCode;
        
        return;
    }
    
    // create new instance
    NSManagedObject<NOResourceProtocol> *newResource = [_store newResourceWithEntityDescription:entityDescription];
    
    // validate inital values
    NOServerStatusCode applyInitalValuesStatusCode = [self verifyEditResource:newResource
                                                           recievedJsonObject:initialValues
                                                                      session:session];
    
    if (applyInitalValuesStatusCode != OKStatusCode) {
        
        response.statusCode = applyInitalValuesStatusCode;
        
        // delete created resource
        [_store deleteResource:newResource];
        
        return;
    }
    
    // set inital values
    [self setValuesForResource:newResource
                fromJSONObject:initialValues
                       session:session];
    
    // get the resourceIDKey
    NSString *resourceIDKey = [[newResource class] resourceIDKey];
    
    // get resourceID
    NSNumber *resourceID = [newResource valueForKey:resourceIDKey];
    
    NSDictionary *jsonObject = @{resourceIDKey: resourceID};
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:self.jsonWritingOption
                                                         error:nil];
    
    [response respondWithData:jsonData];
    
    // notify
    [newResource wasCreatedBySession:session];
    
    response.statusCode = OKStatusCode;
}

-(void)handleFunction:(NSString *)functionName
   recievedJsonObject:(NSDictionary *)recievedJsonObject
             resource:(NSManagedObject<NOResourceProtocol> *)resource
              session:(NSManagedObject<NOSessionProtocol> *)session
             response:(RouteResponse *)response
{
    // check for permission
    if (![resource canPerformFunction:functionName
                              session:session])
    {
        response.statusCode = ForbiddenStatusCode;
        
        return;
    }
    
    // perform function
    NSDictionary *jsonResponse;
    response.statusCode = [resource performFunction:functionName
                                 recievedJsonObject:recievedJsonObject
                                           response:&jsonResponse];
    
    if (jsonResponse) {
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonResponse
                                                           options:self.jsonWritingOption
                                                             error:nil];
        
        [response respondWithData:jsonData];
    }
    
}


@end
