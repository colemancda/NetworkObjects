//
//  NOAPIStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOAPIStore.h"
#import "NOResourceProtocol.h"
#import "NetworkObjectsConstants.h"
#import "NOAPI.h"

@implementation NOAPIStore (Errors)

-(NSError *)invalidPredicate
{
    NSString *description = NSLocalizedString(@"Invalid predicate",
                                              @"Invalid predicate");
    
    NSError *error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                         code:NOAPIStoreInvalidPredicateErrorCode
                                     userInfo:@{NSLocalizedDescriptionKey: description}];
    
    return error;
}

@end

@implementation NOAPIStore

+(void)initialize
{
    [NSPersistentStoreCoordinator registerStoreClass:[self class]
                                        forStoreType:[[self class] type]];
}

+(NSString *)type
{
    return NSStringFromClass([self class]);
}

-(BOOL)loadMetadata:(NSError *__autoreleasing *)error
{
    NSMutableDictionary *mutableMetadata = [NSMutableDictionary dictionary];
    [mutableMetadata setValue:[[NSProcessInfo processInfo] globallyUniqueString]
                       forKey:NSStoreUUIDKey];
    
    [mutableMetadata setValue:[[self class] type]
                       forKey:NSStoreTypeKey];
    
    [self setMetadata:mutableMetadata];
    
    return YES;
}

-(id)executeRequest:(NSPersistentStoreRequest *)request
        withContext:(NSManagedObjectContext *)context
              error:(NSError *__autoreleasing *)error
{
    // check that API is not null
    
    NSAssert(self.api, @"NOAPI property must not be nil");
    
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

-(NSArray *)obtainPermanentIDsForObjects:(NSArray *)array
                                   error:(NSError *__autoreleasing *)error
{
    NSMutableArray *objectIDs = [[NSMutableArray alloc] init];
    
    for (NSManagedObject<NOResourceKeysProtocol> *resource in array) {
        
        NSString *resourceIDKey = [[resource class] resourceIDKey];
        
        NSNumber *resourceID = [resource valueForKey:resourceIDKey];
        
        NSManagedObjectID *objectID = [self newObjectIDForEntity:resource.entity
                                                 referenceObject:resourceID];
        
        [objectIDs addObject:objectID];
    }
    
    return objectIDs;
}

-(NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID
                                        withContext:(NSManagedObjectContext *)context
                                              error:(NSError *__autoreleasing *)error
{
    
    return nil;
}

-(id)newValueForRelationship:(NSRelationshipDescription *)relationship
             forObjectWithID:(NSManagedObjectID *)objectID
                 withContext:(NSManagedObjectContext *)context
                       error:(NSError *__autoreleasing *)error
{
    
    return nil;
}

#pragma mark

-(id)executeFetchRequest:(NSFetchRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error
{
    NSAssert(request, @"NSFetchRequest must not be nil");
    
    // validate that the entity conforms to NOResourceKeysProtocol
    
    NSManagedObjectModel *model = self.persistentStoreCoordinator.managedObjectModel;
    
    // get entity
    NSEntityDescription *entity = model.entitiesByName[request.entityName];
    
    if (!entity) {
        
        if ([model.entities containsObject:request.entity]) {
            
            entity = request.entity;
        }
    }
    
    // entity is nil
    
    if (!entity) {
        
        [NSException raise:NSInternalInconsistencyException
                    format:@"NSFetchRequest doesn't specify a entity"];
    }
    
    // verify that it conforms to protocol
    
    Class entityClass = NSClassFromString(entity.managedObjectClassName);
    
    if (![entityClass conformsToProtocol:@protocol(NOResourceKeysProtocol)]) {
        
        [NSException raise:NSInvalidArgumentException
                    format:@"%@ does not conform to NOResourceProtocol", entity.name];
    }
    
    // incremental store is only capable of fetching single results...
    
    // must specify resourceID...
    
    NSString *resourceIDKey = [entityClass resourceIDKey];
    
    // parse predicate (only 'resourceID == x' is valid)
    
    NSString *desiredPredicatePrefix = [NSString stringWithFormat:@"%@ == ", resourceIDKey];
    
    NSString *predicate = request.predicate.description;
    
    NSRange range = [predicate rangeOfString:desiredPredicatePrefix];
    
    if (range.location == NSNotFound) {
        
        *error = [self invalidPredicate];
        
        return nil;
    }
    
    NSString *resourceIDString = [predicate substringFromIndex:range.location];
    
    if (!resourceIDString) {
        
        *error = [self invalidPredicate];
        
        return nil;
    }
    
    NSUInteger resourceID = resourceIDString.integerValue;
    
    __block NSDictionary *resourceDict;
    
    // GCD
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    [self.api getResource:entity.name withID:resourceID completion:^(NSError *error, NSDictionary *resource)
    {
        // Add a task to the group
        dispatch_group_async(group, queue, ^{
            // Some asynchronous work
            
            
        });
    }];
    
    // wait on the group to block the current thread.
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return nil;
}

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error
{
    
    return nil;
}



@end
