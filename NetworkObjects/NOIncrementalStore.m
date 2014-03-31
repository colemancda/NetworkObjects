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

// Options

NSString *const NOIncrementalStoreURLSessionOption = @"NOIncrementalStoreURLSessionOption";

NSString *const NOIncrementalStoreUserEntityNameOption = @"NOIncrementalStoreUserEntityNameOption";

NSString *const NOIncrementalStoreSessionEntityNameOption = @"NOIncrementalStoreSessionEntityNameOption";

NSString *const NOIncrementalStoreClientEntityNameOption = @"NOIncrementalStoreClientEntityNameOption";

NSString *const NOIncrementalStoreLoginPathOption = @"NOIncrementalStoreLoginPathOption";

NSString *const NOIncrementalStoreSearchPathOption = @"NOIncrementalStoreSearchPathOption";

// categories

@implementation NOIncrementalStore (NSJSONWritingOption)

-(NSJSONWritingOptions)jsonWritingOption
{
    if (self.prettyPrintJSON) {
        return NSJSONWritingPrettyPrinted;
    }
    
    return 0;
}

@end


@implementation NOIncrementalStore (Requests)

-(id)executeFetchRequest:(NSFetchRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error
{
    // create a group dispatch and queue
    dispatch_queue_t queue = dispatch_queue_create("com.ColemanCDA.NetworkObjects.NOIncrementalStoreFetchFromNetworkQueue", NULL);
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    
    __block NSArray *results;
    
    // start remote fetch
    [self.cachedStore searchForCachedResourceWithFetchRequest:request URLSession:self.urlSession completion:^(NSError *remoteError, NSArray *remoteResults) {
        
        if (remoteError) {
            *error = (__bridge id)(__bridge_retained CFTypeRef)remoteError;
        }
        
        else {
            
            results = remoteResults;
            
        }
        
        dispatch_group_leave(group);
        
    }];
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    if (*error) {
        
        return nil;
    }
    
    // success
    
    
    
    // forward error
    
    NSDictionary *userInfo;
    
    if (remoteError) {
        
        userInfo = @{NOIncrementalStoreErrorKey: remoteError,
                     NOIncrementalStoreRequestKey: request};
        
    }
    
    else {
        
        // Immediately return cached values
        
        NSManagedObjectContext *cacheContext = self.cachedStore.context;
        
        NSArray *results;
        
        __block NSArray *cachedResults;
        
        NSFetchRequest *cacheFetchRequest = fetchRequest.copy;
        
        // forward fetch to cache
        
        if (fetchRequest.resultType == NSCountResultType ||
            fetchRequest.resultType == NSDictionaryResultType) {
            
            [cacheContext performBlockAndWait:^{
                
                cachedResults = [cacheContext executeFetchRequest:cacheFetchRequest
                                                            error:error];
            }];
            
            results = cachedResults;
        }
        
        // ManagedObjectID & faults
        
        if (fetchRequest.resultType == NSManagedObjectResultType ||
            fetchRequest.resultType == NSManagedObjectIDResultType) {
            
            // fetch resourceID from cache
            
            cacheFetchRequest.resultType = NSManagedObjectResultType;
            
            NSString *resourceIDKey = [NSClassFromString(fetchRequest.entity.managedObjectClassName) resourceIDKey];
            
            cacheFetchRequest.propertiesToFetch = @[resourceIDKey];
            
            [cacheContext performBlockAndWait:^{
                
                cachedResults = [cacheContext executeFetchRequest:cacheFetchRequest
                                                            error:error];
            }];
            
            // error
            
            if (!cachedResults) {
                
                return nil;
            }
            
            // build array of object ids
            
            NSMutableArray *managedObjectIDs = [NSMutableArray arrayWithCapacity:cachedResults.count];
            
            for (NSManagedObject *cachedManagedObject in cachedResults) {
                
                NSNumber *resourceID = [cachedManagedObject valueForKey:resourceIDKey];
                
                NSManagedObjectID *managedObjectID = [self newObjectIDForEntity:fetchRequest.entity
                                                                referenceObject:resourceID];
                
                [managedObjectIDs addObject:managedObjectID];
            }
            
            // object ID result type
            
            if (fetchRequest.resultType == NSManagedObjectIDResultType) {
                
                results = [NSArray arrayWithArray:managedObjectIDs];
            }
            
            // managed object result. return non-faulted NSManagedObject (only resource ID).
            
            if (fetchRequest.resultType == NSManagedObjectResultType) {
                
                // build array of non-faulted objects
                
                NSMutableArray *managedObjects = [[NSMutableArray alloc] init];
                
                for (NSManagedObjectID *objectID in managedObjectIDs) {
                    
                    NSManagedObject *managedObject = [context objectWithID:objectID];
                    
                    [managedObjects addObject:managedObject];
                }
                
                results = [NSArray arrayWithArray:managedObjects];
            }
        }
        
        userInfo = @{NOIncrementalStoreRequestKey: request,
                     NOIncrementalStoreResultsKey : coreDataResults};
        
    }
    
    // post notification
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOIncrementalStoreFinishedFetchRequestNotification
                                                        object:self
                                                      userInfo:userInfo];
}];

