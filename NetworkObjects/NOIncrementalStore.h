//
//  NOIncrementalStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 3/28/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <CoreData/CoreData.h>
@class NOAPICachedStore;

// Initializations options

/** Option used upon initializaton that specifies the @c NOAPICachedStore the incremental store will be use.
 
 @warning Make sure to include this option when initializing the incremental store.
 
 */

extern NSString *const NOIncrementalStoreCachedStoreOption;

// Notifications

/** Notificiation posted when a fetch request finishes retrieving data from the server. The @c userInfo included will contain the original fetch request that was executed associated with @c NOIncrementalStoreRequestKey and an error associated with the @c NOIncrementalStoreErrorKey or the results with @c NOIncrementalStoreResultsKey.
 */

extern NSString *const NOIncrementalStoreFinishedFetchRequestNotification;

/** Notificiation posted when a managed object is faulted with data from the server. The @c userInfo included will contain the object ID that requested new values associated with @c NOIncrementalStoreObjectIDKey and an error associated with the @c NOIncrementalStoreErrorKey or the new values with @c NOIncrementalStoreNewValuesKey.
 */

extern NSString *const NOIncrementalStoreDidGetNewValuesNotification;

// Keys

extern NSString *const NOIncrementalStoreRequestKey;

extern NSString *const NOIncrementalStoreErrorKey;

extern NSString *const NOIncrementalStoreResultsKey;

extern NSString *const NOIncrementalStoreNewValuesKey;

extern NSString *const NOIncrementalStoreObjectIDKey;


/** Incremental store for communicating with a NetworkObjects server. The URL specified in the initializer is ignored and all server schema and session variables are specified in the @c NOAPICachedStore associated with @c NOIncrementalStoreCachedStoreOption in the initializer's @c options dictionary. All fetch requests made to this store immediately return values from the cached store's context while a background request is made.*/

@interface NOIncrementalStore : NSIncrementalStore
{
    NSOperationQueue *_notificationQueue;
}

+(NSString *)storeType;

@property (readonly) NOAPICachedStore *cachedStore;

@property (readonly) NSURLSession *urlSession;

@end
