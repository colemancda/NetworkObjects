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

/**
 This is the store class that holds the Core Data entities (called Resources) that conform to NOResourceProtocol. It creates, deletes and accesses Resources in a manner that is friendly to NOResourceProtocol. You MUST add a persistent store to the @c context property after initialization to properly use this class.
 */

@interface NOStore : NSObject
{
    /**
     A dictionary (protentially unarchived) that contains Resource IDs.
     */
    NSMutableDictionary *_lastResourceIDs;
    
    /**
     A dictionary that contains NSOperationQueues for that coordinated creation of resources so that they can be given valid Resource ID.
     */
    NSDictionary *_createResourcesQueues;
}

/**
 The recommended initializer to use for initializing a NOStore. Using -init is the same as the following code
 
 @code
 [[NOStore alloc] initWithManagedObjectModel:nil lastIDsURL:nil];
 @endcode
 
 @param model The NSManagedObjectModel to use with this store. Should contain entities that conform to NOResourceProtocol. Can be nil.
 
 @param lastIDsURL The URL to which the list of Resource IDs will be saved. Can be nil.
 
 @return A fully initialized NOStore instance.
 
 @see NSManagedObjectModel
 */

-(id)initWithManagedObjectModel:(NSManagedObjectModel *)model
                     lastIDsURL:(NSURL *)lastIDsURL;

@property (readonly) NSManagedObjectContext *context;

@property (readonly) NSDictionary *lastResourceIDs;

@property (readonly) NSURL *lastIDsURL;

/**
 Saves the NSManagedObjectContext @c context and @c lastResourceIDs dictionary.
 */
-(BOOL)save;

#pragma mark - Resource Methods

// GET number of instances

/**
 Returns the number of instances of a specified Resource.
 
 @param entityDescription The NSEntityDescription of a Resource as defined in @c context.persistentStoreCoordinator.managedObjectModel
 
 @return An NSNumber with the number of instances of a specified Resource.
 */
-(NSNumber *)numberOfInstancesOfResourceWithEntityDescription:(NSEntityDescription *)entityDescription;

#pragma mark - Manage Resource Instances

// Cocoa methods to manage a object graph styled after REST but without the networking or authentication, useful for editing NetworkedObjects from the server app or for other internal use.

// e.g. you want to create a new resource but dont wanna write the glue code for assigning it a proper resource ID

-(NSManagedObject<NOResourceProtocol> *)newResourceWithEntityDescription:(NSEntityDescription *)entityDescription;

-(NSManagedObject<NOResourceProtocol> *)resourceWithEntityDescription:(NSEntityDescription *)entityDescription resourceID:(NSUInteger)resourceID;

-(void)deleteResource:(NSManagedObject<NOResourceProtocol> *)resource;

@end
