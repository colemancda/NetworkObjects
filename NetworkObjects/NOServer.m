//
//  NOServer.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOServer.h"
#import "NOStore.h"
#import "NOResourceProtocol.h"
#import "NOSessionProtocol.h"
#import "NOUserProtocol.h"
#import "NOClientProtocol.h"
#import "NSManagedObject+CoreDataJSONCompatibility.h"
#import "RouteResponse+IPAddress.h"
#import "NOHTTPConnection.h"
#import "NOHTTPServer.h"
#import "NetworkObjectsConstants.h"

// Initialization Options

NSString *const NOServerStoreOption = @"NOServerStoreOption";

NSString *const NOServerUserEntityNameOption = @"NOServerUserEntityNameOption";

NSString *const NOServerSessionEntityNameOption = @"NOServerSessionEntityNameOption";

NSString *const NOServerClientEntityNameOption = @"NOServerClientEntityNameOption";

NSString *const NOServerLoginPathOption = @"NOServerLoginPathOption";

NSString *const NOServerSearchPathOption = @"NOServerSearchPathOption";

@implementation NOServer (NSJSONWritingOption)

-(NSJSONWritingOptions)jsonWritingOption
{
    if (self.prettyPrintJSON) {
        return NSJSONWritingPrettyPrinted;
    }
    
    return 0;
}

@end

@interface NOServer ()

@property NOStore *store;

@property NOHTTPServer *httpServer;

@property NSString *sessionEntityName;

@property NSString *userEntityName;

@property NSString *clientEntityName;

@property NSString *loginPath;

@property NSString *searchPath;

@end

@implementation NOServer

@synthesize resourcePaths = _resourcePaths;

-(instancetype)initWithOptions:(NSDictionary *)options

{
    self = [super init];
    if (self) {
        
        // Obligatory Options
        
        self.store = options[NOServerStoreOption];
        
        self.userEntityName = options[NOServerUserEntityNameOption];
        
        self.sessionEntityName = options[NOServerSessionEntityNameOption];
        
        self.clientEntityName = options[NOServerClientEntityNameOption];
        
        if (!self.store || !self.userEntityName || !self.sessionEntityName || !self.clientEntityName) {
            
            [NSException raise:NSInvalidArgumentException
                        format:@"Required initialzation options were not included in the options dictionary"];
            
            return nil;
        }
        
        // Optional Options
        
        _loginPath = options[NOServerLoginPathOption];
        
        _searchPath = options[NOServerSearchPathOption];
        
        // HTTP Server
        
        _httpServer = [[NOHTTPServer alloc] init];
        
        _httpServer.server = self;
        
        _httpServer.connectionClass = [NOHTTPConnection class];
        
        [self setupServerRoutes];
        
        // search enabled
        if (self.searchPath) {
            
            // default value
            self.allowedOperatorsForSearch = [NSSet setWithArray:@[@(NSEqualToPredicateOperatorType)]];
        }
        
    }
    return self;
}

