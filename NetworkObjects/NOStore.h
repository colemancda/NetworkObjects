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

typedef NS_ENUM(NSUInteger, NOStoreErrorCode) {
    
    /** Could not backup the previous archive of @c _lastResourceIDs. */
    NOStoreBackupLastIDsSaveError = 100,
    
    /** Could not restore the previous archive of @c _lastResourceIDs. */
    NOStoreRestoreLastIDsSaveError
};

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
     A dictionary that contains NSOperationQueues for the coordinated creation of resources so that they can be given valid Resource ID.
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

-(id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
                             lastIDsURL:(NSURL *)lastIDsURL;

@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, readonly) NSDictionary *lastResourceIDs;

@property (nonatomic, readonly) NSURL *lastIDsURL;

#pragma mark - Manage Resource Instances

// Cocoa methods to manage a object graph styled after REST but without the networking or authentication, useful for editing NetworkedObjects from the server app or for other internal use.

// e.g. you want to create a new resource but dont wanna write the glue code for assigning it a proper resource ID

-(NSManagedObject<NOResourceProtocol> *)newResourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                                                   error:(NSError **)error;

-(NSManagedObject<NOResourceProtocol> *)resourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                                           resourceID:(NSNumber *)resourceID
                                                       shouldPrefetch:(BOOL)shouldPrefetch
                                                                error:(NSError **)error;

-(BOOL)deleteResource:(NSManagedObject<NOResourceProtocol> *)resource
                error:(NSError **)error;

@end
