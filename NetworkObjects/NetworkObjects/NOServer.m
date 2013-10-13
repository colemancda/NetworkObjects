//
//  NOServer.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOServer.h"
#import "RoutingHTTPServer.h"
#import "RoutingConnection.h"
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

-(id)initWithStore:(NOStore *)store
    userEntityName:(NSString *)userEntityName
 sessionEntityName:(NSString *)sessionEntityName
  clientEntityName:(NSString *)clientEntityName
         loginPath:(NSString *)loginPath

{
    self = [super init];
    if (self) {
        
        NSAssert(store, @"NOStore cannot be nil");
        
        _store = store;
        
        _userEntityName = userEntityName;
        
        _sessionEntityName = sessionEntityName;
        
        _clientEntityName = clientEntityName;
        
        _loginPath = loginPath;
        
        _httpServer = [[RoutingHTTPServer alloc] init];
        
        _httpServer.connectionClass = [RoutingConnection class];
        
        [self setupServerRoutes];
        
    }
    return self;
}

- (id)init
{
    [NSException raise:@"Wrong initialization method"
                format:@"You cannot use %@ with '-%@', you have to use '-%@'",
     self,
     NSStringFromSelector(_cmd),
     NSStringFromSelector(@selector(initWithStore:userEntityName:sessionEntityName:clientEntityName:loginPath:))];
    return nil;
}

#pragma mark - Start & Stop