- (id)init
{
    [NSException raise:@"Wrong initialization method"
                format:@"You cannot use %@ with '-%@', you have to use '-%@'",
     self,
     NSStringFromSelector(_cmd),
     NSStringFromSelector(@selector(initWithOptions:))];
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
    // build a cache of NOResources and URLs (once)
    if (!_resourcePaths) {
        
        // scan through entity descriptions and get urls of NOResources
        NSManagedObjectModel *model = self.store.persistentStoreCoordinator.managedObjectModel;
        
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
    if (self.loginPath) {
        
        // add login server route
        NSString *loginPath = [NSString stringWithFormat:@"/%@", self.loginPath];
        
        [_httpServer post:loginPath withBlock:^(RouteRequest *request, RouteResponse *response) {
            
            [self handleLoginWithRequest:request
                                response:response];
        }];
    }
    
    // configure internal HTTP server routes for resources
    for (NSString *path in self.resourcePaths) {
        
        // get entity description
        
        NSEntityDescription *entityDescription = _resourcePaths[path];
        
        Class entityClass = NSClassFromString(entityDescription.managedObjectClassName);
        
        // add search route
        
        if (self.searchPath) {
            
            NSString *searchPathExpression = [NSString stringWithFormat:@"/%@/%@", _searchPath, path];
            
            void (^searchRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
                
                [self handleRequest:request
   forResourceWithEntityDescription:entityDescription
                         resourceID:nil
                           function:nil
                           isSearch:YES
                           response:response];
                
            };
            
            [_httpServer post:searchPathExpression
                   withBlock:searchRequestHandler];
        }
        
        // setup routes for resources...
        
        NSString *allInstancesPathExpression = [NSString stringWithFormat:@"/%@", path];
        
        void (^allInstancesRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
            
            [self handleRequest:request
forResourceWithEntityDescription:entityDescription
                     resourceID:nil
                       function:nil
                       isSearch:NO
                       response:response];
        };
        
        // POST (create new resource)
        [_httpServer post:allInstancesPathExpression
                withBlock:allInstancesRequestHandler];
        
        // setup routes for resource instances
        
        NSString *instancePathExpression = [NSString stringWithFormat:@"{^/%@/(\\d+)}", path];
        
        void (^instanceRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
            
            NSArray *captures = request.params[@"captures"];
            
            NSString *capturedResourceID = captures[0];
            
            NSNumber *resourceID = @(capturedResourceID.integerValue);
            
            [self handleRequest:request
forResourceWithEntityDescription:entityDescription
                     resourceID:resourceID
                       function:nil
                       isSearch:NO
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
            
            NSString *functionExpression = [NSString stringWithFormat:@"{^/%@/(\\d+)/%@}", path, functionName];
            
            void (^instanceFunctionRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
                
                NSArray *captures = request.params[@"captures"];
                
                NSString *capturedResourceID = captures[0];
                
                NSNumber *resourceID = @(capturedResourceID.integerValue);
                
                [self handleRequest:request
   forResourceWithEntityDescription:entityDescription
                         resourceID:resourceID
                           function:functionName
                           isSearch:NO
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
            isSearch:(BOOL)isSearch
            response:(RouteResponse *)response
{
    // get session from request
    
    NSString *token = request.headers[@"Authorization"];
    
    NSError *error;
    
    NSManagedObject<NOSessionProtocol> *session = [self sessionWithToken:token
                                                                   error:&error];
    
    if (error) {
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    // check if the resource requires sessions
    if (!session && [NSClassFromString(entityDescription.managedObjectClassName) requireSession]) {
        
        response.statusCode = UnauthorizedStatusCode;
        
        return;
    }
    
    if (session) {
        
        if ([session canUseSessionFromIP:response.ipAddress
                          requestHeaders:request.headers]) {
            
            [session usedSessionFromIP:response.ipAddress
                        requestHeaders:request.headers];
        }
        
        // cant use the session
        else {
            
            session = nil;
        }
    }
    
    // determine what handler to call
    
    // get JSON body
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:request.body
                                                               options:NSJSONReadingAllowFragments
                                                                 error:nil];
    
    // make sure jsonObject is a dictionary
    if (jsonObject && ![jsonObject isKindOfClass:[NSDictionary class]]) {
        
        jsonObject = nil;
    }
    
    // handlers that do not specify an instance...
    
    // create new instance
    if (!resourceID && [request.method isEqualToString:@"POST"] && !isSearch) {
        
        [self handleCreateResourceWithEntityDescription:entityDescription
                                                session:session
                                          initialValues:jsonObject
                                               response:response];
        return;
        
    }
    
    // search
    if (!resourceID && [request.method isEqualToString:@"POST"] && isSearch) {
        
        [self handleSearchForResourceWithEntityDescription:entityDescription
                                                   session:session
                                          searchParameters:jsonObject
                                                  response:response];
        
        return;
    }
    
    // methods that manipulate an instance...
    
    if (resourceID) {
        
        BOOL shouldPrefetch = YES;
        
        // determine prefetch
        
        if ([request.method isEqualToString:@"DELETE"]) {
            
            shouldPrefetch = NO;
        }
        
        NSError *fetchError;
        
        // get the resource
        NSManagedObject<NOResourceProtocol> *resource = [self.store resourceWithEntityDescription:entityDescription
                                                                                       resourceID:resourceID
                                                                                   shouldPrefetch:shouldPrefetch
                                                                                            error:&fetchError];
        // get session object for resource context
        
        __block NSManagedObject <NOSessionProtocol> *resourceContextSession;
        
        [resource.managedObjectContext performBlockAndWait:^{
            
            resourceContextSession = (NSManagedObject<NOSessionProtocol> *)[resource.managedObjectContext objectWithID:session.objectID];
        }];
        
        // internal error
        if (fetchError) {
            
            // TODO LOG
            
            response.statusCode = InternalServerErrorStatusCode;
            
            return;
        }
        
        // fetch resource
        
        if (!resource) {
            
            response.statusCode = NotFoundStatusCode;
            
            return;
        }
        
        // forward to handler
        
        if (functionName) {
            
            [self handleFunction:functionName
              recievedJsonObject:jsonObject
                        resource:resource
                         session:resourceContextSession
                        response:response];
            
            return;
        }
        
        // requires a body
        if ([request.method isEqualToString:@"PUT"]) {
            
            // bad request if no JSON body is attached to request
            if (!jsonObject) {
                
                response.statusCode = BadRequestStatusCode;
                
                return;
            }
            
            [self handleEditResource:resource
                  recievedJsonObject:jsonObject
                             session:resourceContextSession
                            response:response];
            
            return;
        }
        
        if ([request.method isEqualToString:@"GET"]) {
            
            [self handleGetResource:resource
                            session:resourceContextSession
                           response:response];
            
            return;
        }
        
        if ([request.method isEqualToString:@"DELETE"]) {
            
            [self handleDeleteResource:resource
                               session:resourceContextSession
                              response:response];
            
            return;
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
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:self.jsonWritingOption
                                                         error:&error];
    if (!jsonData) {
        
        NSLog(@"Error writing JSON representation of %@ (%@)", resource, error.localizedDescription);
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    // return JSON representation of resource
    [response respondWithData:jsonData];
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
    
    NSError *error;
    
    if ([self setValuesForResource:resource
                    fromJSONObject:recievedJsonObject
                           session:session
                             error:&error]) {
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    
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
    
    NSError *error;
    
    if (![_store deleteResource:resource
                         error:&error]) {
        
        // TODO LOG
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
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
    if ([entityClass requiredInitialProperties]) {
        
        for (NSString *initialPropertyName in [entityClass requiredInitialProperties]) {
            
            BOOL foundInitialProperty;
            
            for (NSString *key in initialValues) {
                
                if ([key isEqualToString:initialPropertyName]) {
                    
                    foundInitialProperty = YES;
                }
            }
            
            if (!foundInitialProperty) {
                
                response.statusCode = BadRequestStatusCode;
                
                return;
            }
        }
    }
    
    // validate initial values
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    context.persistentStoreCoordinator = self.store.persistentStoreCoordinator;
    
    context.undoManager = nil;
    
    __block NOServerStatusCode applyInitialValuesStatusCode;
    
    [context performBlockAndWait:^{
        
        NSManagedObject<NOResourceProtocol> *tempResource = [NSEntityDescription insertNewObjectForEntityForName:entityDescription.name inManagedObjectContext:context];
        
        applyInitialValuesStatusCode = [self verifyEditResource:tempResource
                                             recievedJsonObject:initialValues
                                                        session:(NSManagedObject<NOSessionProtocol> *)[context objectWithID:session.objectID]];
    }];
    
    // reduce memory
    
    context = nil;
    
    if (applyInitialValuesStatusCode != OKStatusCode) {
        
        response.statusCode = applyInitialValuesStatusCode;
        
        return;
    }
    
    // create new instance
    
    __block NSError *error;
    
    NSManagedObject<NOResourceProtocol> *newResource = [_store newResourceWithEntityDescription:entityDescription
                                                                                          error:&error];
    
    if (!newResource) {
        
        // TODO LOG
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    // get the resourceIDKey
    NSString *resourceIDKey = [[newResource class] resourceIDKey];
    
    __block NSNumber *resourceID;
    
    [newResource.managedObjectContext performBlockAndWait:^{
        
        // notify
        
        [newResource wasCreatedBySession:session];
        
        // set initial values
        
        [self setValuesForResource:newResource
                    fromJSONObject:initialValues
                           session:(NSManagedObject<NOSessionProtocol> *)[newResource.managedObjectContext objectWithID:session.objectID]
                             error:&error];
        
        // get resourceID
        resourceID = [newResource valueForKey:resourceIDKey];
        
    }];
    
    NSDictionary *jsonObject = @{resourceIDKey: resourceID};
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:self.jsonWritingOption
                                                         error:&error];
    
    if (!jsonData) {
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    [response respondWithData:jsonData];
    
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
                                        withSession:session
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
    
    // session class
    NSEntityDescription *sessionEntityDescription = self.store.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.sessionEntityName];

    Class sessionEntityClass = NSClassFromString(sessionEntityDescription.managedObjectClassName);
    
    NSString *sessionUserKey = [sessionEntityClass sessionUserKey];
    
    NSString *sessionClientKey = [sessionEntityClass sessionClientKey];
    
    // client class
    NSEntityDescription *clientEntityDescription = self.store.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.clientEntityName];

    
    Class clientEntityClass = NSClassFromString(clientEntityDescription.managedObjectClassName);
    
    // get client keys
    
    NSString *clientSecretKey = [clientEntityClass clientSecretKey];
    
    NSString *clientResourceIDKey = [clientEntityClass resourceIDKey];
    
    NSDictionary *clientJSONObject = recievedJSONObject[sessionClientKey];
    
    // validate jsonObject
    if (![clientJSONObject isKindOfClass:[NSDictionary class]]) {
        
        response.statusCode = BadRequestStatusCode;
        
        return;
    }
    
    NSString *clientSecret = clientJSONObject[clientSecretKey];
    
    NSNumber *clientResourceID = clientJSONObject[clientResourceIDKey];
    
    // validate recieved JSON object
    
    if (!clientSecret ||
        !clientResourceID) {
        
        response.statusCode = BadRequestStatusCode;
        
        return;
    }
    
    // get client with resource ID
    
    NSError *error;
    
    NSManagedObject<NOClientProtocol> *client = (NSManagedObject<NOClientProtocol> *)[_store resourceWithEntityDescription:clientEntityDescription resourceID:clientResourceID shouldPrefetch:YES error:&error];
    
    if (error) {
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    if (!client) {
        
        response.statusCode = ForbiddenStatusCode;
        
        return;
    }
    
    // validate secret
    
    __block BOOL validSecret;
    
    [client.managedObjectContext performBlockAndWait:^{
        
        validSecret = [[client valueForKey:clientSecretKey] isEqualToString:clientSecret];
    }];
    
    if (!validSecret) {
        
        response.statusCode = ForbiddenStatusCode;
        
        return;
    }
    
    // create new session with client
    __block NSManagedObject<NOSessionProtocol> *session = (NSManagedObject<NOSessionProtocol> *)[_store newResourceWithEntityDescription:sessionEntityDescription error:&error];
    
    if (error) {
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    [client.managedObjectContext performBlockAndWait:^{
        
        session = (NSManagedObject<NOSessionProtocol> *)[client.managedObjectContext objectWithID:session.objectID];
        
        // generate token
        [session generateToken];
        
        // set client
        [session setValue:client
                   forKey:sessionClientKey];
        
    }];
    
    // user entity class
    NSEntityDescription *userEntityDescription = self.store.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.userEntityName];

    Class userEntityClass = NSClassFromString(userEntityDescription.managedObjectClassName);
    
    NSString *usernameKey = [userEntityClass usernameKey];
    
    NSString *passwordKey = [userEntityClass userPasswordKey];
    
    NSDictionary *userJSONObject = recievedJSONObject[sessionUserKey];
    
    // add user to session if the authentication data is availible
    
    if ([userJSONObject isKindOfClass:[NSDictionary class]]) {
        
        NSString *username = userJSONObject[usernameKey];
        
        NSString *userPassword = userJSONObject[passwordKey];
        
        // search for user with username and password
        NSFetchRequest *userFetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.userEntityName];
        
        userFetchRequest.fetchLimit = 1;
        
        // create predicate
        
        NSPredicate *usernamePredicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:usernameKey] rightExpression:[NSExpression expressionForConstantValue:username] modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:NSCaseInsensitivePredicateOption];
        
        NSPredicate *passwordPredicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:passwordKey] rightExpression:[NSExpression expressionForConstantValue:userPassword] modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:NSNormalizedPredicateOption];
        
        userFetchRequest.predicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType
                                                                 subpredicates:@[usernamePredicate, passwordPredicate]];
        
        // create context
        
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
        context.persistentStoreCoordinator = self.store.persistentStoreCoordinator;
        
        context.undoManager = nil;
        
        // fetch user
        
        __block NSManagedObject<NOUserProtocol> *user;
        
        __block NSError *fetchError;
        
        [context performBlockAndWait:^{
            
            NSArray *result = [context executeFetchRequest:userFetchRequest
                                                     error:&fetchError];
            user = result.firstObject;
            
        }];
        
        // username and password were provided in the request, but did not match anything in store
        if (!user) {
            
            response.statusCode = ForbiddenStatusCode;
            
            return;
        }
        
        // set session user
        
        [client.managedObjectContext performBlockAndWait:^{
            
            [session setValue:[client.managedObjectContext objectWithID:user.objectID]
                       forKey:sessionUserKey];
            
        }];
    }
    
    // get session token
    NSString *sessionTokenKey = [sessionEntityClass sessionTokenKey];
    
    __block NSString *sessionToken;
    
    [client.managedObjectContext performBlockAndWait:^{
       
        sessionToken = [session valueForKey:sessionTokenKey];
        
    }];
    
    // respond with token
    NSMutableDictionary *jsonObject = [NSMutableDictionary dictionaryWithDictionary:@{sessionTokenKey : sessionToken}];
    
    // add user resourceID if the session has a user
    NSManagedObject *user = [session valueForKey:sessionUserKey];
    
    if (user) {
        
        NSString *userResourceIDKey = [[user class] resourceIDKey];
        
        __block NSNumber *userResourceID;
        
        [client.managedObjectContext performBlockAndWait:^{
           
            userResourceID = [user valueForKey:userResourceIDKey];
            
        }];
        
        [jsonObject addEntriesFromDictionary:@{sessionUserKey: userResourceID}];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:self.prettyPrintJSON
                                                         error:nil];
    
    if (!jsonData) {
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    [response respondWithData:jsonData];
}

-(void)handleSearchForResourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                            session:(NSManagedObject<NOSessionProtocol> *)session
                                   searchParameters:(NSDictionary *)searchParameters
                                           response:(RouteResponse *)response
{
    // check permission
    
    if (![NSClassFromString(entityDescription.managedObjectClassName) canSearchFromSession:session]) {
        
        response.statusCode = ForbiddenStatusCode;
        
        return;
    }
    
    // Put togeather fetch request
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityDescription.name];
    
    // get resourceID key
    
    NSString *resourceIDKey = [NSClassFromString(entityDescription.managedObjectClassName) resourceIDKey];
    
    NSSortDescriptor *defaultSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:resourceIDKey
                                                                            ascending:YES];
    
    fetchRequest.sortDescriptors = @[defaultSortDescriptor];
    
    
    // create context
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    context.persistentStoreCoordinator = self.store.persistentStoreCoordinator;
    
    context.undoManager = nil;
    
    // add search parameters...
    
    // predicate...
    
    NSString *predicateKey = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateKeyParameter]];
    
    id jsonPredicateValue = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateValueParameter]];
    
    NSNumber *predicateOperator = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateOperatorParameter]];
    
    if ([predicateKey isKindOfClass:[NSString class]] &&
        [predicateOperator isKindOfClass:[NSNumber class]] &&
        jsonPredicateValue) {
        
        // validate comparator
        
        BOOL validComparator;
        
        for (NSNumber *allowedOperatorNumber in self.allowedOperatorsForSearch) {
            
            if ([allowedOperatorNumber isEqualToNumber:predicateOperator]) {
                
                validComparator = YES;
                
                break;
            }
        }
        
        if (!validComparator ||
            predicateOperator.integerValue == NSCustomSelectorPredicateOperatorType) {
            
            response.statusCode = BadRequestStatusCode;
            
            return;
        }
        
        // convert to Core Data value...
        
        id value;
        
        // one of these will be nil
        
        NSRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[predicateKey];
        
        NSAttributeDescription *attributeDescription = entityDescription.attributesByName[predicateKey];
        
        // validate that key is attribute or relationship
        if (!relationshipDescription && !attributeDescription) {
            
            response.statusCode = BadRequestStatusCode;
            
            return;
        }
        
        // attribute value
        
        if (attributeDescription) {
            
            value = [entityDescription attributeValueForJSONCompatibleValue:jsonPredicateValue
                                                               forAttribute:predicateKey];
        }
        
        // relationship value
        
        if (relationshipDescription) {
            
            // to-one
            
            if (!relationshipDescription.isToMany) {
                
                // verify
                if (![jsonPredicateValue isKindOfClass:[NSNumber class]]) {
                    
                    response.statusCode = BadRequestStatusCode;
                    
                    return;
                }
                
                NSNumber *resourceID = jsonPredicateValue;
                
                NSError *error;
                
                NSManagedObject *fetchedResource = [self.store resourceWithEntityDescription:entityDescription
                                                                                  resourceID:resourceID
                                                                              shouldPrefetch:NO
                                                                                       error:&error];
                
                if (error) {
                    
                    response.statusCode = InternalServerErrorStatusCode;
                    
                    return;
                }
                
                if (!fetchedResource) {
                    
                    response.statusCode = BadRequestStatusCode;
                    
                    return;
                }
                
                // value must belong to local context
                
                __block NSManagedObject *resource;
                
                [context performBlockAndWait:^{
                    
                    resource = [context objectWithID:fetchedResource.objectID];
                    
                }];
                
                value = resource;
                
            }
            
            // to-many
            
            else {
                
                // verify
                if (![jsonPredicateValue isKindOfClass:[NSArray class]]) {
                    
                    response.statusCode = BadRequestStatusCode;
                    
                    return;
                }
                
                value = [[NSMutableArray alloc] init];
                
                for (NSNumber *resourceID in jsonPredicateValue) {
                    
                    if (![resourceID isKindOfClass:[NSNumber class]]) {
                        
                        response.statusCode = BadRequestStatusCode;
                        
                        return;
                    }
                    
                    NSError *error;
                    
                    NSManagedObject *fetchedResource = [self.store resourceWithEntityDescription:entityDescription
                                                                                      resourceID:resourceID
                                                                                  shouldPrefetch:NO
                                                                                           error:&error];
                    
                    if (error) {
                        
                        response.statusCode = InternalServerErrorStatusCode;
                        
                        return;
                    }
                    
                    if (!fetchedResource) {
                        
                        response.statusCode = BadRequestStatusCode;
                        
                        return;
                    }
                    
                    // value must belong to local context
                    
                    __block NSManagedObject *resource;
                    
                    [context performBlockAndWait:^{
                        
                        resource = [context objectWithID:fetchedResource.objectID];
                        
                    }];
                    
                    [value addObject:resource];
                }
            }
        }
        
        // create predicate
        
        NSExpression *leftExp = [NSExpression expressionForKeyPath:predicateKey];
        
        NSExpression *rightExp = [NSExpression expressionForConstantValue:value];
        
        NSPredicateOperatorType operator = predicateOperator.integerValue;
        
        // add optional parameters...
        
        NSNumber *optionNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateOptionParameter]];
        
        NSComparisonPredicateOptions options;
        
        if ([optionNumber isKindOfClass:[NSNumber class]]) {
            
            options = optionNumber.integerValue;
            
        }
        else {
            
            options = NSNormalizedPredicateOption;
        }
        
        NSNumber *modifierNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateModifierParameter]];
        
        NSComparisonPredicateModifier modifier;
        
        if ([modifierNumber isKindOfClass:[NSNumber class]]) {
            
            modifier = modifierNumber.integerValue;
        }
        
        else {
            
            modifier = NSDirectPredicateModifier;
        }
        
        NSComparisonPredicate *predicate = [[NSComparisonPredicate alloc] initWithLeftExpression:leftExp
                                                                                 rightExpression:rightExp
                                                                                        modifier:modifier
                                                                                            type:operator
                                                                                         options:options];
        
        if (!predicate) {
            
            response.statusCode = BadRequestStatusCode;
            
            return;
        }
        
        fetchRequest.predicate = predicate;
        
    }
    
    // sort descriptors
    
    NSArray *sortDescriptorsJSONArray = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchSortDescriptorsParameter]];
    
    NSMutableArray *sortDescriptors;
    
    if (sortDescriptorsJSONArray) {
        
        if (![sortDescriptorsJSONArray isKindOfClass:[NSArray class]]) {
            
            response.statusCode = BadRequestStatusCode;
            
            return;
        }
        
        if (!sortDescriptorsJSONArray.count) {
            
            response.statusCode = BadRequestStatusCode;
            
            return;
        }
        
        sortDescriptors = [[NSMutableArray alloc] init];
        
        for (NSDictionary *sortDescriptorJSON in sortDescriptorsJSONArray) {
            
            // validate JSON
            
            if (![sortDescriptorJSON isKindOfClass:[NSDictionary class]]) {
                
                response.statusCode = BadRequestStatusCode;
                
                return;
            }
            
            if (sortDescriptorJSON.allKeys.count != 1) {
                
                response.statusCode = BadRequestStatusCode;
                
                return;
            }
            
            NSString *key = sortDescriptorJSON.allKeys.firstObject;
            
            NSNumber *ascending = sortDescriptorJSON.allValues.firstObject;
            
            // more validation
            
            if (![key isKindOfClass:[NSString class]] ||
                ![ascending isKindOfClass:[NSNumber class]]) {
                
                response.statusCode = BadRequestStatusCode;
                
                return;
            }
            
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:key
                                                                   ascending:ascending.boolValue];
            
            [sortDescriptors addObject:sort];
            
        }
        
        fetchRequest.sortDescriptors = sortDescriptors;
        
    }
    
    // fetch limit
    
    NSNumber *fetchLimitNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchFetchLimitParameter]];
    
    if (fetchLimitNumber) {
        
        if (![fetchLimitNumber isKindOfClass:[NSNumber class]]) {
            
            response.statusCode = BadRequestStatusCode;
            
            return;
        }
        
        fetchRequest.fetchLimit = fetchLimitNumber.integerValue;
    }
    
    // fetch offset
    
    NSNumber *fetchOffsetNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchFetchOffsetParameter]];
    
    if (fetchOffsetNumber) {
        
        if (![fetchOffsetNumber isKindOfClass:[NSNumber class]]) {
            
            response.statusCode = BadRequestStatusCode;
            
            return;
        }
        
        
        fetchRequest.fetchOffset = fetchOffsetNumber.integerValue;
    }
    
    NSNumber *includeSubEntitites = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchIncludesSubentitiesParameter]];
    
    if (includeSubEntitites) {
        
        if (![includeSubEntitites isKindOfClass:[NSNumber class]]) {
            
            response.statusCode = BadRequestStatusCode;
            
            return;
        }
        
        fetchRequest.includesSubentities = includeSubEntitites.boolValue;
    }
    
    // prefetch resourceID
    
    fetchRequest.propertiesToFetch = @[entityDescription.propertiesByName[[NSClassFromString(entityDescription.managedObjectClassName) resourceIDKey]]];
    
    fetchRequest.returnsObjectsAsFaults = NO;
    
    // execute fetch request...
    
    __block NSError *fetchError;
    
    __block NSArray *result;
    
    [context performBlockAndWait:^{
        
        result = [context executeFetchRequest:fetchRequest
                                        error:&fetchError];
        
    }];
    
    // invalid fetch
    
    if (fetchError) {
        
        response.statusCode = BadRequestStatusCode;
        
        return;
    }
    
    // make session belong to local context
    
    __block NSManagedObject <NOSessionProtocol> *contextSession;
    
    [context performBlockAndWait:^{
       
        contextSession = (NSManagedObject <NOSessionProtocol> *)[context objectWithID:session.objectID];
        
    }];
    
    // filter results (session must have read permissions)
    
    NSMutableArray *filteredResultsResourceIDs = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait:^{
        
        for (NSManagedObject<NOResourceProtocol> *resource in result) {
            
            NSNumber *resourceID = [resource valueForKey:[NSClassFromString(resource.entity.managedObjectClassName) resourceIDKey]];;
            
            // permission to view resource
            
            if ([resource permissionForSession:contextSession] >= ReadOnlyPermission) {
                
                // must have permission for keys accessed
                
                if (predicateKey) {
                    
                    NSRelationshipDescription *relationship = resource.entity.relationshipsByName[predicateKey];
                    
                    NSAttributeDescription *attribute = resource.entity.attributesByName[predicateKey];
                    
                    if (attribute) {
                        
                        if ([resource permissionForAttribute:predicateKey session:contextSession] < ReadOnlyPermission) {
                            
                            break;
                        }
                    }
                    
                    if (relationship) {
                        
                        if ([resource permissionForRelationship:predicateKey session:contextSession] < ReadOnlyPermission) {
                            
                            break;
                        }
                    }
                    
                }
                
                // must have read only permission for keys in sort descriptor
                
                if (sortDescriptors) {
                    
                    for (NSSortDescriptor *sort in sortDescriptors) {
                        
                        NSRelationshipDescription *relationship = resource.entity.relationshipsByName[sort.key];
                        
                        NSAttributeDescription *attribute = resource.entity.attributesByName[sort.key];
                        
                        if (attribute) {
                            
                            if ([resource permissionForAttribute:sort.key session:contextSession] >= ReadOnlyPermission) {
                                
                                [filteredResultsResourceIDs addObject:resourceID];
                            }
                        }
                        
                        if (relationship) {
                            
                            if (![resource permissionForRelationship:sort.key session:contextSession] >= ReadOnlyPermission) {
                                
                                [filteredResultsResourceIDs addObject:resourceID];
                            }
                        }
                    }
                }
                
                else {
                    
                    [filteredResultsResourceIDs addObject:resourceID];
                }
            }
        }
        
    }];
    
    // return the resource IDs of filtered objects
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:filteredResultsResourceIDs
                                                       options:self.jsonWritingOption
                                                         error:nil];
    
    if (!jsonData) {
        
        response.statusCode = InternalServerErrorStatusCode;
        
        return;
    }
    
    [response respondWithData:jsonData];
}

