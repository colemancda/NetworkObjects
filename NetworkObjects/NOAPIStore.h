//
//  NOAPIStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <NetworkObjects/NOResourceProtocol.h>
@class NOAPI;

typedef NS_ENUM (NSUInteger, NOAPIStoreErrorCode) {
    
    NOAPIStoreInvalidPredicateErrorCode = 2000,
    NOAPIStoreJSONInconsistent
    
};

@interface NOAPIStore : NSIncrementalStore
{
    NSMutableDictionary *_cache;
    
    NSMutableDictionary *_managedObjectIDs;
    
    uint64_t _versionCount;
}

@property (readonly) NOAPI *api;

+(NSString *)type;

#pragma mark - Execute Request

-(id)executeSaveRequest:(NSSaveChangesRequest *)request
            withContext:(NSManagedObjectContext *)context
                  error:(NSError *__autoreleasing *)error;

-(id)executeFetchRequest:(NSFetchRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error;

#pragma mark - Functions

-(NOResourceFunctionCode)sendFunctionToResource:(NSManagedObject<NOResourceKeysProtocol> *)resource
                                     jsonObject:(NSDictionary *)dictionary
                                   jsonResponse:(NSDictionary **)jsonResponse
                                          error:(NSError **)error;

#pragma mark - Obtain Object ID

-(NSManagedObjectID *)managedObjectIDForResourceID:(NSNumber *)resourceID
                                            entity:(NSEntityDescription *)entity;

-(NSNumber *)resourceIDForManagedObjectID:(NSManagedObjectID *)objectID;

@end