-(NSError *)startOnPort:(NSUInteger)port
{
    _httpServer.port = port;
    
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
    // add login server route
    [_httpServer get:self.loginPath withBlock:^(RouteRequest *request, RouteResponse *response) {
        
        [self handleLoginWithRequest:request
                            response:response];
    }];
    
    // configure internal HTTP server routes for resources
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
    // get session from request
    
    NSString *token = request.headers[@"Authentication"];
    
    NSManagedObject<NOSessionProtocol> *session = [self sessionWithToken:token];
    
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
    
    // make sure jsonObject is a dictionary
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        jsonObject = nil;
    }
    
    // create new instance
    if (!resourceID && [request.method isEqualToString:@"POST"]) {
        
        [self handleCreateResourceWithEntityDescription:entityDescription
                                                session:session
                                          initialValues:jsonObject
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
    // resource is invisible to session
    if ([resource permissionForSession:session] < ReadOnlyPermission) {
        
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
        
        NSLog(@"Error writing JSON representation of %@", resource);
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    // return JSON representation of resource
    [response respondWithData:jsonData];
}

-(NSDictionary *)JSONRepresentationOfResource:(NSManagedObject<NOResourceProtocol> *)resource
                                   forSession:(NSManagedObject<NOSessionProtocol> *)session
{
    // build JSON object...
    
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    // first the attributes
    for (NSString *attributeName in resource.entity.attributesByName) {
        
        // check access permissions
        if ([resource permissionForAttribute:attributeName
                                     session:session] >= ReadOnlyPermission) {
            
            [jsonObject setObject:[resource JSONCompatibleValueForAttribute:attributeName]
                           forKey:attributeName];
            
            // notify
            [resource attribute:attributeName
             wasAccessedBySession:session];
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
            if ([resource permissionForRelationship:toOneRelationshipName session:session] >= ReadOnlyPermission &&
                [destinationResource permissionForSession:session ] >= ReadOnlyPermission) {
                
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
        if ([resource permissionForRelationship:toManyRelationshipName session:session] >= ReadOnlyPermission) {
            
            NSRelationshipDescription *toOneRelationshipDescription = resource.entity.relationshipsByName[toManyRelationshipName];
            
            NSEntityDescription *destinationEntity = toOneRelationshipDescription.destinationEntity;
            
            // make sure the destination entity class conforms to NOResourceProtocol
            if ([NSClassFromString(destinationEntity.managedObjectClassName) conformsToProtocol:@protocol(NOResourceProtocol)]) {
                
                NSArray *toManyRelationship = [resource valueForKey:toManyRelationshipName];
                
                // only add resources that are visible
                NSMutableArray *visibleRelationship = [[NSMutableArray alloc] init];
                
                for (NSManagedObject<NOResourceProtocol> *destinationResource in toManyRelationship) {
                    
                    if ([destinationResource permissionForRelationship:toManyRelationshipName session:session] >= ReadOnlyPermission) {
                        
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
    
    // notify object
    [resource wasAccessedBySession:session];
    
    return jsonObject;
}

-(void)setValuesForResource:(NSManagedObject<NOResourceProtocol> *)resource
             fromJSONObject:(NSDictionary *)jsonObject
                    session:(NSManagedObject<NOSessionProtocol> *)session
{
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
    if ([resource permissionForSession:session] < EditPermission) {
        
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
            
            if ([resource permissionForAttribute:key session:session] < EditPermission) {
                
                return ForbiddenStatusCode;
            }
        }
        
        if (isToOneRelationship || isToManyRelationship) {
            
            if ([resource permissionForRelationship:key session:session] < EditPermission) {
                
                return ForbiddenStatusCode;
            }
            
            if (isToOneRelationship) {
                
                NSManagedObject<NOResourceProtocol> *destinationResource = [resource valueForKey:key];
                
                if ([destinationResource permissionForSession:session] < EditPermission) {
                    
                    return ForbiddenStatusCode;
                }
                
            }
            
            if (isToManyRelationship) {
                
                NSSet *toManyRelationship = [resource valueForKey:key];
                
                for (NSManagedObject<NOResourceProtocol> *destinationResource in toManyRelationship) {
                    
                    if ([destinationResource permissionForSession:session] < EditPermission) {
                        
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
    if ([resource permissionForSession:session] < EditPermission ||
        ![resource canDeleteFromSession:session]) {
        
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
    if (![entityClass canCreateNewInstanceFromSession:session]) {
        
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
    
    // validate initial values
    NOServerStatusCode applyInitialValuesStatusCode = [self verifyEditResource:newResource
                                                            recievedJsonObject:initialValues
                                                                       session:session];
    
    if (applyInitialValuesStatusCode != OKStatusCode) {
        
        response.statusCode = applyInitialValuesStatusCode;
        
        // delete created resource
        [_store deleteResource:newResource];
        
        return;
    }
    
    // set initial values
    [self setValuesForResource:newResource
                fromJSONObject:initialValues
                       session:session];
    
    // validate those inital values
    if (![newResource validInitialValues]) {
        
        response.statusCode = BadRequestStatusCode;
        
        // delete created resource
        [_store deleteResource:newResource];
        
        return;
    }
    
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

-(void)handleLoginWithRequest:(RouteRequest *)request
                     response:(RouteResponse *)response
{
    // get tokens
    NSDictionary *recievedJSONObject = [NSJSONSerialization JSONObjectWithData:request.body
                                                                       options:NSJSONReadingAllowFragments
                                                                         error:nil];
    
    // validate jsonObject
    if (![recievedJSONObject isKindOfClass:[NSDictionary class]]) {
        
        response.statusCode = BadRequestStatusCode;
        
        return;
    }
    
    NSString *clientSecret = recievedJSONObject[@"clientSecret"];
    
    NSString *username = recievedJSONObject[@"username"];
    
    NSString *userPassword = recievedJSONObject[@"password"];
    
    // all users must authenticate with client secret
    if ((username || userPassword) && !clientSecret) {
        
        response.statusCode = BadRequestStatusCode;
        
        return;
    }
    
    // client class
    NSEntityDescription *clientEntityDescription = [NSEntityDescription entityForName:self.clientEntityName
                                                               inManagedObjectContext:_store.context];
    
    Class clientEntityClass = NSClassFromString(clientEntityDescription.managedObjectClassName);
    
    NSString *clientSecretKey = [clientEntityClass clientSecretKey];
    
    NSFetchRequest *clientWithSecretFetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.clientEntityName];
    
    clientWithSecretFetchRequest.predicate = [NSPredicate predicateWithFormat:@"%@ == %@", clientSecretKey, clientSecret];
    
    // find client with secret
    
    __block NSManagedObject<NOClientProtocol> *client;
    
    [_store.context performBlockAndWait:^{
        
        NSError *fetchError;
        NSArray *result = [_store.context executeFetchRequest:clientWithSecretFetchRequest
                                                         error:&fetchError];
        
        if (!result) {
            
            [NSException raise:@"Fetch Request Failed"
                        format:@"%@", fetchError.localizedDescription];
            return;
        }
        
        if (!result.count) {
            return;
        }
        
        client = result[0];
        
    }];
    
    // if no client was found
    if (!client) {
        
        response.statusCode = BadRequestStatusCode;
        
        return;
    }
    
    // session class
    NSEntityDescription *sessionEntityDescription = [NSEntityDescription entityForName:self.sessionEntityName inManagedObjectContext:_store.context];
    
    Class sessionEntityClass = NSClassFromString(sessionEntityDescription.managedObjectClassName);
    
    // create new session with client
    NSManagedObject<NOSessionProtocol> *session = (NSManagedObject<NOSessionProtocol> *)[_store newResourceWithEntityDescription:sessionEntityDescription];
    
    // generate token
    [session generateToken];
    
    // set session client
    NSString *sessionClientKey = [sessionEntityClass sessionClientKey];
    
    [session setValue:client
               forKey:sessionClientKey];
    
    // add user to session if the authentication data is availible
    
    if (userPassword && username) {
        
        // user entity class
        NSEntityDescription *userEntityDescription = [NSEntityDescription entityForName:self.userEntityName
                                                                 inManagedObjectContext:_store.context];
        
        Class userEntityClass = NSClassFromString(userEntityDescription.managedObjectClassName);
        
        NSString *usernameKey = [userEntityClass usernameKey];
        
        NSString *passwordKey = [userEntityClass userPasswordKey];
        
        // search for user with username and password
        NSFetchRequest *userFetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.userEntityName];
        
        userFetchRequest.predicate = [NSPredicate predicateWithFormat:@"%@ ==[c] %@ AND %@ == %@", usernameKey, username, passwordKey, userPassword];
        
        __block NSManagedObject<NOUserProtocol> *user;
        
        [_store.context performBlockAndWait:^{
           
            NSError *fetchError;
            NSArray *result = [_store.context executeFetchRequest:userFetchRequest
                                                            error:&fetchError];
            
            if (!result) {
                
                [NSException raise:@"Fetch Request Failed"
                            format:@"%@", fetchError.localizedDescription];
                return;
            }
            
            if (!result.count) {
                return;
            }
            
            user = result[0];
            
        }];
        
        // username and password were provided in the request, but did not match anything in store
        if (!user) {
            
            response.statusCode = ForbiddenStatusCode;
            
            return;
        }
        
        // set session user
        NSString *sessionUserKey = [sessionEntityClass sessionUserKey];
        
        [session setValue:user
                   forKey:sessionUserKey];
    }
    
    // get session token
    NSString *sessionTokenKey = [sessionEntityClass sessionTokenKey];
    
    // respond with token
    NSDictionary *jsonObject = @{@"token": [session valueForKey:sessionTokenKey]};
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:self.prettyPrintJSON
                                                         error:nil];
    
    [response respondWithData:jsonData];
}

#pragma mark

-(NSManagedObject<NOSessionProtocol> *)sessionWithToken:(NSString *)token
{
    // determine the attribute name the entity uses for storing tokens
    
    NSEntityDescription *sessionEntityDescription = [NSEntityDescription entityForName:self.sessionEntityName inManagedObjectContext:_store.context];
    
    Class sessionEntityClass = NSClassFromString(sessionEntityDescription.managedObjectClassName);
    
    NSString *tokenKey = [sessionEntityClass sessionTokenKey];
    
    // search the store for session with token
    
    NSFetchRequest *sessionWithTokenFetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.sessionEntityName];
    
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
    
    return session;
}


@end