return [self cachedResultsForFetchRequest:request
                                  context:context
                                    error:error];
}

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error
{
    
    
    return nil;
}

@end

@implementation NOIncrementalStore (Cache)

-(NSArray *)cachedResultsForFetchRequest:(NSFetchRequest *)fetchRequest
                                 context:(NSManagedObjectContext *)context
                                   error:(NSError *__autoreleasing *)error
{
    // Immediately return cached values
    
    NSManagedObjectContext *cacheContext = self.cachedStore.context;
    
    NSArray *results;
    
    __block NSArray *cachedResults;
    
    NSFetchRequest *cacheFetchRequest = fetchRequest.copy;
    
    // forward fetch to cache
    
    if (fetchRequest.resultType == NSCountResultType ||
        fetchRequest.resultType == NSDictionaryResultType) {
        
        [cacheContext performBlockAndWait:^{
            
            cachedResults = [cacheContext executeFetchRequest:cacheFetchRequest
                                                        error:error];
        }];
        
        return cachedResults;
    }
    
    // ManagedObjectID & faults
    
    if (fetchRequest.resultType == NSManagedObjectResultType ||
        fetchRequest.resultType == NSManagedObjectIDResultType) {
        
        // fetch resourceID from cache
        
        cacheFetchRequest.resultType = NSManagedObjectResultType;
        
        NSString *resourceIDKey = [NSClassFromString(fetchRequest.entity.managedObjectClassName) resourceIDKey];
        
        cacheFetchRequest.propertiesToFetch = @[resourceIDKey];
        
        [cacheContext performBlockAndWait:^{
            
            cachedResults = [cacheContext executeFetchRequest:cacheFetchRequest
                                                        error:error];
        }];
        
        // error
        
        if (!cachedResults) {
            
            return nil;
        }
        
        // build array of object ids
        
        NSMutableArray *managedObjectIDs = [NSMutableArray arrayWithCapacity:cachedResults.count];
        
        for (NSManagedObject *cachedManagedObject in cachedResults) {
            
            NSNumber *resourceID = [cachedManagedObject valueForKey:resourceIDKey];
            
            NSManagedObjectID *managedObjectID = [self newObjectIDForEntity:fetchRequest.entity
                                                            referenceObject:resourceID];
            
            [managedObjectIDs addObject:managedObjectID];
        }
        
        // object ID result type
        
        if (fetchRequest.resultType == NSManagedObjectIDResultType) {
            
            results = [NSArray arrayWithArray:managedObjectIDs];
        }
        
        // managed object result. return non-faulted NSManagedObject (only resource ID).
        
        if (fetchRequest.resultType == NSManagedObjectResultType) {
            
            // build array of non-faulted objects
            
            NSMutableArray *managedObjects = [[NSMutableArray alloc] init];
            
            for (NSManagedObjectID *objectID in managedObjectIDs) {
                
                NSManagedObject *managedObject = [context objectWithID:objectID];
                
                [managedObjects addObject:managedObject];
            }
            
            results = [NSArray arrayWithArray:managedObjects];
        }
    }
    
    return results;
}

