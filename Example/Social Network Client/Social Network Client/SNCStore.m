//
//  SNCStore.m
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/21/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNCStore.h"
#import <NetworkObjects/NetworkObjects.h>
#import "User.h"
#import "Post.h"

@interface SNCStore ()

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
    self = [super initWithModel:[NSManagedObjectModel mergedModelFromBundles:nil]
              sessionEntityName:@"Session"
                 userEntityName:@"User"
               clientEntityName:@"Client"
                      loginPath:@"login"];
    
    if (self) {
        
        self.prettyPrintJSON = YES;
        
        // add persistent store
        self.context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
        
        NSError *error;
        
        [self.context.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
        
        NSAssert(!error, @"Could not create In-Memory store");
        
        
    }
    return self;
}

- (id)initWithModel:(NSManagedObjectModel *)model
  sessionEntityName:(NSString *)sessionEntityName
     userEntityName:(NSString *)userEntityName
   clientEntityName:(NSString *)clientEntityName loginPath:(NSString *)loginPath
{
    [NSException raise:@"Wrong initialization method"
                format:@"You cannot use %@ with '-%@', you have to use '+%@'",
     self,
     NSStringFromSelector(_cmd),
     NSStringFromSelector(@selector(sharedStore))];
    return nil;
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
        [self getCachedResource:@"User" resourceID:self.userResourceID.integerValue URLSession:urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            // save session values
            self.serverURL = serverURL;
            self.clientSecret = secret;
            self.clientResourceID = @(clientID);
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

#pragma mark - Complex Requests

-(NSURLSessionDataTask *)fetchUserWithURLSession:(NSURLSession *)urlSession
                                      completion:(void (^)(NSError *))completionBlock
{
    NSAssert(self.user, @"Must already be authenticated to fetch user");
    
    return [self getCachedResource:self.user.entity.name resourceID:self.user.resourceID.integerValue URLSession:urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        self.user = (User *)resource;
        
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
    
    // reset context
    [self.context performBlock:^{
        
        [self.context reset];
        
        NSLog(@"User logged out");
        
    }];
    
}

#pragma mark - Fetch

-(NSURLSessionDataTask *)getCachedResource:(NSString *)resourceName resourceID:(NSUInteger)resourceID URLSession:(NSURLSession *)urlSession completion:(void (^)(NSError *, NSManagedObject<NOResourceKeysProtocol> *))completionBlock
{
    return [super getCachedResource:resourceName resourceID:resourceID URLSession:urlSession completion:^void(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
        
        if (!error) {
            
            [self.context performBlock:^{
                
                [self.context processPendingChanges];
                
            }];
        }
        
        completionBlock(error, resource);
        
    }];
}

-(NSURLSessionDataTask *)deleteCachedResource:(NSManagedObject<NOResourceKeysProtocol> *)resource URLSession:(NSURLSession *)urlSession completion:(void (^)(NSError *))completionBlock
{
    return [super deleteCachedResource:resource URLSession:urlSession completion:^void(NSError *error){
       
        if (!error) {
            
            [self.context performBlock:^{
                
                [self.context processPendingChanges];
                
            }];
        }
        
        completionBlock(error);
        
    }];
}

-(NSURLSessionDataTask *)editCachedResource:(NSManagedObject<NOResourceKeysProtocol> *)resource
                                    changes:(NSDictionary *)values
                                 URLSession:(NSURLSession *)urlSession
                                 completion:(void (^)(NSError *))completionBlock
{
    return [super editCachedResource:resource changes:values URLSession:urlSession completion:^void(NSError *error) {
        
        if (!error) {
            
            [self.context performBlock:^{
                
                [self.context processPendingChanges];
                
            }];
        }
        
        completionBlock(error);
        
    }];
}

-(NSURLSessionDataTask *)createCachedResource:(NSString *)resourceName initialValues:(NSDictionary *)initialValues URLSession:(NSURLSession *)urlSession completion:(void (^)(NSError *, NSManagedObject<NOResourceKeysProtocol> *))completionBlock
{
    return [super createCachedResource:resourceName initialValues:initialValues URLSession:urlSession completion:^void(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
        
        if (!error) {
            
            [self.context performBlock:^{
                
                [self.context processPendingChanges];
                
            }];
        }
        
        completionBlock(error, resource);
        
    }];
    
}

@end
