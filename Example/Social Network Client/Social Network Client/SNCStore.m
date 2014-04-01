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

@property NSManagedObjectContext *cacheContext;

@property NSManagedObjectContext *incrementalContext;

@property NOIncrementalStore *incrementalStore;

@property NSMutableSet *incrementalContexts

;

@property NSOperationQueue *incrementalContextsOperationQueue;

// Session properties

@property NSString *username;

@property NSString *userPassword;

@property NSURL *serverURL;

@property NSString *clientSecret;

@property NSNumber *clientResourceID;

-(void)contextDidChange:(NSNotification *)notification;

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
        
        self.incrementalContexts = [[NSMutableSet alloc] init];
        
        self.incrementalContextsOperationQueue = [[NSOperationQueue alloc] init];
        
        self.incrementalContextsOperationQueue.maxConcurrentOperationCount = 1;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:nil];
        
        // configure cache context...
        
        self.cacheContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
        self.cacheContext.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel mergedModelFromBundles:nil]];
        
        NSError *error;
        
        [self.cacheContext.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                                   configuration:nil
                                                                             URL:nil
                                                                         options:nil
                                                                           error:&error];
        
        NSAssert(!error, @"Could not setup cache context");
        
        
        
    }
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    self.username = username;
    self.userPassword = password;
    self.serverURL = serverURL;
    self.clientSecret = secret;
    self.clientResourceID = @(clientID);
    
    NSLog(@"Logging in as '%@'...", username);
    
    NSManagedObjectContext *context;
    
    self.incrementalStore = [self newIncrementalStoreWithURLSession:urlSession context:&context];
    
    self.incrementalContext = context;
    
    [self.incrementalStore loginWithContext:context completion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // fetch request
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        
        fetchRequest.predicate = (id)[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"resourceID"] rightExpression:[NSExpression expressionForConstantValue:self.incrementalStore.userResourceID] modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:NSNormalizedPredicateOption];
        
        [context performBlock:^{
            
            NSError *fetchError;
            
            NSArray *results = [context executeFetchRequest:fetchRequest error:&fetchError];
            
            if (fetchError) {
                
                completionBlock(fetchError);
                
                return;
            }
            
            // save user
            
            self.user = results.firstObject;
            
            NSLog(@"Successfully logged in");
            
            completionBlock(nil);

        }];
        
    }];
}

/*

-(void)registerWithUsername:(NSString *)username
                   password:(NSString *)password
                  serverURL:(NSURL *)serverURL
                   clientID:(NSUInteger)clientID
               clientSecret:(NSString *)secret
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
 
 */

#pragma mark - Logout

-(void)logout
{
    self.user = nil;
    self.userPassword = nil;
    self.username = nil;
    self.clientSecret = nil;
    self.serverURL = nil;
    
    // reset cache
    
    [self.cacheContext performBlock:^{
        
        [self.cacheContext reset];
        
    }];
    
    NSLog(@"User logged out");
}

#pragma mark - Incremental Stores

-(NOIncrementalStore *)newIncrementalStoreWithURLSession:(NSURLSession *)urlSession context:(NSManagedObjectContext *__autoreleasing *)contextPointer
{
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    
    [options addEntriesFromDictionary:@{NOIncrementalStoreClientEntityNameOption: @"Client",
                                        NOIncrementalStoreSessionEntityNameOption: @"Session",
                                        NOIncrementalStoreUserEntityNameOption: @"User",
                                        NOIncrementalStoreSearchPathOption: @"search",
                                        NOIncrementalStoreLoginPathOption: @"login"}];
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    *contextPointer = context;
    
    context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel mergedModelFromBundles:nil]];
    
    NOIncrementalStore *incrementalStore = (id)[context.persistentStoreCoordinator addPersistentStoreWithType:[NOIncrementalStore storeType]
                                                                             configuration:nil
                                                                                       URL:self.serverURL
                                                                                   options:options
                                                                                     error:nil];
    
    // setup session properties
    
    incrementalStore.username = self.username;
    
    incrementalStore.userPassword = self.userPassword;
    
    incrementalStore.clientResourceID = self.clientResourceID;
    
    incrementalStore.clientSecret = self.clientSecret;
    
    // setup syncing
    
    [self.incrementalContextsOperationQueue addOperations:@[[NSBlockOperation blockOperationWithBlock:^{
        
        [self.incrementalContexts addObject:context];
        
    }]] waitUntilFinished:YES];
    
    return incrementalStore;
}

-(void)deleteIncrementalContext:(NSManagedObjectContext *)context
{
    [self.incrementalContextsOperationQueue addOperations:@[[NSBlockOperation blockOperationWithBlock:^{
        
        [self.incrementalContexts removeObject:context];
        
    }]] waitUntilFinished:YES];
}

#pragma mark - Notifications

-(void)contextDidChange:(NSNotification *)notification
{
    // make sure its one of our contexts
    
    NSSet *contexts = [NSSet setWithSet:self.incrementalContexts];
    
    if ([contexts containsObject:notification.object]) {
        
        // syncronize
        
        [self.cacheContext performBlock:^{
           
            [self.cacheContext mergeChangesFromContextDidSaveNotification:notification];
            
        }];
    }
    
}

@end