-(NSDictionary *)cachedNewValuesForObjectWithID:(NSManagedObjectID *)objectID
                                    withContext:(NSManagedObjectContext *)context
                                          error:(NSError *__autoreleasing *)error
{
    // find resource with resource ID...
    
    NSNumber *resourceID = [self referenceObjectForObjectID:objectID];
    
    NSFetchRequest *cachedRequest = [NSFetchRequest fetchRequestWithEntityName:objectID.entity.name];
    
    cachedRequest.fetchLimit = 1;
    
    // resourceID key
    
    NSString *resourceIDKey = [NSClassFromString(objectID.entity.managedObjectClassName) resourceIDKey];
    
    cachedRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", resourceIDKey, resourceID];
    
    // prefetch all attributes and to-one relationships
    
    NSMutableArray *propertiesToFetch = [[NSMutableArray alloc] init];
    
    for (NSString *attributeName in objectID.entity.attributesByName) {
        
        [propertiesToFetch addObject:attributeName];
    }
    
    for (NSString *relationshipName in objectID.entity.relationshipsByName) {
        
        NSRelationshipDescription *relationship = objectID.entity.relationshipsByName[relationshipName];
        
        // only to-one relationships
        
        if (!relationship.isToMany) {
            
            [propertiesToFetch addObject:relationshipName];
        }
    }
    
    cachedRequest.propertiesToFetch = [NSArray arrayWithArray:propertiesToFetch];
    
    NSManagedObjectContext *cachedContext = self.cachedStore.context;
    
    __block NSArray *cachedResults;
    
    [cachedContext performBlockAndWait:^{
        
        cachedResults = [cachedContext executeFetchRequest:cachedRequest
                                                     error:error];
    }];
    
    if (!cachedResults) {
        
        return nil;
    }
    
    NSManagedObject *cachedResource = cachedResults.firstObject;
    
    if (!cachedResource) {
        
        return nil;
    }
    
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    
    for (NSString *propertyName in propertiesToFetch) {
        
        // one of these will be nil
        
        NSAttributeDescription *attribute = cachedResource.entity.attributesByName[propertyName];
        
        NSRelationshipDescription *relationship = cachedResource.entity.relationshipsByName[propertyName];
        
        if (!attribute && !relationship) {
            
            [NSException raise:NSInternalInconsistencyException
                        format:@"Object ID's entity doesnt match the entity used by the cache"];
        }
        
        if (attribute) {
            
            id value = [cachedResource valueForKey:propertyName];
            
            if (value) {
                
                values[propertyName] = value;
            }
        }
        
        // only to-one relationship
        
        if (relationship) {
            
            NSManagedObject *destinationManagedObject = [cachedResource valueForKey:propertyName];
            
            id value;
            
            // create an object id
            
            if (destinationManagedObject) {
                
                NSString *resourceIDKey = [NSClassFromString(cachedResource.entity.managedObjectClassName) resourceIDKey];
                
                NSNumber *resourceID = [destinationManagedObject valueForKey:resourceIDKey];
                
                value = [self newObjectIDForEntity:relationship.destinationEntity
                                   referenceObject:resourceID];
            }
            
            else {
                
                value = [NSNull null];
            }
            
            values[propertyName] = value;
            
        }
    }
    
    return values;
}

