//
//  NOIncrementalStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 3/28/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOIncrementalStore.h"
#import "NOResourceProtocol.h"
#import "NOSessionProtocol.h"
#import "NOUserProtocol.h"
#import "NOClientProtocol.h"
#import "NOServerConstants.h"
#import "NetworkObjectsConstants.h"
#import "NSManagedObject+CoreDataJSONCompatibility.h"

// Options

NSString *const NOIncrementalStoreURLSessionOption = @"NOIncrementalStoreURLSessionOption";

NSString *const NOIncrementalStoreUserEntityNameOption = @"NOIncrementalStoreUserEntityNameOption";

NSString *const NOIncrementalStoreSessionEntityNameOption = @"NOIncrementalStoreSessionEntityNameOption";

NSString *const NOIncrementalStoreClientEntityNameOption = @"NOIncrementalStoreClientEntityNameOption";

NSString *const NOIncrementalStoreLoginPathOption = @"NOIncrementalStoreLoginPathOption";

NSString *const NOIncrementalStoreSearchPathOption = @"NOIncrementalStoreSearchPathOption";



@implementation NOIncrementalStore (CommonErrors)

-(NSError *)invalidServerResponseError
{
    
    NSString *description = NSLocalizedString(@"The server returned a invalid response",
                                              @"The server returned a invalid response");
    
    NSError *error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                         code:NOIncrementalStoreInvalidServerResponseErrorCode
                                     userInfo:@{NSLocalizedDescriptionKey: description}];
    
    return error;
}

-(NSError *)badRequestError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"Invalid request",
                                                  @"Invalid request");
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOIncrementalStoreBadRequestErrorCode
                                userInfo:@{NSLocalizedDescriptionKey: description}];
        
    }
    
    return error;
}

-(NSError *)serverError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"The server suffered an internal error",
                                                  @"The server suffered an internal error");
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOIncrementalStoreServerInternalErrorCode
                                userInfo:@{NSLocalizedDescriptionKey: description}];
        
    }
    
    return error;
}

-(NSError *)unauthorizedError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"Authentication is required",
                                                  @"Authentication is required");
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOIncrementalStoreUnauthorizedErrorCode
                                userInfo:@{NSLocalizedDescriptionKey: description}];
    }
    
    return error;
}

-(NSError *)notFoundError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"Resource was not found",
                                                  @"Resource was not found");
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOIncrementalStoreNotFoundErrorCode
                                userInfo:@{NSLocalizedDescriptionKey: description}];
    }
    
    return error;
}

@end

@implementation NOIncrementalStore (Common)

-(Class)entityClassWithResourceName:(NSString *)resourceName
                            context:(NSManagedObjectContext *)context
{
    NSEntityDescription *entity = context.persistentStoreCoordinator.managedObjectModel.entitiesByName[resourceName];
    
    if (!entity) {
        
        [NSException raise:NSInvalidArgumentException
                    format:@"No entity in the model matches '%@'", resourceName];
    }
    
    Class entityClass = NSClassFromString(entity.managedObjectClassName);
    
    return entityClass;
}

@end

@implementation NSEntityDescription (Convert)

