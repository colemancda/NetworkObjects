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
    
    assert(self.api);
    
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
    
    
}

-(id)newValueForRelationship:(NSRelationshipDescription *)relationship
             forObjectWithID:(NSManagedObjectID *)objectID
                 withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error
{
    
    
}

#pragma mark

-(id)executeFetchRequest:(NSFetchRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error
{
    // validate that the entity conforms to NOResourceKeysProtocol
    
    if (![self fetchRequestEntityIsResource:request]) {
        
        
        
        NSError *error = [NSError errorWithDomain:<#(NSString *)#> code:<#(NSInteger)#> userInfo:<#(NSDictionary *)#>]
    }
    
}

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error
{
    
    
}

#pragma mark

-(BOOL)fetchRequestEntityIsResource:(NSFetchRequest *)request
{
    Class entityClass = NSClassFromString(request.en.managedObjectClassName);
    
    return [entityClass conformsToProtocol:@protocol(NOResourceKeysProtocol)];
}

@end