-(NSArray *)cachedNewValueForRelationship:(NSRelationshipDescription *)relationship
                          forObjectWithID:(NSManagedObjectID *)objectID
                              withContext:(NSManagedObjectContext *)context
                                    error:(NSError *__autoreleasing *)error
{
    // find resource with resource ID...
    
    NSNumber *resourceID = [self referenceObjectForObjectID:objectID];
    
    NSFetchRequest *cachedRequest = [NSFetchRequest fetchRequestWithEntityName:objectID.entity.name];
    
    cachedRequest.fetchLimit = 1;
    
    cachedRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", resourceID];
    
    cachedRequest.propertiesToFetch = @[relationship.name];
    
    NSManagedObjectContext *cachedContext = self.cachedStore.context;
    
    __block NSArray *cachedResults;
    
    [cachedContext performBlockAndWait:^{
        
        cachedResults = [cachedContext executeFetchRequest:cachedRequest
                                                     error:error];
    }];
    
    if (!cachedResults) {
        
        return nil;
    }
    
    NSManagedObject *cachedResource = cachedResults.firstObject;
    
    if (!cachedResource) {
        
        return nil;
    }
    
    NSArray *value;
    
    // to-many relationship
    
    if (relationship.isToMany) {
        
        NSMutableArray *objectIDs = [[NSMutableArray alloc] init];
        
        NSSet *set = [cachedResource valueForKey:relationship.name];
        
        for (NSManagedObject *cachedDestinationObject in set) {
            
            // create an object id
            
            NSString *resourceIDKey = [NSClassFromString(cachedResource.entity.managedObjectClassName) resourceIDKey];
            
            NSNumber *resourceID = [cachedDestinationObject valueForKey:resourceIDKey];
            
            NSManagedObjectID *objectID = [self newObjectIDForEntity:relationship.destinationEntity
                                                     referenceObject:resourceID];
            
            
            [objectIDs addObject:objectID];
        }
        
        value = [NSArray arrayWithArray:objectIDs];
    }
    
    return value;
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

@implementation NOIncrementalStore (CommonErrors)

-(NSError *)invalidServerResponseError
{
    
    NSString *description = NSLocalizedString(@"The server returned a invalid response",
                                              @"The server returned a invalid response");
    
    NSError *error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                         code:NOAPIInvalidServerResponseErrorCode
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
                                    code:NOAPIBadRequestErrorCode
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
                                    code:NOAPIServerInternalErrorCode
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
                                    code:NOAPIUnauthorizedErrorCode
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
                                    code:NOAPINotFoundErrorCode
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

@implementation NOIncrementalStore (API)

-(NSURLSessionDataTask *)searchForResource:(NSString *)resourceName
                            withParameters:(NSDictionary *)parameters
                                completion:(void (^)(NSError *, NSArray *))completionBlock
{
    if (!self.searchPath) {
        
        [NSException raise:NSInternalInconsistencyException
                    format:@"searchPath must be set to a valid value"];
    }
    
    // Build URL
    
    Class entityClass = [self entityClassWithResourceName:resourceName];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *searchURL = [self.serverURL URLByAppendingPathComponent:self.searchPath];
    
    searchURL = [searchURL URLByAppendingPathComponent:resourcePath];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:searchURL];
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [urlRequest addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    // add JSON data
    
    if (parameters) {
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                           options:self.jsonWritingOption
                                                             error:nil];
        if (!jsonData) {
            
            [NSException raise:NSInvalidArgumentException
                        format:@"Invalid parameters NSDictionary argument. Not valid JSON."];
            
            return nil;
        }
        
        urlRequest.HTTPBody = jsonData;
        
    }
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
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
                                                              code:NOAPIForbiddenErrorCode
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

@end

#pragma mark - NOIncrementalStore

@interface NOIncrementalStore ()

@property NSString *sessionEntityName;

@property NSString *userEntityName;

@property NSString *clientEntityName;

@property NSString *loginPath;

@property NSString *searchPath;

@property NSURLSession *urlSession;

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
    
    if (!self.model || !self.sessionEntityName || !self.userEntityName || !self.clientEntityName) {
        
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

#pragma mark - Faulting

-(NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID
                                        withContext:(NSManagedObjectContext *)context
                                              error:(NSError *__autoreleasing *)error
{
    // get reference object
    
    NSNumber *resourceID = [self referenceObjectForObjectID:objectID];
    
    if (!resourceID) {
        
        return nil;
    }
    
    // immediately return cached values
    
    NSDictionary *values = [self cachedNewValuesForObjectWithID:objectID
                                                    withContext:context
                                                          error:error];
    
    if (!values) {
        
        return nil;
    }
    
    NSIncrementalStoreNode *storeNode = [[NSIncrementalStoreNode alloc] initWithObjectID:objectID
                                                                              withValues:values
                                                                                 version:0];
    
    // download from server
    
    [self getCachedResource:objectID.entity.name resourceID:resourceID.integerValue URLSession:self.urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
        
        NSDictionary *userInfo;
        
        if (error) {
            
            // forward error
            
            userInfo = @{NOIncrementalStoreErrorKey: error,
                         NOIncrementalStoreObjectIDKey: objectID};
            
        }
        
        else {
            
            // update context with new values
            
            __block NSDictionary *newValues;
            
            [context performBlockAndWait:^{
                
                newValues = [self cachedNewValuesForObjectWithID:objectID
                                                     withContext:context
                                                           error:nil];
                
                [storeNode updateWithValues:newValues
                                    version:0];
                
            }];
            
            userInfo = @{NOIncrementalStoreObjectIDKey: objectID,
                         NOIncrementalStoreNewValuesKey: newValues};
        }
        
        // post notification
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOIncrementalStoreDidGetNewValuesNotification
                                                            object:self
                                                          userInfo:userInfo];
        
    }];
    
    return storeNode;
}

-(id)newValueForRelationship:(NSRelationshipDescription *)relationship
             forObjectWithID:(NSManagedObjectID *)objectID
                 withContext:(NSManagedObjectContext *)context
                       error:(NSError *__autoreleasing *)error
{
    // get reference object
    
    NSNumber *resourceID = [self referenceObjectForObjectID:objectID];
    
    if (!resourceID) {
        
        return nil;
    }
    
    // immediately return cached values
    
    NSArray *values = [self cachedNewValueForRelationship:relationship
                                          forObjectWithID:objectID
                                              withContext:context
                                                    error:error];
    
    // not going to fetch to-many from server becuase that was already called in -newValues...
    
    return values;
}

-(NSArray *)obtainPermanentIDsForObjects:(NSArray *)array
                                   error:(NSError *__autoreleasing *)error
{
    NSMutableArray *objectIDs = [NSMutableArray arrayWithCapacity:array.count];
    
    for (NSManagedObject *managedObject in array) {
        
        // get the resource ID
        
        NSString *resourceIDKey = [NSClassFromString(managedObject.entity.managedObjectClassName) resourceIDKey];
        
        NSNumber *resourceID = [managedObject valueForKey:resourceIDKey];
        
        NSManagedObjectID *objectID = [self newObjectIDForEntity:managedObject.entity
                                                 referenceObject:resourceID];
        
        [objectIDs addObject:objectID];
    }
    
    return objectIDs;
}

#pragma mark - Special JSON Requests

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
                                                                code:NOAPILoginFailedErrorCode
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
    
    Class entityClass = [self entityClassWithResourceName:resourceName];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *deleteResourceURL = [self.serverURL URLByAppendingPathComponent:resourcePath];
    
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
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
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

@end
