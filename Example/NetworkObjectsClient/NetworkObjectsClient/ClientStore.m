//
//  ClientStore.m
//  NetworkObjectsClient
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "ClientStore.h"
#import <NetworkObjects/NOAPI.h>
#import <NetworkObjects/NOAPIStore.h>

@implementation ClientStore

+ (ClientStore *)sharedStore
{
    static ClientStore *sharedStore = nil;
    if (!sharedStore) {
        sharedStore = [[super allocWithZone:nil] init];
    }
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedStore];
}

- (id)init
{
    self = [super init];
    if (self) {
        
        // initialize API
        
        _api = [[NOAPI alloc] init];
        
        self.api.model = [NSManagedObjectModel mergedModelFromBundles:nil];
        
        self.api.urlSession = [NSURLSession sharedSession];
        
        self.api.sessionEntityName = @"Session";
        
        self.api.userEntityName = @"User";
        
        self.api.clientEntityName = @"Client";
        
        self.api.prettyPrintJSON = YES;
        
        self.api.loginPath = @"login";
        
        // initialize context
        
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
        _context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.api.model];
        
        // add incremental store
        
        NSPersistentStore *store = [_context.persistentStoreCoordinator addPersistentStoreWithType:NOAPIStoreType
                                                                                     configuration:nil
                                                                                               URL:nil
                                                                                           options:nil
                                                                                             error:nil];
        
        _apiStore = (NOAPIStore *)store;
        
        _apiStore.api = _api;
        
    }
    return self;
}

#pragma mark






@end
