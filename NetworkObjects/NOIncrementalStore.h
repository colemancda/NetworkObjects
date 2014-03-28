//
//  NOIncrementalStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 3/28/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <CoreData/CoreData.h>
@class NOAPICachedStore;

/** Option used upon initializaton that specifies the @c NOAPICachedStore the incremental store will be use.
 
 @warning Make sure to include this option when initializing the incremental store.
 
 */

extern NSString *const NOIncrementalStoreCachedStoreOption;

/** The persistent store type. */

extern NSString *const NOIncrementalStoreType;

@interface NOIncrementalStore : NSIncrementalStore

@property (readonly) NOAPICachedStore *cachedStore;

#pragma mark - Execute Request

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error;

-(id)executeFetchRequest:(NSFetchRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error;


@end
