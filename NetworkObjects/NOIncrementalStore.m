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

@interface NOIncrementalStore (Requests)

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error;

-(id)executeFetchRequest:(NSFetchRequest *)request
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
        
        [NSPersistentStoreCoordinator registerStoreClass:[NOIncrementalStore self]
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

-(NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID
                                        withContext:(NSManagedObjectContext *)context
                                              error:(NSError *__autoreleasing *)error
{
    
    
}

-(id)newValueForRelationship:(NSRelationshipDescription *)relationship
             forObjectWithID:(NSManagedObjectID *)objectID
                 withContext:(NSManagedObjectContext *)context
                       error:(NSError *__autoreleasing *)error
{
    
    
}

-(NSArray *)obtainPermanentIDsForObjects:(NSArray *)array
                                   error:(NSError *__autoreleasing *)error
{
    
    
}

@end

@implementation NOIncrementalStore (Requests)

-(id)executeFetchRequest:(NSFetchRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error
{
    NSFetchRequest *cacheRequest = request.copy;
    
    cacheRequest.entity = [NSEntityDescription entityForName:request.entityName
                                      inManagedObjectContext:self.cachedStore.context];
    
    // comparison predicate, use search
    if ([request.predicate isKindOfClass:[NSComparisonPredicate class]]) {
        
        [self.cachedStore searchForCachedResourceWithFetchRequest:cacheRequest URLSession:self.urlSession completion:^(NSError *error, NSArray *results) {
            
            // use notification center
            
        }];
    }
    
    // other fetch requests
    else {
        
        
        
    }
    
    // Immediately return cached values
    
    __block id results;
    
    [self.cachedStore.context performBlockAndWait:^{
       
        results = [self.cachedStore.context executeFetchRequest:request
                                                          error:error];
        
    }];
    
    return results;
}

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error
{
    
    
}

@end
