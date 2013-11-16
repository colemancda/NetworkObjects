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
#import "AppDelegate.h"

@implementation ClientStore

-(id)initWithURL:(NSURL *)url
           error:(NSError *__autoreleasing *)error
{
    self = [super init];
    if (self) {
        
        // initialize context
        
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
        _context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel mergedModelFromBundles:nil]];
        
        // add incremental store
        NSString *storeType = [NOAPIStore type];
        
        NSPersistentStore *store = [_context.persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                                                     configuration:nil
                                                                                               URL:url
                                                                                           options:nil
                                                                                             error:error];
        
        if (*error) {
            
            return nil;
        }
        
        _apiStore = (NOAPIStore *)store;
        
        // initialize API
        
        _apiStore.api.urlSession = [NSURLSession sharedSession];
        
        _apiStore.api.sessionEntityName = @"Session";
        
        _apiStore.api.userEntityName = @"User";
        
        _apiStore.api.clientEntityName = @"Client";
        
        _apiStore.api.prettyPrintJSON = YES;
        
        _apiStore.api.loginPath = @"login";
        
        
        
    }
    return self;
}

#pragma mark

-(void)loginWithUsername:(NSString *)username
                password:(NSString *)password
              completion:(void (^)(NSError *))completionBlock
{
    self.apiStore.api.username = username;
    
    self.apiStore.api.userPassword = password;
    
    NSLog(@"Logging in as '%@'...", username);
    
    [self.apiStore.api loginWithCompletion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        NSLog(@"Fetching logged in User...");
        
        // get user that logged in
        [_context performBlock:^{
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
            
            request.predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"resourceID", self.apiStore.api.userResourceID];
            
            NSError *error;
            
            NSArray *results = [_context executeFetchRequest:request
                                                       error:&error];
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            User *user = results.firstObject;
            
            if (!user) {
                
                NSString *errorDescription = NSLocalizedString(@"Could not fetch user",
                                                               @"Could not fetch user");
                
                error = [NSError errorWithDomain:AppErrorDomain
                                            code:1000
                                        userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(error);
                
                return;
            }
            
            NSLog(@"Got user, finished login process");
            
            _user = user;
            
            completionBlock(nil);
            
        }];
    }];
}

-(void)registerWithUsername:(NSString *)username
                   password:(NSString *)password
                 completion:(void (^)(NSError *))completionBlock
{
    // create object
    
    NSLog(@"Creating new User '%@'", username);
    
    [self.apiStore.api createResource:@"User" withInitialValues:@{@"username": username, @"password" : password} completion:^(NSError *error, NSNumber *resourceID) {
       
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // login
        
        [self.apiStore.api loginWithCompletion:^(NSError *error) {
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            completionBlock(nil);
            
        }];
    }];
}


@end
