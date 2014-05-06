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
@protocol NOStoreConcurrentPersistanceDelegate;

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
     A dictionary that contains NSOperationQueues for the coordinated creation of resources so that they can be given a valid Resource ID.
     */
    NSDictionary *_createResourcesQueues;
}

/**
 The recommended initializer to use for initializing a NOStore. Using -init is the same as the following code
 
 @code
 [[NOStore alloc] initWithManagedObjectModel:nil lastIDsURL:nil];
 @endcode
 
 @param persistentStoreCoordinator Preconfigured @c NSPersistentStoreCoordinator that the store will use. Can be nil.
 
 @param lastIDsURL The URL to which the list of Resource IDs will be saved. Can be nil.
 
 @return A fully initialized NOStore instance.
 
 @see NSManagedObjectModel
 */

-(instancetype)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
                             lastIDsURL:(NSURL *)lastIDsURL;

/** Initializes a @c NOStore instance configured for concurrent requests.
 */

-(instancetype)initWithConcurrentPersistanceDelegate:(id<NOStoreConcurrentPersistanceDelegate>)delegate;

#pragma mark - Serial Store Properties

/** The store's @c NSManagedObjectContext. This value is @c nil of the store was initialized with @c -initWithConcurrentPersistanceDelegate:.
 */

@property (nonatomic, readonly) NSManagedObjectContext *context;

@property (nonatomic, readonly) NSDictionary *lastResourceIDs;

@property (nonatomic, readonly) NSURL *lastIDsURL;

#pragma mark - Concurrent Store Properties

@property (nonatomic, readonly) id<NOStoreConcurrentPersistanceDelegate> concurrentPersistanceDelegate;

#pragma mark - Actions

/** Used to save the store's context and lastResourceIDs dictionary. Concurrent stores create a new context for each request and is not responsible for saving them.
 */

-(BOOL)save:(NSError **)error;

#pragma mark - Manage Resource Instances

// Cocoa methods to manage a object graph styled after REST but without the networking or authentication, useful for editing NetworkedObjects from the server app or for other internal use.

// e.g. you want to create a new resource but dont wanna write the glue code for assigning it a proper resource ID

// Make sure to call these on the same thread as the @c context argmuent.

-(NSManagedObject<NOResourceProtocol> *)resourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                                           resourceID:(NSNumber *)resourceID
                                                       shouldPrefetch:(BOOL)shouldPrefetch
                                                              context:(NSManagedObjectContext **)context
                                                                error:(NSError **)error;

-(NSArray *)fetchResources:(NSEntityDescription *)entity
           withResourceIDs:(NSArray *)resourceIDs
            shouldPrefetch:(BOOL)shouldPrefetch
                   context:(NSManagedObjectContext **)context
                     error:(NSError **)error;

-(NSManagedObject<NOResourceProtocol> *)newResourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                                                 context:(NSManagedObjectContext **)context;


@end

@protocol NOStoreConcurrentPersistanceDelegate <NSObject>

/** Delegate should setup a new @c NSPersistentStoreCoordinator instance that points to the same storage. Do no attempt to configure with @c NSInMemoryStoreType store type.
 */

-(NSPersistentStoreCoordinator *)newPersistentStoreCoordinatorForStore:(NOStore *)store;

/** Delegate should return the new resource ID for the newly created resource. */

-(NSNumber *)store:(NOStore *)store newResourceIDForResource:(NSString *)resourceName;

@end
