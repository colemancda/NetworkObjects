//
//  NOIncrementalStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 3/28/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOIncrementalStore.h"
#import "NOAPICachedStore.h"

// Store Type

NSString *const NOIncrementalStoreType = @"NOIncrementalStoreType";

// Options

NSString *const NOIncrementalStoreCachedStoreOption = @"NOIncrementalStoreCachedStoreOption";

NSString *const NOIncrementalStoreURLSessionOption = @"NOIncrementalStoreURLSessionOption";

// Notifications

NSString *const NOIncrementalStoreFinishedFetchRequestNotification = @"NOIncrementalStoreFinishedFetchRequestNotification";

NSString *const NOIncrementalStoreDidGetNewValuesNotification = @"NOIncrementalStoreDidGetNewValuesNotification";

NSString *const NOIncrementalStoreRequestKey = @"NOIncrementalStoreRequestKey";

NSString *const NOIncrementalStoreErrorKey = @"NOIncrementalStoreErrorKey";

NSString *const NOIncrementalStoreResultsKey = @"NOIncrementalStoreResultsKey";

NSString *const NOIncrementalStoreNewValuesKey = @"NOIncrementalStoreNewValuesKey";

NSString *const NOIncrementalStoreObjectIDKey = @"NOIncrementalStoreObjectIDKey";

@interface NOIncrementalStore (Requests)

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error;

-(id)executeFetchRequest:(NSFetchRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error;

@end

@interface NOIncrementalStore (Cache)


-(NSArray *)cachedResultsForFetchRequest:(NSFetchRequest *)fetchRequest
                                 context:(NSManagedObjectContext *)context
                                   error:(NSError **)error;

-(NSDictionary *)cachedNewValuesForObjectWithID:(NSManagedObjectID *)objectID
                                    withContext:(NSManagedObjectContext *)context
                                          error:(NSError **)error;

-(NSArray *)cachedNewValueForRelationship:(NSRelationshipDescription *)relationship
                          forObjectWithID:(NSManagedObjectID *)objectID
                              withContext:(NSManagedObjectContext *)context
                                    error:(NSError *__autoreleasing *)error;



@end

@interface NOIncrementalStore ()

@property NOAPICachedStore *cachedStore;

@end

@implementation NOIncrementalStore

#pragma mark - Initialization

+(void)initialize
{
    if (self == [NOIncrementalStore self]) {
        
        [NSPersistentStoreCoordinator registerStoreClass:self
                                            forStoreType:NOIncrementalStoreType];
    }
}

+(NSString *)storeType
{
    return NOIncrementalStoreType;
}

-(id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root
                      configurationName:(NSString *)name
                                    URL:(NSURL *)url
                                options:(NSDictionary *)options
{
    self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options];
    
    if (self) {
        
        self.cachedStore = options[NOIncrementalStoreCachedStoreOption];
        
        // notification queue
        
        _notificationQueue = [[NSOperationQueue alloc] init];
        
        _notificationQueue.name = @"NOIncrementalStore Notification Queue";
        
    }
    
    return self;
}

-(BOOL)loadMetadata:(NSError *__autoreleasing *)error
{
    self.metadata = @{NSStoreTypeKey: NOIncrementalStoreType,
                      NSStoreUUIDKey : [[NSUUID UUID] UUIDString]};
    
    return YES;
}

#pragma mark - Request

-(id)executeRequest:(NSPersistentStoreRequest *)request
        withContext:(NSManagedObjectContext *)context
              error:(NSError *__autoreleasing *)error
{
    // check for API cached store
    if (!self.cachedStore) {
        
        [NSException raise:NSInvalidArgumentException
                    format:@"Must specify a NOAPICachedStore instance for the NOIncrementalStoreCachedStoreOption in the initializer's options dictionary"];
        
        return nil;
    }
    
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
    
    [self.cachedStore getCachedResource:objectID.entity.name resourceID:resourceID.integerValue URLSession:self.urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
        
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
        
        [_notificationQueue addOperationWithBlock:^{
           
            [[NSNotificationCenter defaultCenter] postNotificationName:NOIncrementalStoreDidGetNewValuesNotification
                                                                object:self
                                                              userInfo:userInfo];
            
        }];
        
    }];
    
    return storeNode;
}

-(id)newValueForRelationship:(NSRelationshipDescription *)relationship
             forObjectWithID:(NSManagedObjectID *)objectID
                 withContext:(NSManagedObjectContext *)context
                       error:(NSError *__autoreleasing *)error
{
    [NSException raise:NSInternalInconsistencyException
                format:@"This method should never get called becuase the relationships are not lazily loaded"];
    
    return nil;
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

@end

@implementation NOIncrementalStore (Requests)

-(id)executeFetchRequest:(NSFetchRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error
{
    NSFetchRequest *cacheRequest = request.copy;
    
    // comparison predicate, use search
    
    if ([request.predicate isKindOfClass:[NSComparisonPredicate class]]) {
        
        [self.cachedStore searchForCachedResourceWithFetchRequest:cacheRequest URLSession:self.urlSession completion:^(NSError *remoteError, NSArray *results) {
            
            // forward error
            
            NSDictionary *userInfo;
            
            if (remoteError) {
                
                userInfo = @{NOIncrementalStoreErrorKey: remoteError,
                             NOIncrementalStoreRequestKey: request};
                
            }
            
            else {
                
                NSArray *coreDataResults = [self cachedResultsForFetchRequest:cacheRequest
                                                                       context:context
                                                                         error:nil];
                
                userInfo = @{NOIncrementalStoreRequestKey: request,
                             NOIncrementalStoreResultsKey : coreDataResults};
                
            }
            
            // post notification

            [_notificationQueue addOperationWithBlock:^{
               
                [[NSNotificationCenter defaultCenter] postNotificationName:NOIncrementalStoreFinishedFetchRequestNotification
                                                                    object:self
                                                                  userInfo:userInfo];
                
            }];
            
        }];
    }
    
    else {
        
        [NSException raise:NSInvalidArgumentException
                    format:@"NOIncrementalStore only supports NSComparisonPredicate predicates for fetch requests"];
        
        return nil;
        
    }
    
    return [self cachedResultsForFetchRequest:cacheRequest
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
    
    // fetch resourceID from cache
    
    if (fetchRequest.resultType == NSManagedObjectResultType ||
        fetchRequest.resultType == NSManagedObjectIDResultType) {
        
        cacheFetchRequest.resultType = NSDictionaryResultType;
        
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
        
        for (NSDictionary *cachedDictionary in cachedResults) {
            
            NSNumber *resourceID = cachedDictionary[resourceIDKey];
            
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
    
    cachedRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", resourceID];
    
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
            
            if (!value) {
                
                value = [NSNull null];
            }
            
            values[propertyName] = value;
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
    
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    
    for (NSString *relationshipName in ) {
        <#statements#>
    }
    
}

@end
