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

-(NSArray *)loginWithUsername:(NSString *)username
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
    self.clientResourceID = [NSNumber numberWithInteger:clientID];
    
    NSLog(@"Logging in as '%@'...", username);
    
    NSMutableArray *tasks = [[NSMutableArray alloc] init];
    
    NSURLSessionDataTask *dataTask = [self loginWithURLSession:urlSession completion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // get the user for this session
        NSURLSessionDataTask *dataTask = [self getCachedResource:@"User" resourceID:self.userResourceID.integerValue URLSession:urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
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
            
            completionBlock(nil);
            
        }];
        
        [tasks addObject:dataTask];
        
    }];
    
    [tasks addObject:dataTask];
    
    return tasks;
}

-(NSArray *)registerWithUsername:(NSString *)username
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
    self.clientResourceID = [NSNumber numberWithInteger:clientID];
    self.username = nil;
    self.userPassword = nil;
    
    NSLog(@"Registering as '%@'...", username);
    
    NSMutableArray *tasks = [[NSMutableArray alloc] init];
    
    // login as app
    
    NSURLSessionDataTask *dataTask = [self loginWithURLSession:urlSession completion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        NSURLSessionDataTask *dataTask = [self createCachedResource:@"User" initialValues:@{@"username": username, @"password" : password} URLSession:urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
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
            
            completionBlock(nil);
            
        }];
        
        [tasks addObject:dataTask];
        
    }];
    
    [tasks addObject:dataTask];
    
    return tasks;
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

@end
