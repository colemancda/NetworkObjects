//
//  NOCacheGetOperation.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 4/13/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOCacheGetOperation.h"
#import "NOAPI.h"
#import "NOCacheOperation+Cache.h"

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

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Operation

-(void)start
{
    self.isExecuting = YES;
    
    self.dataTask = [self.API getResource:self.resourceName withID:self.resourceID.integerValue URLSession:self.URLSession completion:^(NSError *error, NSDictionary *resourceDict) {
        
        if (self.isCancelled) {
            
            self.isExecuting = NO;
            
            self.isFinished = YES;
            
            return;
        }
        
        if (error) {
            
            self.error = error;
            
            // not found, delete object from our cache
            
            if (error.code == NOAPINotFoundErrorCode) {
                
                NSManagedObjectContext *context;
                
                NSManagedObject<NOResourceKeysProtocol> *resource = [self findResource:self.resourceName
                                                                        withResourceID:self.resourceID
                                                                               context:&context];
                
                if (resource) {
                    
                    [context performBlockAndWait:^{
                        
                        [context deleteObject:resource];
                        
                        NSError *error;
                        
                        [context save:&error];
                        
                        if (error) {
                            
                            self.error = error;
                        }
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self
                                                                 selector:@selector(contextDidSave:)
                                                                     name:NSManagedObjectContextDidSaveNotification
                                                                   object:context];
                        
                    }];
                }
                
                self.isExecuting = NO;
                
                self.isFinished = YES;
                
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

#pragma mark - Notifications

-(void)contextDidSave:(NSNotification *)notification
{
    [self.context performBlock:^{
       
        [self.context mergeChangesFromContextDidSaveNotification:notification];
        
    }];
}

@end
