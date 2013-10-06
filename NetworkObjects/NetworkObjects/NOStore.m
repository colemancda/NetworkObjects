//
//  NOStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/2/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOStore.h"
#import "NOResourceProtocol.h"

@implementation NOStore

@synthesize lastIDsURL = _lastIDsURL;

-(id)initWithManagedObjectModel:(NSManagedObjectModel *)model
                     lastIDsURL:(NSURL *)lastIDsURL;
{
    self = [super init];
    if (self) {
        
        // load model
        if (!model) {
            model = [NSManagedObjectModel mergedModelFromBundles:nil];
        }
        
        // create context
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        _context.undoManager = nil;
        
        // create a creation queue per nsmanagedobject subclass that conforms to NOResourceProtocol
        
        NSMutableDictionary *creationQueuesDict = [[NSMutableDictionary alloc] init];
        
        for (NSEntityDescription *entityDescription in model.entities) {
            
            Class entityClass = NSClassFromString(entityDescription.managedObjectClassName);
            
            if ([entityClass conformsToProtocol:@protocol(NOResourceProtocol)]) {
                
                NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
                operationQueue.maxConcurrentOperationCount = 1;
                
                // add to mutable dict
                [creationQueuesDict setObject:operationQueue
                                       forKey:entityDescription.name];
            }
        }
        
        _createResourcesQueues = [NSDictionary dictionaryWithDictionary:creationQueuesDict];
        
        _lastResourceIDs = [[NSMutableDictionary alloc] init];
        
        // load previously saved last resourceIDs
        if (lastIDsURL) {
            
            NSDictionary *savedLastIDs = [NSDictionary dictionaryWithContentsOfURL:lastIDsURL];
            
            if (!savedLastIDs) {
                
                NSLog(@"Could not open lastIDs");
            }
            else {
                
                [_lastResourceIDs addEntriesFromDictionary:savedLastIDs];
                
                _lastIDsURL = lastIDsURL;
            }
        }
    }
    return self;
}

-(id)init
{
    self = [self initWithManagedObjectModel:nil
                                 lastIDsURL:nil];
    return self;
}

#pragma mark

-(BOOL)save
{
    // save lastIDs first...
    
    NSDictionary *lastIDsBackup;
    
    if (_lastIDsURL) {
        
        // store backup of lastIDs in case there's an error in saving the context
        lastIDsBackup = [NSDictionary dictionaryWithContentsOfURL:_lastIDsURL];
        
        // the URL is invalid
        if (!lastIDsBackup) {
            return NO;
        }
        
        BOOL savedLastIDs = [_lastResourceIDs writeToURL:_lastIDsURL
                                              atomically:YES];
        
        if (!savedLastIDs) {
            return NO;
        }
    }
    
    // save context
    __block BOOL savedContext;
    [_context performBlockAndWait:^{
        
        NSError *saveError;
        savedContext = [_context save:&saveError];
        
        if (!savedContext) {
            
            NSLog(@"Could not save Core Data context of %@. %@", self, saveError.localizedDescription);
        }
    }];
    
    if (!savedContext) {
        
        // restore saved lastIDS
        BOOL restoreLastIDs = [lastIDsBackup writeToURL:_lastIDsURL
                                             atomically:YES];
        
        if (!restoreLastIDs) {
            
            NSLog(@"Could not restore lastIDs file to value before failed context save operation!");
            
        }
        
        return NO;
    }
    
    return YES;
}

#pragma mark - Manipulate Resources

-(NSNumber *)numberOfInstancesOfResourceWithEntityDescription:(NSEntityDescription *)entityDescription
{
    __block NSNumber *count;
    
    [_context performBlockAndWait:^{
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityDescription.name];
        fetchRequest.resultType = NSCountResultType;
        
        NSError *fetchError;
        NSArray *result = [_context executeFetchRequest:fetchRequest
                                                  error:&fetchError];
        
        if (!result) {
            
            [NSException raise:@"Fetch Request Failed"
                        format:@"%@", fetchError.localizedDescription];
            return;
        }
        
        count = result[0];
        
    }];
    
    return count;
}

-(id<NOResourceProtocol>)resourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                            resourceID:(NSUInteger)resourceID
{
    // get the key of the resourceID attribute
    Class entityClass = NSClassFromString(entityDescription.managedObjectClassName);
    
    NSString *resourceIDKey = [entityClass resourceIDKey];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityDescription.name];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%@ == %lu", resourceIDKey, (unsigned long)resourceID];
    
    __block id<NOResourceProtocol> resource;
    
    [_context performBlockAndWait:^{
        
        NSError *fetchError;
        NSArray *result = [_context executeFetchRequest:fetchRequest
                                                  error:&fetchError];
        
        if (!result) {
            
            [NSException raise:@"Fetch Request Failed"
                        format:@"%@", fetchError.localizedDescription];
            return;
        }
        
        if (result.count > 1) {
            
            NSLog(@"More than one %@ exist with the same resourceID", entityDescription.name);
            
        }
        
        // nothing was found
        if (!result.count) {
            return;
        }
        
        resource = result[0];
    }];
    
    return resource;
}

-(BOOL)deleteResourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                resourceID:(NSUInteger)resourceID
{
    id<NOResourceProtocol> resource = [self resourceWithEntityDescription:entityDescription
                                                               resourceID:resourceID];
    
    if (!resource) {
        return NO;
    }
    
    // no need to wait for block to end since we dont return a value
    [_context performBlock:^{
        
        [_context deleteObject:resource];
    }];
    
    return YES;
}

-(NSNumber *)newResourceWithEntityDescription:(NSEntityDescription *)entityDescription
{
    // use the operationQueue for this resource
    
    NSOperationQueue *operationQueue = _createResourcesQueues[entityDescription.name];
    
    NSNumber *lastID = _lastResourceIDs[entityDescription.name];
    
    __block NSNumber *resourceID;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        [_context performBlockAndWait:^{
            
            // get resourceID attribute
            Class entityClass = NSClassFromString(entityDescription.managedObjectClassName);
            
            NSString *resourceIDKey = [entityClass resourceIDKey];
            
            // create new resource
            NSManagedObject<NOResourceProtocol> *newResource = [NSEntityDescription insertNewObjectForEntityForName:entityDescription.name
                                          inManagedObjectContext:_context];
            
            // set new resourceID
            
            if (!lastID) {
                resourceID = @0;
            }
            else {
                resourceID = [NSNumber numberWithInteger:lastID.integerValue + 1];
            }
            
            [newResource setValue:resourceID
                           forKey:resourceIDKey];
            
            // set as last ID
            [_lastResourceIDs setObject:resourceID
                                 forKey:entityDescription.name];
            
        }];
    }];
    
    [operationQueue addOperations:@[blockOperation]
                waitUntilFinished:YES];
    
    return resourceID;
}

@end
