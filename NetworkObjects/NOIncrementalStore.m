//
//  NOIncrementalStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 3/28/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOIncrementalStore.h"
#import "NOAPICachedStore.h"

NSString *const NOIncrementalStoreCachedStoreOption = @"NOIncrementalStoreCachedStoreOption";

NSString *const NOIncrementalStoreType = @"NOIncrementalStoreType";

// Notifications

NSString *const NOIncrementalStoreFinishedFetchRequestNotification = @"NOIncrementalStoreFinishedFetchRequestNotification";

NSString *const NOIncrementalStoreDidGetNewValuesNotification = @"NOIncrementalStoreDidGetNewValuesNotification";

NSString *const NOIncrementalStoreRequestKey = @"NOIncrementalStoreRequestKey";

NSString *const NOIncrementalStoreErrorKey = @"NOIncrementalStoreErrorKey";

NSString *const NOIncrementalStoreResultsKey = @"NOIncrementalStoreResultsKey";

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

-(NSDictionary *)cachedNewValuesForResource:(NSString *)resourceName
                             withResourceID:(NSNumber *)resourceID
                                    context:(NSManagedObjectContext *)context
                                      error:(NSError **)error;

@end

@interface NOIncrementalStore (ManagedObjectID)

-(NSManagedObjectID *)objectIDForEntity:(NSEntityDescription *)entity
                        referenceObject:(id)data;

@end

@interface NOIncrementalStore ()

@property NSMutableDictionary *objectIDs;

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
    
    NSDictionary *values = [self cachedNewValuesForResource:objectID.entity.name
                                             withResourceID:resourceID
                                                    context:context
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
            
            NSDictionary *newValues = [self cachedNewValuesForResource:objectID.entity.name
                                                        withResourceID:resourceID
                                                               context:context
                                                                 error:&error];
            
            userInfo = @{NOIncrementalStoreObjectIDKey: objectID,
                         NOIncrementalStoreNewValuesKey: newValues};
        }
        
    }];
    
    return storeNode;
}

-(id)newValueForRelationship:(NSRelationshipDescription *)relationship
             forObjectWithID:(NSManagedObjectID *)objectID
                 withContext:(NSManagedObjectContext *)context
                       error:(NSError *__autoreleasing *)error
{
    
    return nil;
}

-(NSArray *)obtainPermanentIDsForObjects:(NSArray *)array
                                   error:(NSError *__autoreleasing *)error
{
    
    return nil;
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

@implementation NOIncrementalStore (ManagedObjectID)

-(NSManagedObjectID *)objectIDForEntity:(NSEntityDescription *)entity
                        referenceObject:(id)data
{
    // lazily initialize dictionary
    
    if (!self.objectIDs) {
        
        self.objectIDs = [[NSMutableDictionary alloc] init];
    }
    
    // key for object ID
    
    NSString *objectIDKey = [NSString stringWithFormat:@"%@.%@", entity.name, data];
    
    // try to get already created object ID
    
    NSManagedObjectID *objectID = self.objectIDs[objectIDKey];
    
    // create new and add to dictionary if it doesnt exist
    
    if (!objectID) {
        
        objectID = [self newObjectIDForEntity:entity referenceObject:data];
        
        self.objectIDs[objectIDKey] = objectID;
    }
    
    return objectID;
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
            
            NSManagedObjectID *managedObjectID = [self objectIDForEntity:fetchRequest.entity
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

-(NSDictionary *)cachedNewValuesForResource:(NSString *)resourceName
                             withResourceID:(NSNumber *)resourceID
                                    context:(NSManagedObjectContext *)context
                                      error:(NSError *__autoreleasing *)error
{
    // find resource with resource ID...
    
    NSFetchRequest *cachedRequest = [NSFetchRequest fetchRequestWithEntityName:resourceName];
    
    cachedRequest.fetchLimit = 1;
    
    cachedRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", resourceID];
    
    NSArray *results = [self cachedResultsForFetchRequest:cachedRequest
                                                  context:context
                                                    error:error];
    
    if (!results) {
        
        return nil;
    }
    
    NSManagedObject *cachedResource = results.firstObject;
    
    if (!cachedResource) {
        
        return nil;
    }
    
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    
    for (NSAttributeDescription *attribute in cachedResource.entity.attributesByName) {
        
        values[attribute.name] = [cachedResource valueForKey:attribute.name];
    }
    
    for (NSRelationshipDescription *relationship in cachedResource.entity.attributesByName) {
        
        // you are encouaraged to lazily fetch to-many relationships, but then we GET data from a NetworkObjects server, the info is already included, so in our case its better to include everything in -newValues...
        
        // to-one relationship
        
        if (!relationship.isToMany) {
            
            [self objectIDForEntity:[NSEntityDescription entityForName:resourceName inManagedObjectContext:context]
                    referenceObject:<#(id)#>];
        }
    }
    
}

@end
