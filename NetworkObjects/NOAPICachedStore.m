//
//  NOAPICachedStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 11/16/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOAPICachedStore.h"
#import "NSManagedObject+CoreDataJSONCompatibility.h"

@interface NOAPICachedStore (Cache)

-(NSManagedObject<NOResourceKeysProtocol> *)resource:(NSString *)resourceName
                                              withID:(NSUInteger)resourceID;

@end

@implementation NOAPICachedStore

- (id)init
{
    self = [super init];
    if (self) {
        
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
    }
    return self;
}

#pragma mark - Requests

-(void)getResource:(NSString *)resourceName
        resourceID:(NSUInteger)resourceID
        completion:(void (^)(NSError *, NSManagedObject<NOResourceKeysProtocol> *))completionBlock
{
    [self.api getResource:resourceName withID:resourceID completion:^(NSError *error, NSDictionary *resourceDict) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        // update cache...
        
        NSManagedObject<NOResourceKeysProtocol> *resource = [self resource:resourceName
                                                                    withID:resourceID];
        
        // set values
        
        NSEntityDescription *entity = self.api.model.entitiesByName[resourceName];
        
        for (NSString *attributeName in entity.attributesByName) {
            
            for (NSString *key in resourceDict) {
                
                // found matching key (will only run once because dictionaries dont have duplicates)
                if ([key isEqualToString:attributeName]) {
                    
                    id value = [resourceDict valueForKey:key];
                    
                    [resource setJSONCompatibleValue:value
                                        forAttribute:attributeName];
                }
            }
        }
        
        for (NSString *relationshipName in entity.relationshipsByName) {
            
            NSRelationshipDescription *relationship = entity.relationshipsByName[relationshipName];
            
            
            for (NSString *key in resourceDict) {
                
                // found matching key (will only run once because dictionaries dont have duplicates)
                if ([key isEqualToString:relationshipName]) {
                    
                    // to-one relationship
                    if (!relationship.isToMany) {
                        
                        // get the object IDs
                        
                        
                    }
                    
                    // to-many relationship
                    else {
                        
                        
                        
                    }
                }
            }
        }
        
        
        completionBlock(nil, resource);
    }];
}

-(void)createResource:(NSString *)resourceName
        initialValues:(NSDictionary *)initialValues
           completion:(void (^)(NSError *, NSManagedObject<NOResourceKeysProtocol> *))completionBlock
{
    
    
}


@end

@implementation NOAPICachedStore (Cache)

-(NSManagedObject<NOResourceKeysProtocol> *)resource:(NSString *)resourceName
                                              withID:(NSUInteger)resourceID;
{
    // look for resource in cache
    
    __block NSManagedObject<NOResourceKeysProtocol> *resource;
    
    [self.context performBlockAndWait:^{
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:resourceName];
        
        // get entity
        NSEntityDescription *entity = self.api.model.entitiesByName[resourceName];
        
        Class entityClass = NSClassFromString(entity.managedObjectClassName);
        
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %d", [entityClass resourceIDKey], resourceID];
        
        NSError *error;
        
        NSArray *results = [self.context executeFetchRequest:fetchRequest
                                                       error:&error];
        
        if (error) {
            
            [NSException raise:@"Error executing NSFetchRequest"
                        format:@"%@", error.localizedDescription];
            
            return;
        }
        
        resource = results.firstObject;
        
        // create new object if none exists
        if (!resource) {
            
            resource = [NSEntityDescription insertNewObjectForEntityForName:resourceName
                                                     inManagedObjectContext:self.context];
        }
    }];
    
    return resource;
}

@end