-(NSDictionary *)jsonObjectFromCoreDataValues:(NSDictionary *)values
{
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    // convert values...
    
    for (NSString *attributeName in self.attributesByName) {
        
        for (NSString *key in values) {
            
            // found matching key (will only run once because dictionaries dont have duplicates)
            if ([key isEqualToString:attributeName]) {
                
                id value = [values valueForKey:key];
                
                id jsonValue = [self JSONCompatibleValueForAttributeValue:value
                                                             forAttribute:key];
                
                jsonObject[key] = jsonValue;
                
                break;
            }
        }
    }
    
    for (NSString *relationshipName in self.relationshipsByName) {
        
        NSRelationshipDescription *relationship = self.relationshipsByName[relationshipName];
        
        for (NSString *key in values) {
            
            // found matching key (will only run once because dictionaries dont have duplicates)
            if ([key isEqualToString:relationshipName]) {
                
                // destination entity
                NSEntityDescription *destinationEntity = relationship.destinationEntity;
                
                Class entityClass = NSClassFromString(destinationEntity.managedObjectClassName);
                
                NSString *destinationResourceIDKey = [entityClass resourceIDKey];
                
                // to-one relationship
                if (!relationship.isToMany) {
                    
                    // get resource ID of object
                    
                    NSManagedObject<NOResourceKeysProtocol> *destinationResource = values[key];
                    
                    NSNumber *destinationResourceID = [destinationResource valueForKey:destinationResourceIDKey];
                    
                    jsonObject[key] = destinationResourceID;
                    
                }
                
                // to-many relationship
                else {
                    
                    NSSet *destinationResources = [values valueForKey:relationshipName];
                    
                    NSMutableArray *destinationResourceIDs = [[NSMutableArray alloc] init];
                    
                    for (NSManagedObject *destinationResource in destinationResources) {
                        
                        NSNumber *destinationResourceID = [destinationResource valueForKey:destinationResourceIDKey];
                        
                        [destinationResourceIDs addObject:destinationResourceID];
                    }
                    
                    jsonObject[key] = destinationResourceIDs;
                    
                }
                
                break;
            }
        }
    }
    
    return jsonObject;
}

@end

@implementation NOIncrementalStore (Convert)

