//
//  NOCacheGetOperation.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 4/13/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOCacheGetOperation.h"
#import "NOAPI.h"

@interface NSOperation ()

@property BOOL isReady;

@property BOOL isExecuting;

@property BOOL isFinished;

@end

@interface NOCacheOperation ()

@property NSURLSessionDataTask *dataTask;

@property NSError *error;

@end

@implementation NOCacheGetOperation

/*

-(void)start
{
    self.isExecuting = YES;
    
    self.dataTask = [self.API getResource:self.resourceName withID:self.resourceID URLSession:self.URLSession completion:^(NSError *error, NSDictionary *resourceDict) {
        
        if (self.isCancelled) {
            
            self.isExecuting = NO;
            
            self.isFinished = YES;
            
            return;
        }
        
        if (error) {
            
            self.error = error;
            
            // not found, delete object from our cache
            
            if (error.code == NOAPINotFoundErrorCode) {
                
                // get resourceID
                
                Class entityClass = NSClassFromString([self.context.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.resourceName] managedObjectClassName]);
                
                NSString *resourceIDKey = [entityClass resourceIDKey];
                
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.resourceName];
                
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %lu", resourceIDKey, self.resourceID];
                
                [self.context performBlock:^{
                    
                    NSError *fetchError;
                    
                    NSArray *results = [self.context executeFetchRequest:fetchRequest
                                                                   error:&fetchError];
                    
                    NSManagedObject *resource = results.firstObject;
                    
                    // delete resouce if there is one in cache
                    
                    if (resource) {
                        
                        [self.context deleteObject:resource];
                        
                        NSError *error;
                        
                        [self.context save:&error];
                        
                        if (error) {
                            
                            self.error = error;
                        }
                        
                    }
                    
                    self.isExecuting = NO;
                    
                    self.isFinished = YES;
                    
                }];
                
                return;
            }
            
            self.isExecuting = NO;
            
            self.isFinished = YES;
            
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

*/

@end
