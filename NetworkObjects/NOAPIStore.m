//
//  NOAPIStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOAPIStore.h"
#import "NOResourceProtocol.h"
#import "NOAPIStore+Errors.h"

@implementation NOAPIStore

NSString *const NOAPIStoreType = @"NOAPIStore";

+(void)initialize
{
    [NSPersistentStoreCoordinator registerStoreClass:[self class]
                                        forStoreType:[[self class] type]];
}

+(NSString *)type
{
    return NOAPIStoreType;
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
        
        *error = self.entityNotFoundError;
        
        return nil;
    }
    
    // verify that it conforms to protocol
    
    Class entityClass = NSClassFromString(entity.managedObjectClassName);
    
    if (![entityClass conformsToProtocol:@protocol(NOResourceKeysProtocol)]) {
        
        *error = self.entityNotResourceError;
        
        return nil;
    }
    
    // incremental store is only capable of fetching single results...
    
    // must specify resourceID...
    
    NSString *resourceIDKey = [entityClass resourceIDKey];
    
    
    
    return nil;
}

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error
{
    
    return nil;
}



@end
