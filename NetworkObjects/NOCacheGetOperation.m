//
//  NOCacheGetOperation.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 4/13/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOCacheGetOperation.h"

@implementation NOCacheGetOperation

-(void)start
{
    self.dataTask = [self.API getResource:resourceName withID:resourceID URLSession:urlSession completion:^(NSError *error, NSDictionary *resourceDict) {
        
        if (error) {
            
            // not found, delete object from our cache
            
            if (error.code == NOAPINotFoundErrorCode) {
                
                // get resourceID
                
                Class entityClass = NSClassFromString([self.context.persistentStoreCoordinator.managedObjectModel.entitiesByName[resourceName] managedObjectClassName]);
                
                NSString *resourceIDKey = [entityClass resourceIDKey];
                
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:resourceName];
                
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %lu", resourceIDKey, resourceID];
                
                [_context performBlockAndWait:^{
                    
                    NSError *fetchError;
                    
                    NSArray *results = [_context executeFetchRequest:fetchRequest
                                                               error:&fetchError];
                    
                    NSManagedObject *resource = results.firstObject;
                    
                    // delete resouce of there is one in cache
                    
                    if (resource) {
                        
                        [_context deleteObject:resource];
                        
                        // optionally process pending changes
                        
                        if (self.shouldProcessPendingChanges) {
                            
                            [self.context processPendingChanges];
                        }
                    }
                }];
            }
            
            completionBlock(error, nil);
            
            return;
        }
        
        NSManagedObject<NOResourceKeysProtocol> *resource = [self setJSONObject:resourceDict
                                                                    forResource:resourceName
                                                                         withID:resourceID];
        
        // set date cached
        
        [self cachedResource:resourceName
              withResourceID:resourceID];
        
        // optionally process changes
        
        if (self.shouldProcessPendingChanges) {
            
            [self.context performBlock:^{
                
                [self.context processPendingChanges];
            }];
        }
        
        completionBlock(nil, resource);
    }];
    
}

@end
