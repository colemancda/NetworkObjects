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

@property (nonatomic) User *user;

@property (nonatomic) NSManagedObjectContext *mainContext;

-(void)contextDidSave:(NSNotification *)notification;

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

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super initWithOptions:@{NOAPIModelOption: [NSManagedObjectModel mergedModelFromBundles:nil],
                                    NOAPISessionEntityNameOption: @"Session",
                                    NOAPIUserEntityNameOption: @"User",
                                    NOAPIClientEntityNameOption: @"Client",
                                    NOAPILoginPathOption: @"login",
                                    NOAPISearchPathOption: @"search",
                                    NOAPICachedStoreDateCachedAttributeNameOption : @"dateCached"}];
    
    if (self) {
        
        // configure cache store...
        
        self.prettyPrintJSON = YES;
        
        self.context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
        
        NSError *error;
        
        [self.context.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                                          configuration:nil
                                                                                    URL:nil
                                                                                options:nil
                                                                                  error:&error];
        
        NSAssert(!error, @"Could not create persistent store for cached store");
        
        // add main queue context
        
        self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        
        self.mainContext.undoManager = nil;
        
        self.mainContext.persistentStoreCoordinator = self.context.persistentStoreCoordinator;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:self.context];
        
    }
    
    return self;
}

#pragma mark - Notifications

-(void)contextDidSave:(NSNotification *)notification
{
    [self.mainContext performBlock:^{
        
        [self.mainContext mergeChangesFromContextDidSaveNotification:notification];
        
    }];
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
    
    [self loginWithURLSession:urlSession completion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // get the user for this session
        [self getCachedResource:@"User" resourceID:self.userResourceID URLSession:urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            // save session values
            self.serverURL = serverURL;
            self.clientSecret = secret;
            self.clientResourceID = @(clientID);
            self.user = (User *)[self.mainContext objectWithID:resource.objectID];
            
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
    self.serverURL = serverURL;
    self.clientSecret = secret;
    self.clientResourceID = @(clientID);
    self.username = nil;
    self.userPassword = nil;
    
    NSLog(@"Registering as '%@'...", username);
    
    // login as app
    
    [self loginWithURLSession:urlSession completion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        [self createCachedResource:@"User" initialValues:@{@"username": username, @"password" : password} URLSession:urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            User *newUser = (User *)[self.mainContext objectWithID:resource.objectID];
            
            // login as newly created user
            [self loginWithUsername:newUser.username password:password serverURL:serverURL clientID:clientID clientSecret:secret URLSession:urlSession completion:^(NSError *error) {
                
                if (error) {
                    
                    completionBlock(error);
                    
                    return;
                }
                
                self.user = newUser;
                
                NSLog(@"Successfully registered");
                
                completionBlock(nil);
                
            }];
        }];
    }];
}

#pragma mark - Complex Requests

-(NSURLSessionDataTask *)fetchUserWithURLSession:(NSURLSession *)urlSession
                                      completion:(void (^)(NSError *))completionBlock
{
    NSAssert(self.user, @"Must already be authenticated to fetch user");
    
    return [self getCachedResource:self.user.entity.name resourceID:self.user.resourceID URLSession:urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        self.user = (User *)[self.mainContext objectWithID:resource.objectID];
        
        completionBlock(nil);
        
    }];
}

#pragma mark - Logout

-(void)logout
{
    self.user = nil;
    self.userPassword = nil;
    self.username = nil;
    self.userResourceID = nil;
    self.clientResourceID = nil;
    self.clientSecret = nil;
    self.serverURL = nil;
    self.sessionToken = nil;
    
    // reset cache
    
    [self.context performBlock:^{
        
        [self.context reset];
        
    }];
    
    NSLog(@"User logged out");
    
}

@end
