//
//  NOStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/2/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <NetworkObjects/NOResourceProtocol.h>

@interface NOStore : NSObject
{
    NSMutableDictionary *_lastResourceIDs;
    
    NSDictionary *_createResourcesQueues;
}

-(id)initWithManagedObjectModel:(NSManagedObjectModel *)model
                     lastIDsURL:(NSURL *)lastIDsURL;

@property (readonly) NSManagedObjectContext *context;

@property (readonly) NSDictionary *lastResourceIDs;

@property (readonly) NSURL *lastIDsURL;

-(BOOL)save;

#pragma mark - Resource Methods

// GET number of instances
-(NSNumber *)numberOfInstancesOfResourceWithEntityDescription:(NSEntityDescription *)entityDescription;

#pragma mark - Manage Resource Instances
// Cocoa methods to manage a object graph styled after REST but without the networking or authentication, useful for editing NetworkedObjects from the server app or for other internal use.

// e.g. you want to create a new resource but dont wanna write the glue code for assigning it a proper resource ID

-(NSManagedObject<NOResourceProtocol> *)newResourceWithEntityDescription:(NSEntityDescription *)entityDescription;

-(NSManagedObject<NOResourceProtocol> *)resourceWithEntityDescription:(NSEntityDescription *)entityDescription resourceID:(NSUInteger)resourceID;

-(void)deleteResource:(NSManagedObject<NOResourceProtocol> *)resource;

@end