#pragma mark - Common methods for handlers

-(NSManagedObject<NOSessionProtocol> *)sessionWithToken:(NSString *)token error:(NSError **)error
{
    // determine the attribute name the entity uses for storing tokens
    
    NSEntityDescription *sessionEntityDescription = self.store.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.sessionEntityName];
    
    Class sessionEntityClass = NSClassFromString(sessionEntityDescription.managedObjectClassName);
    
    NSString *tokenKey = [sessionEntityClass sessionTokenKey];
    
    // search the store for session with token
    
    NSFetchRequest *sessionWithTokenFetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.sessionEntityName];
    
    sessionWithTokenFetchRequest.predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:tokenKey] rightExpression:[NSExpression expressionForConstantValue:tokenKey] modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:NSNormalizedPredicateOption];
    
    sessionWithTokenFetchRequest.fetchLimit = 1;
    
    sessionWithTokenFetchRequest.propertiesToFetch = nil;
    
    // create context
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    context.persistentStoreCoordinator = self.store.persistentStoreCoordinator;
    
    context.undoManager = nil;
    
    __block NSManagedObject <NOSessionProtocol> *session;
    
    __block NSError *fetchError;
    
    [context performBlockAndWait:^{
        
        NSArray *result = [context executeFetchRequest:sessionWithTokenFetchRequest
                                                 error:&fetchError];
        
        session = result.firstObject;
        
    }];
    
    if (fetchError) {
        
        return nil;
    }
    
    return session;
}

