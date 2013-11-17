//
//  ClientStore.m
//  NetworkObjectsClient
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "ClientStore.h"
#import <NetworkObjects/NOAPI.h>
#import "AppDelegate.h"

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
        
        _api.urlSession = [NSURLSession sharedSession];
        
        _api.sessionEntityName = @"Session";
        
        _api.userEntityName = @"User";
        
        _api.clientEntityName = @"Client";
        
        _api.prettyPrintJSON = YES;
        
        _api.loginPath = @"login";
        
    }
    return self;
}

#pragma mark

-(void)loginWithUsername:(NSString *)username
                password:(NSString *)password
              completion:(void (^)(NSError *))completionBlock
{
    self.api.username = username;
    
    self.api.userPassword = password;
    
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
    // login as client
    
    self.api.username = nil;
    
    self.api.userPassword = nil;
    
    NSLog(@"Logging in as App");
    
    [self.api loginWithCompletion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        NSLog(@"Creating new User '%@'", username);
        
        [self.api createResource:@"User" withInitialValues:@{@"username": username, @"password" : password} completion:^(NSError *error, NSNumber *resourceID)
        {
            
            if (error) {
                
                completionBlock(error);
                
                return;
            }
            
            [self loginWithUsername:username password:password completion:^(NSError *error) {
                
                if (error) {
                    
                    completionBlock(error);
                    
                    return;
                }
                
                NSLog(@"Sucessfully registered user '%@'", username);
                
                completionBlock(nil);
                
            }];
            
        }];
    }];
}


@end
