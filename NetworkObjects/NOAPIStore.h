//
//  NOAPIStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <NetworkObjects/NOAPIStoreConstants.h>
@class NOAPI;

FOUNDATION_EXPORT NSString *const NOAPIStoreType;

@interface NOAPIStore : NSIncrementalStore 

@property NOAPI *api;

#pragma mark

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error;

-(id)executeFetchRequest:(NSFetchRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error;

#pragma mark

-(BOOL)fetchRequestEntityIsResource:(NSFetchRequest *)request;

@end
