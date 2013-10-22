//
//  NOAPIStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOAPIStore.h"
#import "NOResourceProtocol.h"
#import "NOUserProtocol.h"
#import "NOSessionProtocol.h"
#import "NOClientProtocol.h"

@implementation NOAPIStore

- (id)init
{
    self = [super init];
    if (self) {
        
        // setup NSURLSession
        
        NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        _urlSession = [NSURLSession sessionWithConfiguration:urlSessionConfig
                                                    delegate:self
                                               delegateQueue:[[NSOperationQueue alloc] init]];
        
        
    }
    return self;
}

#pragma mark - Requests

-(void)loginWithCompletion:(void (^)(NSError *))completionBlock
{
    // build login URL
    
    NSURL *loginUrl = [self.URL URLByAppendingPathComponent:self.loginPath];
    
    // put togeather POST body...
    
    NSManagedObjectModel *model = self.persistentStoreCoordinator.managedObjectModel;
    
    NSEntityDescription *clientEntity = model.entitiesByName[self.clientEntityName];
    
    Class clientEntityClass = NSClassFromString(clientEntity.managedObjectClassName);
    
    
    
    NSDictionary *loginJSONObject = @
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginUrl];
    request
    
    
}

@end