-(NSDictionary *)coreDataFaultingValuesForObjectID:(NSManagedObjectID *)objectID
                                        JSONObject:(NSDictionary *)jsonObject
{
    // convert to Core Data values
    
    NSMutableDictionary *values = [[NSMutableDictionary alloc] initWithCapacity:jsonObject.allKeys.count];
    
    NSEntityDescription *entity = objectID.entity;
    
    for (NSString *attributeName in entity.attributesByName) {
        
        for (NSString *key in jsonObject) {
            
            // found matching key (will only run once because dictionaries dont have duplicates)
            if ([key isEqualToString:attributeName]) {
                
                id jsonValue = jsonObject[key];
                
                id value = [entity attributeValueForJSONCompatibleValue:jsonValue
                                                           forAttribute:attributeName];
                
                values[key] = value;
                
                break;
            }
        }
    }
    
    for (NSString *relationshipName in entity.relationshipsByName) {
        
        NSRelationshipDescription *relationship = entity.relationshipsByName[relationshipName];
        
        for (NSString *key in jsonObject) {
            
            // found matching key (will only run once because dictionaries dont have duplicates)
            if ([key isEqualToString:relationshipName]) {
                
                // destination entity
                NSEntityDescription *destinationEntity = relationship.destinationEntity;
                
                // to-one relationship
                if (!relationship.isToMany) {
                    
                    // get the resource ID
                    NSNumber *destinationResourceID = jsonObject[relationshipName];
                    
                    if (destinationResourceID) {
                        
                        // create new Object ID
                        
                        NSManagedObjectID *objectID = [self newObjectIDForEntity:destinationEntity
                                                                 referenceObject:destinationResourceID];
                        
                        values[key] = objectID;
                    }
                    
                    else {
                        
                        values[key] = [NSNull null];
                    }
                }
                
                // to-many relationship
                else {
                    
                    // get the resourceIDs
                    NSArray *destinationResourceIDs = jsonObject[relationshipName];
                    
                    NSMutableArray *destinationResources = [[NSMutableArray alloc] init];
                    
                    for (NSNumber *destinationResourceID in destinationResourceIDs) {
                        
                        NSManagedObjectID *objectID = [self newObjectIDForEntity:destinationEntity
                                                                 referenceObject:destinationResourceID];
                        
                        [destinationResources addObject:objectID];
                    }
                    
                    values[key] = destinationResources;
                }
                
                break;
                
            }
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:values];
}

@end

@interface NOIncrementalStore ()

@property NSString *sessionEntityName;

@property NSString *userEntityName;

@property NSString *clientEntityName;

@property NSString *loginPath;

@property NSString *searchPath;

@property NSURLSession *urlSession;

@property (readonly) NSJSONWritingOptions jsonWritingOption;

// Private JSON API Calls

-(NSURLSessionDataTask *)searchWithFetchRequest:(NSFetchRequest *)fetchRequest
                                        context:(NSManagedObjectContext *)context
                                     completion:(void (^)(NSError *, NSArray *))completionBlock;

-(NSURLSessionDataTask *)getResource:(NSString *)resourceName
                              withID:(NSUInteger)resourceID
                             context:(NSManagedObjectContext *)context
                          completion:(void (^)(NSError *, NSDictionary *))completionBlock;

-(NSURLSessionDataTask *)editResource:(NSString *)resourceName
                               withID:(NSUInteger)resourceID
                              changes:(NSDictionary *)changes
                              context:(NSManagedObjectContext *)context
                           completion:(void (^)(NSError *error))completionBlock;

-(NSURLSessionDataTask *)deleteResource:(NSString *)resourceName
                                 withID:(NSUInteger)resourceID
                                context:(NSManagedObjectContext *)context
                             completion:(void (^)(NSError *error))completionBlock;

-(NSURLSessionDataTask *)createResource:(NSString *)resourceName
                      withInitialValues:(NSDictionary *)initialValues
                                context:(NSManagedObjectContext *)context
                             completion:(void (^)(NSError *error, NSNumber *resourceID))completionBlock;

@end

@implementation NOIncrementalStore

#pragma mark - Initialization

+(void)initialize
{
    if (self == [NOIncrementalStore self]) {
        
        [NSPersistentStoreCoordinator registerStoreClass:self
                                            forStoreType:NSStringFromClass(self)];
    }
}

+(NSString *)storeType
{
    return NSStringFromClass(self);
}

-(id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root
                      configurationName:(NSString *)name
                                    URL:(NSURL *)url
                                options:(NSDictionary *)options
{
    self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options];
    
    if (self) {
        
        self.sessionEntityName = options[NOIncrementalStoreSessionEntityNameOption];
        
        self.userEntityName = options[NOIncrementalStoreUserEntityNameOption];
        
        self.clientEntityName = options[NOIncrementalStoreClientEntityNameOption];
        
        self.loginPath = options[NOIncrementalStoreLoginPathOption];
        
        self.searchPath = options[NOIncrementalStoreSearchPathOption];
        
        self.urlSession = options[NOIncrementalStoreURLSessionOption];
        
        // use default session
        
        if (!self.urlSession) {
            
            self.urlSession = [NSURLSession sharedSession];
        }
        
    }
    
    return self;
}

-(BOOL)loadMetadata:(NSError *__autoreleasing *)error
{
    self.metadata = @{NSStoreTypeKey: NSStringFromClass([self class]),
                      NSStoreUUIDKey : [[NSUUID UUID] UUIDString]};
    
    if (!self.sessionEntityName || !self.userEntityName || !self.clientEntityName || !self.searchPath) {
        
        // return error
        
        // [NSException raise:NSInvalidArgumentException
        //             format:@"Required initialzation options were not included in the options dictionary"];
        
        return NO;
    }
    
    if (!self.URL) {
        
        // error
        
        return NO;
    }
    
    return YES;
}

#pragma mark - Request

-(id)executeRequest:(NSPersistentStoreRequest *)request
        withContext:(NSManagedObjectContext *)context
              error:(NSError *__autoreleasing *)error
{
    if (request.requestType == NSSaveRequestType) {
        
        NSSaveChangesRequest *saveRequest = (NSSaveChangesRequest *)request;
        
        return [self executeSaveRequest:saveRequest
                            withContext:context
                                  error:error];
    }
    
    NSFetchRequest *fetchRequest = (NSFetchRequest *)request;
    
    return [self executeFetchRequest:fetchRequest
                         withContext:context
                               error:error];
}

-(id)executeFetchRequest:(NSFetchRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error
{
    __block NSArray *results;
    
    // create semaphore
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // start remote fetch
    [self searchWithFetchRequest:request context:context completion:^(NSError *remoteError, NSArray *remoteResults) {
        
        if (remoteError) {
            *error = (__bridge id)(__bridge_retained CFTypeRef)remoteError;
        }
        
        else {
            
            results = remoteResults;
            
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (*error) {
        
        return nil;
    }
    
    // success fetching from server, convert to Core Data
    
    if (request.resultType == NSCountResultType) {
        
        return @[@(results.count)];
    }
    
    // build array of object IDs
    
    NSMutableArray *objectIDs = [[NSMutableArray alloc] initWithCapacity:results.count];
    
    for (NSNumber *resourceID in results) {
        
        NSManagedObjectID *objectID = [self newObjectIDForEntity:request.entity
                                                 referenceObject:resourceID];
        
        [objectIDs addObject:objectID];
        
    }
    
    if (request.resultType == NSDictionaryResultType) {
        
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        
        // TEMP to do
        
        return dictionary;
        
    }
    
    if (request.resultType == NSManagedObjectIDResultType) {
        
        return [NSArray arrayWithArray:objectIDs];
    }
    
    // NSManagedObject
    
    NSMutableArray *managedObjects = [[NSMutableArray alloc] init];
    
    for (NSManagedObjectID *objectID in objectIDs) {
        
        NSManagedObject *managedObject = [context objectWithID:objectID];
        
        // download values if fault or for prefetching
        
        if (managedObject.isFault || request.propertiesToFetch || request.relationshipKeyPathsForPrefetching) {
            
            NSDictionary *values = [self downloadValuesForObjectWithID:objectID withContext:context error:error];
            
            if (*error) {
                
                return nil;
            }
            
            // set values
            
            for (NSString *key in values) {
                
                NSAttributeDescription *attribute = objectID.entity.attributesByName[key];
                
                NSRelationshipDescription *relationship = objectID.entity.relationshipsByName[key];
                
                id value = values[key];
                
                // attribute
                
                if (attribute) {
                    
                    if (value == [NSNull null]) {
                        
                        [managedObject setValue:nil
                                                  forKey:key];
                    }
                    else {
                        
                        [managedObject setValue:value
                                                  forKey:key];
                    }
                }
                
                // relationship
                
                if (relationship) {
                    
                    // to-one
                    
                    if (!relationship.isToMany) {
                        
                        if (value == [NSNull null]) {
                            
                            [managedObject setValue:nil
                                                      forKey:key];
                        }
                        else {
                            
                            NSManagedObject *destinationObject = [context objectWithID:value];
                            
                            [managedObject setValue:destinationObject
                                                      forKey:key];
                        }
                    }
                    
                    // to-many relationship
                    
                    else {
                        
                        if (value == [NSNull null]) {
                            
                            [managedObject setValue:nil
                                                      forKey:key];
                        }
                        
                        else {
                            
                            NSArray *destinationObjectIDs = value;
                            
                            NSMutableSet *destinationObjects = [[NSMutableSet alloc] initWithCapacity:destinationObjectIDs.count];
                            
                            for (NSManagedObjectID *objectID in destinationObjectIDs) {
                                
                                NSManagedObject *object = [context objectWithID:objectID];
                                
                                [destinationObjects addObject:object];
                            }
                            
                            [managedObject setValue:destinationObjects
                                                      forKey:key];
                        }
                    }
                }
            }
        }
        
        [managedObjects addObject:managedObject];
    }
    
    return [NSArray arrayWithArray:managedObjects];
}

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error
{
    
    
    return nil;
}

#pragma mark - Faulting

-(NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID
                                        withContext:(NSManagedObjectContext *)context
                                              error:(NSError *__autoreleasing *)error
{
    // create semaphore
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // get reference object
    
    NSNumber *resourceID = [self referenceObjectForObjectID:objectID];
    
    if (!resourceID) {
        
        return nil;
    }
    
    __block NSDictionary *jsonObject;
    
    [self getResource:objectID.entity.name withID:resourceID.integerValue context:context completion:^(NSError *remoteError, NSDictionary *JSONResponse) {
        
        if (remoteError) {
            *error = (__bridge id)(__bridge_retained CFTypeRef)remoteError;
        }
        
        else {
            
            jsonObject = JSONResponse;
            
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (*error) {
        
        return nil;
    }
    
    NSDictionary *values = [self coreDataFaultingValuesForObjectID:objectID
                                                        JSONObject:jsonObject];
    
    NSIncrementalStoreNode *storeNode = [[NSIncrementalStoreNode alloc] initWithObjectID:objectID
                                                                              withValues:values
                                                                                 version:0];
    
    return storeNode;
}

-(NSDictionary *)downloadValuesForObjectWithID:(NSManagedObjectID *)objectID
                                   withContext:(NSManagedObjectContext *)context
                                         error:(NSError **)error
{
    // create semaphore
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // get reference object
    
    NSNumber *resourceID = [self referenceObjectForObjectID:objectID];
    
    if (!resourceID) {
        
        return nil;
    }
    
    __block NSDictionary *jsonObject;
    
    [self getResource:objectID.entity.name withID:resourceID.integerValue context:context completion:^(NSError *remoteError, NSDictionary *JSONResponse) {
        
        if (remoteError) {
            *error = (__bridge id)(__bridge_retained CFTypeRef)remoteError;
        }
        
        else {
            
            jsonObject = JSONResponse;
            
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (*error) {
        
        return nil;
    }
    
    NSDictionary *values = [self coreDataFaultingValuesForObjectID:objectID
                                                        JSONObject:jsonObject];
    
    return values;
}

-(id)newValueForRelationship:(NSRelationshipDescription *)relationship
             forObjectWithID:(NSManagedObjectID *)objectID
                 withContext:(NSManagedObjectContext *)context
                       error:(NSError *__autoreleasing *)error
{
    // relationships are not lazily fetched
    
    return nil;
}

#pragma mark - JSON Writing Option

-(NSJSONWritingOptions)jsonWritingOption
{
    if (self.prettyPrintJSON) {
        return NSJSONWritingPrettyPrinted;
    }
    
    return 0;
}

#pragma mark - API

-(NSURLSessionDataTask *)loginWithContext:(NSManagedObjectContext *)context
                               completion:(void (^)(NSError *))completionBlock
{
    if (!self.clientResourceID ||
        !self.clientSecret) {
        
        [NSException raise:NSInternalInconsistencyException
                    format:@"clientResourceID and clientSecret are required for authentication"];
        
        return nil;
    }
    
    // build login URL
    
    NSURL *loginUrl = [self.URL URLByAppendingPathComponent:self.loginPath];
    
    // put togeather POST body...
    
    NSManagedObjectModel *model = context.persistentStoreCoordinator.managedObjectModel;
    
    NSEntityDescription *sessionEntity = model.entitiesByName[self.sessionEntityName];
    
    Class sessionEntityClass = NSClassFromString(sessionEntity.managedObjectClassName);
    
    NSString *sessionTokenKey = [sessionEntityClass sessionTokenKey];
    
    NSString *sessionUserKey = [sessionEntityClass sessionUserKey];
    
    NSString *sessionClientKey = [sessionEntityClass sessionClientKey];
    
    NSEntityDescription *clientEntity = model.entitiesByName[self.clientEntityName];
    
    Class clientEntityClass = NSClassFromString(clientEntity.managedObjectClassName);
    
    NSString *clientResourceIDKey = [clientEntityClass resourceIDKey];
    
    NSString *clientSecretKey = [clientEntityClass clientSecretKey];
    
    NSEntityDescription *userEntity = model.entitiesByName[self.userEntityName];
    
    Class userEntityClass = NSClassFromString(userEntity.managedObjectClassName);
    
    NSString *usernameKey = [userEntityClass usernameKey];
    
    NSString *userPasswordKey = [userEntityClass userPasswordKey];
    
    NSMutableDictionary *loginJSONObject = [[NSMutableDictionary alloc] init];
    
    // need at least client info to login
    [loginJSONObject addEntriesFromDictionary:@{sessionClientKey:
                                                    @{clientResourceIDKey: self.clientResourceID,
                                                      clientSecretKey : self.clientSecret}}];
    
    // add user to authentication if available
    
    if (self.username && self.userPassword) {
        
        [loginJSONObject addEntriesFromDictionary:@{sessionUserKey: @{usernameKey: self.username, userPasswordKey : self.userPassword}}];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginUrl];
    
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:loginJSONObject
                                                       options:self.jsonWritingOption
                                                         error:nil];
    
    request.HTTPMethod = @"POST";
    
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != 200) {
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError);
                
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"The login failed",
                                                               @"The login failed");
                
                NSError *loginFailedError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                                code:NOIncrementalStoreLoginFailedErrorCode
                                                            userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                completionBlock(loginFailedError);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError);
            
            return;
        }
        
        // parse response
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
        
        if (!jsonResponse ||
            ![jsonResponse isKindOfClass:[NSDictionary class]]) {
            
            completionBlock(self.invalidServerResponseError);
            
            return;
        }
        
        // get session token key
        
        NSString *token = jsonResponse[sessionTokenKey];
        
        if (!token) {
            
            completionBlock(self.invalidServerResponseError);
            
            return;
        }
        
        // get user ID if availible
        
        NSNumber *userResourceID = jsonResponse[sessionUserKey];
        
        if (userResourceID) {
            
            self.userResourceID = userResourceID;
        }
        
        self.sessionToken = token;
        
        completionBlock(nil);
        
    }];
    
    [task resume];
    
    return task;
}

-(NSURLSessionDataTask *)performFunction:(NSString *)functionName
                              onResource:(NSString *)resourceName
                                  withID:(NSUInteger)resourceID
                          withJSONObject:(NSDictionary *)jsonObject
                                 context:(NSManagedObjectContext *)context
                              completion:(void (^)(NSError *, NSNumber *, NSDictionary *))completionBlock
{
    // build URL
    
    Class entityClass = [self entityClassWithResourceName:resourceName
                                                  context:context];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *deleteResourceURL = [self.URL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    deleteResourceURL = [deleteResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deleteResourceURL];
    
    request.HTTPMethod = @"POST";
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    // add HTTP body
    if (jsonObject) {
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                           options:self.jsonWritingOption
                                                             error:nil];
        
        if (!jsonData) {
            
            [NSException raise:NSInvalidArgumentException
                        format:@"Invalid jsonObject NSDictionary argument. Not valid JSON."];
            
            return nil;
        }
        
        request.HTTPBody = jsonData;
    }
    
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error, nil, nil);
            
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        NSNumber *statusCode = @(httpResponse.statusCode);
        
        // get response body
        
        NSDictionary *jsonResponse;
        
        if (data) {
            
            jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                           options:NSJSONReadingAllowFragments
                                                             error:nil];
            
            if (![jsonResponse isKindOfClass:[NSDictionary class]]) {
                
                jsonResponse = nil;
            }
        }
        
        completionBlock(nil, statusCode, jsonResponse);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)searchWithFetchRequest:(NSFetchRequest *)fetchRequest
                                        context:(NSManagedObjectContext *)context
                                     completion:(void (^)(NSError *, NSArray *))completionBlock
{
    // Build URL
    
    Class entityClass = [self entityClassWithResourceName:fetchRequest.entityName context:context];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *searchURL = [self.URL URLByAppendingPathComponent:self.searchPath];
    
    searchURL = [searchURL URLByAppendingPathComponent:resourcePath];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:searchURL];
    
    urlRequest.HTTPMethod = @"POST";
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [urlRequest addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    // build JSON dictionary of search parameters from fetch request
    
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    // Optional comparison predicate
    
    NSComparisonPredicate *predicate = (NSComparisonPredicate *)fetchRequest.predicate;
    
    if (predicate) {
        
        if (![predicate isKindOfClass:[NSComparisonPredicate class]]) {
            
            [NSException raise:NSInvalidArgumentException
                        format:@"The fetch request's predicate must be of type NSComparisonPredicate"];
            
            return nil;
        }
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateKeyParameter]] = predicate.leftExpression.keyPath;
        
        // convert value to from Core Data to JSON
        
        id jsonValue = [fetchRequest.entity jsonObjectFromCoreDataValues:@{predicate.leftExpression.keyPath: predicate.rightExpression.constantValue}].allValues.firstObject;
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateValueParameter]] = jsonValue;
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateOperatorParameter]] = [NSNumber numberWithInteger:predicate.predicateOperatorType];
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateOptionParameter]] = [NSNumber numberWithInteger:predicate.options];
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateModifierParameter]] = [NSNumber numberWithInteger:predicate.comparisonPredicateModifier];
    }
    
    // other fetch parameters
    
    if (fetchRequest.fetchLimit) {
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchFetchLimitParameter]] = [NSNumber numberWithInteger: fetchRequest.fetchLimit];
    }
    
    if (fetchRequest.fetchOffset) {
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchFetchOffsetParameter]] = [NSNumber numberWithInteger:fetchRequest.fetchOffset];
    }
    
    if (fetchRequest.includesSubentities) {
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchIncludesSubentitiesParameter]] = [NSNumber numberWithInteger:fetchRequest.includesSubentities];
    }
    
    // sort descriptors
    
    if (fetchRequest.sortDescriptors.count) {
        
        NSMutableArray *jsonSortDescriptors = [[NSMutableArray alloc] init];
        
        for (NSSortDescriptor *sort in fetchRequest.sortDescriptors) {
            
            [jsonSortDescriptors addObject:@{sort.key: @(sort.ascending)}];
        }
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchSortDescriptorsParameter]] = jsonSortDescriptors;
    }
    
    // add JSON data
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:self.jsonWritingOption
                                                         error:nil];
    if (!jsonData) {
        
        [NSException raise:NSInvalidArgumentException
                    format:@"Invalid parameters NSDictionary argument. Not valid JSON."];
        
        return nil;
    }
    
    urlRequest.HTTPBody = jsonData;
    
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // error codes
        
        if (httpResponse.statusCode != OKStatusCode) {
            
            if (httpResponse.statusCode == UnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to perform search is denied",
                                                               @"Permission to perform search is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOIncrementalStoreForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == InternalServerErrorStatusCode) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError, nil);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // parse response
        
        NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                options:NSJSONReadingAllowFragments
                                                                  error:nil];
        
        if (!jsonResponse ||
            ![jsonResponse isKindOfClass:[NSArray class]]) {
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // verify that values are numbers
        
        for (NSNumber *resultResourceID in jsonResponse) {
            
            if (![resultResourceID isKindOfClass:[NSNumber class]]) {
                
                completionBlock(self.invalidServerResponseError, nil);
                
                return;
            }
        }
        
        completionBlock(nil, jsonResponse);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)getResource:(NSString *)resourceName
                              withID:(NSUInteger)resourceID
                             context:(NSManagedObjectContext *)context
                          completion:(void (^)(NSError *, NSDictionary *))completionBlock
{
    // build URL
    
    Class entityClass = [self entityClassWithResourceName:resourceName
                                                  context:context];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *getResourceURL = [self.URL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    getResourceURL = [getResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:getResourceURL];
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != 200) {
            
            if (httpResponse.statusCode == UnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Access to resource is denied",
                                                               @"Access to resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOIncrementalStoreForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == InternalServerErrorStatusCode) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NotFoundStatusCode) {
                
                completionBlock([self notFoundError], nil);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // parse response
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
        
        if (!jsonResponse ||
            ![jsonResponse isKindOfClass:[NSDictionary class]]) {
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        completionBlock(nil, jsonResponse);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)createResource:(NSString *)resourceName
                      withInitialValues:(NSDictionary *)initialValues
                                context:(NSManagedObjectContext *)context
                             completion:(void (^)(NSError *, NSNumber *))completionBlock
{
    // build URL...
    
    Class entityClass = [self entityClassWithResourceName:resourceName context:context];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *createResourceURL = [self.URL URLByAppendingPathComponent:resourcePath];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:createResourceURL];
    
    // add the initial values to request
    if (initialValues) {
        
        NSData *postData = [NSJSONSerialization dataWithJSONObject:initialValues
                                                           options:self.jsonWritingOption
                                                             error:nil];
        
        if (!postData) {
            
            completionBlock(self.badRequestError, nil);
            
            return nil;
        }
        
        request.HTTPBody = postData;
    }
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    request.HTTPMethod = @"POST";
    
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != 200) {
            
            if (httpResponse.statusCode == UnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to create new resource is denied",
                                                               @"Permission to create new resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOIncrementalStoreForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == InternalServerErrorStatusCode) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError, nil);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // parse response
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
        
        if (!jsonResponse ||
            ![jsonResponse isKindOfClass:[NSDictionary class]]) {
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // get new resource id
        
        NSEntityDescription *entity = context.persistentStoreCoordinator.managedObjectModel.entitiesByName[resourceName];
        
        Class entityClass = NSClassFromString(entity.managedObjectClassName);
        
        NSString *resourceIDKey = [entityClass resourceIDKey];
        
        NSNumber *resourceID = jsonResponse[resourceIDKey];
        
        if (!resourceID) {
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // got it!
        completionBlock(nil, resourceID);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)editResource:(NSString *)resourceName
                               withID:(NSUInteger)resourceID
                              changes:(NSDictionary *)changes
                              context:(NSManagedObjectContext *)context
                           completion:(void (^)(NSError *))completionBlock
{
    // build URL
    
    Class entityClass = [self entityClassWithResourceName:resourceName context:context];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *editResourceURL = [self.URL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    editResourceURL = [editResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:editResourceURL];
    
    request.HTTPMethod = @"PUT";
    
    // add HTTP body
    
    NSData *httpBody = [NSJSONSerialization dataWithJSONObject:changes
                                                       options:self.jsonWritingOption
                                                         error:nil];
    
    if (!httpBody) {
        
        [NSException raise:NSInvalidArgumentException
                    format:@"The 'changes' dictionary must be a valid JSON object"];
        
        return nil;
    }
    
    request.HTTPBody = httpBody;
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != 200) {
            
            if (httpResponse.statusCode == UnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError);
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to edit resource is denied",
                                                               @"Permission to edit resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOIncrementalStoreForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError);
                
                return;
            }
            
            if (httpResponse.statusCode == InternalServerErrorStatusCode) {
                
                completionBlock(self.serverError);
                
                return;
            }
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError);
            
            return;
        }
        
        completionBlock(nil);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)deleteResource:(NSString *)resourceName
                                 withID:(NSUInteger)resourceID
                                context:(NSManagedObjectContext *)context
                             completion:(void (^)(NSError *))completionBlock
{
    // build URL
    
    Class entityClass = [self entityClassWithResourceName:resourceName context:context];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *deleteResourceURL = [self.URL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    deleteResourceURL = [deleteResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deleteResourceURL];
    
    request.HTTPMethod = @"DELETE";
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != 200) {
            
            if (httpResponse.statusCode == UnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError);
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to delete resource is denied",
                                                               @"Permission to delete resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOIncrementalStoreForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError);
                
                return;
            }
            
            if (httpResponse.statusCode == InternalServerErrorStatusCode) {
                
                completionBlock(self.serverError);
                
                return;
            }
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError);
            
            return;
        }
        
        completionBlock(nil);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

@end