-(NSDictionary *)JSONRepresentationOfResource:(NSManagedObject<NOResourceProtocol> *)resource
                                   forSession:(NSManagedObject<NOSessionProtocol> *)session
{
    // build JSON object...
    
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    // first the attributes
    
    for (NSString *attributeName in resource.entity.attributesByName) {
        
        // check access permissions (unless its the resourceID, thats always visible)
        if ([resource permissionForAttribute:attributeName session:session] >= ReadOnlyPermission ||
            [attributeName isEqualToString:[[resource class] resourceIDKey]]) {
            
            // get attribute
            NSAttributeDescription *attribute = resource.entity.attributesByName[attributeName];
            
            // make sure the attribute is not transformable or undefined
            if (attribute.attributeType != NSTransformableAttributeType ||
                attribute.attributeType != NSUndefinedAttributeType) {
                
                // add to JSON representation
                jsonObject[attributeName] = [resource JSONCompatibleValueForAttribute:attributeName];
                
                // notify
                [resource attribute:attributeName
               wasAccessedBySession:session];
                
            }
        }
    }
    
    // then the relationships
    for (NSString *relationshipName in resource.entity.relationshipsByName) {
        
        NSRelationshipDescription *relationshipDescription = resource.entity.relationshipsByName[relationshipName];
        
        NSEntityDescription *destinationEntity = relationshipDescription.destinationEntity;
        
        // make sure relationship is visible
        if ([resource permissionForRelationship:relationshipName session:session] >= ReadOnlyPermission) {
            
            // make sure the destination entity class conforms to NOResourceProtocol
            if ([NSClassFromString(destinationEntity.managedObjectClassName) conformsToProtocol:@protocol(NOResourceProtocol)]) {
                
                // to-one relationship
                if (!relationshipDescription.isToMany) {
                    
                    // get destination resource
                    NSManagedObject<NOResourceProtocol> *destinationResource = [resource valueForKey:relationshipName];
                    
                    // check access permissions (the relationship & the single distination object must be visible)
                    if ([resource permissionForRelationship:relationshipName session:session] >= ReadOnlyPermission &&
                        [destinationResource permissionForSession:session ] >= ReadOnlyPermission) {
                        
                        // get resourceID
                        NSString *destinationResourceIDKey = [destinationResource.class resourceIDKey];
                        
                        NSNumber *destinationResourceID = [destinationResource valueForKey:destinationResourceIDKey];
                        
                        // add to json object
                        [jsonObject setValue:destinationResourceID
                                      forKey:relationshipName];
                    }
                }
                
                // to-many relationship
                else {
                    
                    // get destination collection
                    NSArray *toManyRelationship = [resource valueForKey:relationshipName];
                    
                    // only add resources that are visible
                    NSMutableArray *visibleRelationship = [[NSMutableArray alloc] init];
                    
                    for (NSManagedObject<NOResourceProtocol> *destinationResource in toManyRelationship) {
                        
                        if ([destinationResource permissionForRelationship:relationshipName session:session] >= ReadOnlyPermission) {
                            
                            // get destination resource ID
                            
                            NSString *destinationResourceIDKey = [destinationResource.class resourceIDKey];
                            
                            NSNumber *destinationResourceID = [destinationResource valueForKey:destinationResourceIDKey];
                            
                            [visibleRelationship addObject:destinationResourceID];
                        }
                    }
                    
                    // add to jsonObject
                    [jsonObject setValue:visibleRelationship
                                  forKey:relationshipName];
                }
                
                // notify
                [resource relationship:relationshipName
                  wasAccessedBySession:session];
                
            }
        }
    }
    
    // notify object
    [resource wasAccessedBySession:session];
    
    return jsonObject;
}

