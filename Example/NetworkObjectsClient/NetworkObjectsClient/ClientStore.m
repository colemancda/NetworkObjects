//
//  ClientStore.m
//  NetworkObjectsClient
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "ClientStore.h"
#import "AppDelegate.h"
#import "User.h"
#import <NetworkObjects/NSManagedObject+CoreDataJSONCompatibility.h>
#import <NetworkObjects/NOAPICachedStore.h>

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
        
        NOAPI *api = [[NOAPI alloc] init];
        
        api.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                       delegate:self
                                                  delegateQueue:[[NSOperationQueue alloc] init]];
        
        api.sessionEntityName = @"Session";
        
        api.userEntityName = @"User";
        
        api.clientEntityName = @"Client";
        
        api.prettyPrintJSON = YES;
        
        api.loginPath = @"login";
        
        api.model = [NSManagedObjectModel mergedModelFromBundles:nil];
        
        _store = [[NOAPICachedStore alloc] init];
        
        _store.api = api;
        
        // initialize context
        
        _store.context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:api.model];
        
        NSError *error;
        
        [_store.context.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                                configuration:nil
                                                                          URL:nil
                                                                      options:nil
                                                                        error:&error];
        if (error) {
            
            [NSException raise:NSInternalInconsistencyException
                        format:@"Could not add In-Memory store"];
            
            return nil;
        }
        
    }
    return self;
}

#pragma mark - NSURLSession Delegate

-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    // trust any certificate
    
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

#pragma mark

-(void)loginWithUsername:(NSString *)username
                password:(NSString *)password
              completion:(void (^)(NSError *))completionBlock
{
    self.store.api.username = username;
    
    self.store.api.userPassword = password;
    
    NSLog(@"Logging in as '%@'...", username);
    
    [self.store.api loginWithCompletion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        NSLog(@"Fetching logged in User...");
        
        // get user that logged in
        
        [self.store getResource:@"User" resourceID:self.store.api.userResourceID.integerValue completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
           
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            NSLog(@"Got user, finished login process");
            
            _user = (User *)resource;
            
            completionBlock(nil);
            
        }];
    }];
}

-(void)registerWithUsername:(NSString *)username
                   password:(NSString *)password
                 completion:(void (^)(NSError *))completionBlock
{
    // login as client
    
    self.store.api.username = nil;
    
    self.store.api.userPassword = nil;
    
    NSLog(@"Logging in as App");
    
    [self.store.api loginWithCompletion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        NSLog(@"Creating new User '%@'", username);
        
        [self.store createResource:@"User" initialValues:@{@"username": username, @"password" : password} completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            [self loginWithUsername:username password:password completion:^(NSError *error) {
                
                if (error) {
                    
                    completionBlock(error);
                    
                    return;
                }
                
                _user = (User *)resource;
                
                NSLog(@"Sucessfully registered user '%@'", username);
                
                completionBlock(nil);
                
            }];
        }];
    }];
}

#pragma mark - Requests

-(void)fetchPostsOfUser:(User *)user
             completion:(void (^)(NSError *))completionBlock
{
    
    
}

@end
