//
//  NOCacheOperation+Cache.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 4/13/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOCacheOperation+Cache.h"

static NSPredicate *predicate;

@implementation NOCacheOperation (Cache)

-(NSManagedObject<NOResourceKeysProtocol> *)findResource:(NSString *)resourceName
                                          withResourceID:(NSNumber *)resourceID
                                                 context:(NSManagedObjectContext *__autoreleasing *)context
                                  returnsObjectsAsFaults:(BOOL)returnsObjectsAsFaults
{
    // look for resource in cache
    
    __block NSManagedObject<NOResourceKeysProtocol> *resource;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:resourceName];
    
    fetchRequest.fetchLimit = 1;
    
    fetchRequest.returnsObjectsAsFaults = returnsObjectsAsFaults;
    
    // get entity
    NSEntityDescription *entity = self.API.model.entitiesByName[resourceName];
    
    Class entityClass = NSClassFromString(entity.managedObjectClassName);
    
    NSString *resourceIDKey = [entityClass resourceIDKey];
    
    // lazily create global predicate
    
    if (!predicate) {
        
        predicate = [NSPredicate predicateWithFormat:@"$RESOURCEIDKEY == $RESOURCEID"];
        
    }
    
    NSDictionary *variables = @{@"RESOURCEIDKEY": resourceIDKey,
                                @"RESOURCEID": resourceID};
    
    fetchRequest.predicate = [predicate predicateWithSubstitutionVariables:variables];
    
    // fetch on background thread
    
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    privateContext.persistentStoreCoordinator = self.context.persistentStoreCoordinator;
    
    privateContext.undoManager = nil;
    
    *context = privateContext;
    
    [privateContext performBlockAndWait:^{
        
        NSError *error;
        
        NSArray *results = [privateContext executeFetchRequest:fetchRequest
                                                         error:&error];
        
        if (error) {
            
            [NSException raise:@"Error executing NSFetchRequest"
                        format:@"%@", error.localizedDescription];
            
            return;
        }
        
        resource = results.firstObject;
        
    }];
    
    return resource;
}

-(NSManagedObject<NOResourceKeysProtocol> *)findOrCreateResource:(NSString *)resourceName
                                                  withResourceID:(NSNumber *)resourceID
                                                         context:(NSManagedObjectContext *__autoreleasing *)context
{
    __block NSManagedObject <NOResourceKeysProtocol> *resource = [self findResource:resourceName
                                                                     withResourceID:resourceID
                                                                            context:context
                                                             returnsObjectsAsFaults:NO];
    
    NSManagedObjectContext *privateContext = *context;
    
    if (!resource) {
        
        [privateContext performBlockAndWait:^{
            
            resource = [NSEntityDescription insertNewObjectForEntityForName:resourceName
                                                     inManagedObjectContext:self.context];
            
            [resource setValue:resourceID
                        forKey:[NSClassFromString(resource.entity.managedObjectClassName) resourceIDKey]];
            
        }];
    }
    
    return resource;
}

@end