-(BOOL)setValuesForResource:(NSManagedObject<NOResourceProtocol> *)resource
             fromJSONObject:(NSDictionary *)jsonObject
                    session:(NSManagedObject<NOSessionProtocol> *)session
                      error:(NSError **)error
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
                
                NSManagedObject<NOResourceProtocol> *destinationResource = [_store resourceWithEntityDescription:relationshipDescription.destinationEntity resourceID:destinationResourceID shouldPrefetch:NO error:error];
                
                if (*error) {
                    
                    return NO;
                }
                
                [resource setValue:[resource.managedObjectContext objectWithID:destinationResource.objectID]
                            forKey:key];
                
            }
            
            // to many relationship
            else {
                
                NSArray *resourceIDs = (NSArray *)value;
                
                // build array to replace old to-many relationsip
                NSMutableSet *newRelationshipValues = [[NSMutableSet alloc] init];
                
                for (NSNumber *destinationResourceID in resourceIDs) {
                    
                    // get the destination resource
                    
                    NSManagedObject<NOResourceProtocol> *destinationResource = [_store resourceWithEntityDescription:relationshipDescription.destinationEntity resourceID:destinationResourceID shouldPrefetch:NO error:error];
                    
                    if (*error) {
                        
                        return NO;
                    }
                    
                    [newRelationshipValues addObject:[resource.managedObjectContext objectWithID:destinationResource.objectID]];
                }
                
                // replace collection
                [resource setValue:newRelationshipValues
                            forKey:key];
            }
            
            // notify
            [resource relationship:key
                wasEditedBySession:session];
        }
    }
    
    // notify
    [resource wasEditedBySession:session];
    
    return YES;
}

