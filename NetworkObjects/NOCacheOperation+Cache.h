//
//  NOCacheOperation+Cache.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 4/13/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <NetworkObjects/NetworkObjects.h>
@import CoreData;

@interface NOCacheOperation (Cache)

-(NSManagedObject <NOResourceKeysProtocol> *)findOrCreateResource:(NSString *)resourceName
                                                   withResourceID:(NSNumber *)resourceID
                                                          context:(NSManagedObjectContext **)context;

-(NSManagedObject <NOResourceKeysProtocol> *)findResource:(NSString *)resourceName
                                           withResourceID:(NSNumber *)resourceID
                                                  context:(NSManagedObjectContext **)context
                                   returnsObjectsAsFaults:(BOOL)returnsObjectsAsFaults;

@end
