//
//  SNCStore.m
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/21/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNCStore.h"
#import "User.h"
#import "Post.h"

@interface SNCStore ()

@property User *user;

@property NOAPICachedStore *cachedStore;

@property NOIncrementalStore *incrementalStore;

@property NSManagedObjectContext *context;

@end

@implementation SNCStore

+ (instancetype)sharedStore
{
    static SNCStore *sharedStore = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        sharedStore = [[self alloc] init];
        
    });
    
    return sharedStore;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        
        // configure cache store...
        
        self.cachedStore = [[NOAPICachedStore alloc] initWithOptions:@{NOAPIModelOption: [NSManagedObjectModel mergedModelFromBundles:nil], NOAPISessionEntityNameOption: @"Session", NOAPIUserEntityNameOption: @"User", NOAPIClientEntityNameOption: @"Client", NOAPILoginPathOption: @"login", NOAPISearchPathOption: @"search"}];
        
        self.cachedStore.shouldProcessPendingChanges = YES;
        
        self.cachedStore.prettyPrintJSON = YES;
        
        self.cachedStore.context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.cachedStore.model];
        
        NSError *error;
        
        [self.cachedStore.context.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                                          configuration:nil
                                                                                    URL:nil
                                                                                options:nil
                                                                                  error:&error];
        
        NSAssert(!error, @"Could not create persistent cache store");
        
        // configure incremental store
        
        self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
        self.context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.cachedStore.model];
        
        self.incrementalStore = (id)[self.context.persistentStoreCoordinator addPersistentStoreWithType:[NOIncrementalStore storeType]
                                                                          configuration:nil
                                                                                    URL:nil
                                                                                options:@{NOIncrementalStoreCachedStoreOption: self.cachedStore}
                                                                                  error:&error];
        
        NSAssert(!error, @"Could not create incremental store");
        
    }
    
    return self;
}

#pragma mark - Authentication

-(void)loginWithUsername:(NSString *)username
                password:(NSString *)password
               serverURL:(NSURL *)serverURL
                clientID:(NSUInteger)clientID
            clientSecret:(NSString *)secret
              URLSession:(NSURLSession *)urlSession
              completion:(void (^)(NSError *))completionBlock

{
    // setup session properties
    self.cachedStore.username = username;
    self.cachedStore.userPassword = password;
    self.cachedStore.serverURL = serverURL;
    self.cachedStore.clientSecret = secret;
    self.cachedStore.clientResourceID = @(clientID);
    
    NSLog(@"Logging in as '%@'...", username);
    
    [self.cachedStore loginWithURLSession:urlSession completion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // get the user for this session
        [self.cachedStore getCachedResource:@"User" resourceID:self.cachedStore.userResourceID.integerValue URLSession:urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            // save session values
            self.user = (User *)resource;
            
            NSLog(@"Successfully logged in");
            
            completionBlock(nil);
            
        }];
    }];
}

-(void)registerWithUsername:(NSString *)username
                        password:(NSString *)password
                       serverURL:(NSURL *)serverURL
                        clientID:(NSUInteger)clientID
                    clientSecret:(NSString *)secret
                      URLSession:(NSURLSession *)urlSession
                      completion:(void (^)(NSError *))completionBlock
{
    
    // setup session properties
    self.cachedStore.serverURL = serverURL;
    self.cachedStore.clientSecret = secret;
    self.cachedStore.clientResourceID = @(clientID);
    self.cachedStore.username = nil;
    self.cachedStore.userPassword = nil;
    
    NSLog(@"Registering as '%@'...", username);
    
    // login as app
    
    [self.cachedStore loginWithURLSession:urlSession completion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        [self.cachedStore createCachedResource:@"User" initialValues:@{@"username": username, @"password" : password} URLSession:urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            User *newUser = (User *)resource;
            
            // login as newly created user
            [self loginWithUsername:newUser.username password:password serverURL:serverURL clientID:clientID clientSecret:secret URLSession:urlSession completion:^(NSError *error) {
                
                if (error) {
                    
                    completionBlock(error);
                    
                    return;
                }
                
                
                NSLog(@"Successfully registered");
                
                completionBlock(nil);
                
            }];
        }];
    }];
}

#pragma mark - Logout

-(void)logout
{
    self.user = nil;
    self.cachedStore.userPassword = nil;
    self.cachedStore.username = nil;
    self.cachedStore.userResourceID = nil;
    self.cachedStore.clientResourceID = nil;
    self.cachedStore.clientSecret = nil;
    self.cachedStore.serverURL = nil;
    self.cachedStore.sessionToken = nil;
    
    // reset cache
    
    [self.cachedStore.context performBlock:^{
        
        [self.cachedStore.context reset];
        
    }];
    
    [self.context performBlock:^{
        
        [self.context reset];
        
    }];
    
    NSLog(@"User logged out");
    
}

@end
