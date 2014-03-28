//
//  NOIncrementalStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 3/28/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOIncrementalStore.h"
#import "NOAPICachedStore.h"

NSString *const NOIncrementalStoreCachedStoreOption = @"NOIncrementalStoreCachedStoreOption";

NSString *const NOIncrementalStoreType = @"NOIncrementalStoreType";

@interface NOIncrementalStore ()



@end

@implementation NOIncrementalStore

#pragma mark - Initialization

-(id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root
                      configurationName:(NSString *)name
                                    URL:(NSURL *)url
                                options:(NSDictionary *)options
{
    self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options];
    
    if (self) {
        
        self.cachedStore = options[NOIncrementalStoreCachedStoreOption];
        
        if (<#condition#>) {
            <#statements#>
        }
        
    }
    
    return self;
}

-(BOOL)loadMetadata:(NSError *__autoreleasing *)error
{
    self.metadata = @{NSStoreTypeKey: NOIncrementalStoreType, NSStoreUUIDKey : [[NSUUID UUID] UUIDString]};
    
    return YES;
}

#pragma mark - Request

-(id)executeRequest:(NSPersistentStoreRequest *)request
        withContext:(NSManagedObjectContext *)context
              error:(NSError *__autoreleasing *)error
{
    
    
}

@end