-(NOServerStatusCode)verifyEditResource:(NSManagedObject<NOResourceProtocol> *)resource
                     recievedJsonObject:(NSDictionary *)recievedJsonObject
                                session:(NSManagedObject<NOSessionProtocol> *)session
{
    if ([resource permissionForSession:session] < EditPermission) {
        
        return ForbiddenStatusCode;
    }
    
    for (NSString *key in recievedJsonObject) {
        
        NSObject *jsonValue = recievedJsonObject[key];
        
        // validate the recieved JSON object
        
        if (![NSJSONSerialization isValidJSONObject:recievedJsonObject]) {
            
            return BadRequestStatusCode;
        }
        
        BOOL isAttribute;
        BOOL isRelationship;
        
        for (NSString *attributeName in resource.entity.attributesByName) {
            
            // found attribute with same name
            if ([key isEqualToString:attributeName]) {
                
                isAttribute = YES;
                
                // check if this key is the resourceIDKey
                NSString *resourceIDKey = [[resource class] resourceIDKey];
                
                // resourceID cannot be edited by anyone
                if ([key isEqualToString:resourceIDKey]) {
                    
                    return ForbiddenStatusCode;
                }
                
                NSAttributeDescription *attribute = resource.entity.attributesByName[attributeName];
                
                // make sure the attribute to edit is not transformable or undefined
                if (attribute.attributeType == NSTransformableAttributeType ||
                    attribute.attributeType == NSUndefinedAttributeType) {
                    
                    return BadRequestStatusCode;
                }
                
                // get pre-edit value
                NSObject *newValue = [resource attributeValueForJSONCompatibleValue:jsonValue
                                                                       forAttribute:key];
                
                // validate that the pre-edit value is of the same class as the attribute it will be given
                
                if (![resource isValidConvertedValue:newValue
                                        forAttribute:attributeName]) {
                    
                    return BadRequestStatusCode;
                }
                
                // let NOResource verify that the new attribute value is a valid new value
                if (![resource validateValue:&newValue
                                      forKey:attributeName
                                       error:nil]) {
                    
                    return BadRequestStatusCode;
                }
            }
        }
        
        for (NSString *relationshipName in resource.entity.relationshipsByName) {
            
            // found relationship with that name...
            if ([key isEqualToString:relationshipName] ) {
                
                isRelationship = YES;
                
                NSRelationshipDescription *relationshipDescription = resource.entity.relationshipsByName[key];
                
                // to-one relationship
                if (!relationshipDescription.isToMany) {
                    
                    // must be number
                    if (![jsonValue isKindOfClass:[NSNumber class]]) {
                        
                        return BadRequestStatusCode;
                    }
                    
                    NSNumber *destinationResourceID = (NSNumber *)jsonValue;
                    
                    NSError *error;
                    
                    NSManagedObject<NOResourceProtocol> *newValue = [_store resourceWithEntityDescription:relationshipDescription.entity resourceID:destinationResourceID shouldPrefetch:NO error:&error];
                    
                    if (error) {
                        
                        return InternalServerErrorStatusCode;
                    }
                    
                    if (!newValue) {
                        
                        return BadRequestStatusCode;
                    }
                    
                    // destination resource must be visible
                    if ([newValue permissionForSession:session] < ReadOnlyPermission) {
                        
                        return ForbiddenStatusCode;
                    }
                    
                    // must be valid value
                    if (![resource validateValue:&newValue
                                          forKey:key
                                           error:nil]) {
                        
                        return BadRequestStatusCode;
                    }
                }
                
                // to-many relationship
                else {
                    
                    // must be array
                    if (![jsonValue isKindOfClass:[NSArray class]]) {
                        
                        return BadRequestStatusCode;
                    }
                    
                    NSArray *jsonReplacementCollection = (NSArray *)jsonValue;
                    
                    // build new value
                    NSMutableArray *newValue = [[NSMutableArray alloc] init];
                    
                    for (NSNumber *destinationResourceID in jsonReplacementCollection) {
                        
                        NSError *error;
                        
                        NSManagedObject<NOResourceProtocol> *destinationResource = [_store resourceWithEntityDescription:relationshipDescription.entity resourceID:destinationResourceID shouldPrefetch:NO error:&error];
                        
                        if (error) {
                            
                            return InternalServerErrorStatusCode;
                        }
                        
                        if (!destinationResource) {
                            
                            return BadRequestStatusCode;
                        }
                        
                        // check permissions
                        if ([destinationResource permissionForSession:session] < ReadOnlyPermission) {
                            
                            return ForbiddenStatusCode;
                        }
                        
                    }
                    
                    // must be valid new value
                    if (![resource validateValue:&newValue
                                          forKey:key
                                           error:nil]) {
                        
                        return BadRequestStatusCode;
                    }
                }
            }
        }
        
        // no attribute or relationship with that name found
        if (!isAttribute && !isRelationship) {
            
            return BadRequestStatusCode;
        }
    }
    
    return OKStatusCode;
}


@end
