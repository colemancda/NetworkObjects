//
//  SNCStore.m
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/21/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNCStore.h"
#import <NetworkObjects/NetworkObjects.h>

@interface SNCStore ()

@property NSURL *serverURL;

@property NSUInteger clientID;

@property NSString *clientSecret;

@property User *user;

@end

@implementation SNCStore

+ (instancetype)sharedStore
{
    static SNCStore *sharedStore = nil;
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
        
        // initialize cache store and API configuration
        _cacheStore = [[NOAPICachedStore alloc] init];
        _cacheStore.api = [[NOAPI alloc] init];
        _cacheStore.api.model = [NSManagedObjectModel mergedModelFromBundles:nil];
        _cacheStore.api.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _cacheStore.api.sessionEntityName = @"Session";
        _cacheStore.api.userEntityName = @"User";
        _cacheStore.api.clientEntityName = @"Client";
        _cacheStore.api.prettyPrintJSON = YES;
        _cacheStore.api.loginPath = @"login";
        
        // add persistent store
        _cacheStore.context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_cacheStore.api.model];
        
        NSError *error;
        
        [_cacheStore.context.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
        
        NSAssert(!error, @"Could not create In-Memory store");
        
        
        
    }
    return self;
}


#pragma mark - Authentication
-(void)loginWithUsername:(NSString *)username
                password:(NSString *)password
               serverURL:(NSURL *)serverURL
                clientID:(NSUInteger)clientID
            clientSecret:(NSString *)secret
              completion:(void (^)(NSError *))completionBlock

{
    // setup session properties
    _cacheStore.api.username = username;
    _cacheStore.api.userPassword = password;
    _cacheStore.api.serverURL = serverURL;
    _cacheStore.api.clientSecret = secret;
    _cacheStore.api.clientResourceID = [NSNumber numberWithInteger:clientID];
    
    NSLog(@"Logging in as %@", username);
    
    [_cacheStore.api loginWithCompletion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // get the user for this session
        [_cacheStore getResource:@"User" resourceID:_cacheStore.api.userResourceID.integerValue completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            
            // save session values
            self.serverURL = serverURL;
            self.clientSecret = secret;
            self.clientID = clientID;
            self.user = (User *)resource;
            
            NSLog(@"Successfully logged in");
            
        }];
    }];
}

-(void)registerWithUsername:(NSString *)username
                   password:(NSString *)password
                  serverURL:(NSURL *)serverURL
                   clientID:(NSUInteger)clientID
               clientSecret:(NSString *)secret
                 completion:(void (^)(NSError *))completionBlock
{
    
    // setup session properties
    _cacheStore.api.serverURL = serverURL;
    _cacheStore.api.clientSecret = secret;
    _cacheStore.api.clientResourceID = [NSNumber numberWithInteger:clientID];
    
    NSLog(@"Registering as %@", username);
    
    // login as app
    
    [_cacheStore.api loginWithCompletion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        [_cacheStore createResource:@"User" initialValues:@{@"username": username, @"password" : password} completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            // save session values
            self.serverURL = serverURL;
            self.clientSecret = secret;
            self.clientID = clientID;
            self.user = (User *)resource;
            
            NSLog(@"Successfully registered");
            
        }];
    }];
}

@end
