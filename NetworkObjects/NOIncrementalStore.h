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

/** Incremental store for communicating with a NetworkObjects server. The URL specified in the initializer is ignored and all server schema and session variables are specified in the @c NOAPICachedStore associated with @c NOIncrementalStoreCachedStoreOption in the initializer's @c options dictionary. All fetch requests made to this store immediately return values from the cached store's context while a background request is made.*/

@interface NOIncrementalStore : NSIncrementalStore

+(NSString *)storeType;

@property (readonly) NOAPICachedStore *cachedStore;

@property (readonly) NSURLSession *urlSession;

@end
