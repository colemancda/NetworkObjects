//
//  NOAPI.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOAPI.h"
#import <CoreData/CoreData.h>
#import "NOResourceProtocol.h"
#import "NOUserProtocol.h"
#import "NOSessionProtocol.h"
#import "NOClientProtocol.h"

@implementation NOAPI (NSJSONWritingOption)

-(NSJSONWritingOptions)jsonWritingOption
{
    if (self.prettyPrintJSON) {
        return NSJSONWritingPrettyPrinted;
    }
    
    return 0;
}

@end

@implementation NOAPI

#pragma mark - Requests

-(void)loginWithCompletion:(void (^)(NSError *))completionBlock
{
    // build login URL
    
    NSURL *loginUrl = [self.serverURL URLByAppendingPathComponent:self.loginPath];
    
    // put togeather POST body...
    
    NSEntityDescription *clientEntity = _model.entitiesByName[self.clientEntityName];
    
    Class clientEntityClass = NSClassFromString(clientEntity.managedObjectClassName);
    
    NSString *clientResourceIDKey = [clientEntityClass resourceIDKey];
    
    NSString *clientSecretKey = [clientEntityClass clientSecretKey];
    
    NSEntityDescription *userEntity = _model.entitiesByName[self.userEntityName];
    
    Class userEntityClass = NSClassFromString(userEntity.managedObjectClassName);
    
    NSString *usernameKey = [userEntityClass usernameKey];
    
    NSString *userPasswordKey = [userEntityClass userPasswordKey];
    
    NSMutableDictionary *loginJSONObject = [[NSMutableDictionary alloc] init];
    
    // need at least client info to login
    [loginJSONObject addEntriesFromDictionary:@{clientResourceIDKey: self.clientResourceID,
                                                clientSecretKey : self.clientSecret}];
    
    // add user to authentication if available
    
    if (self.username && self.userPassword) {
        
        [loginJSONObject addEntriesFromDictionary:@{usernameKey: self.username,
                                                    userPasswordKey : self.userPassword}];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginUrl];
    
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:loginJSONObject
                                                       options:self.jsonWritingOption
                                                         error:nil];
    
    request.HTTPMethod = @"POST";
    
    // execute request
    
    [_urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // parse response
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
        
        if (!response ||
            ![response isKindOfClass:[NSDictionary class]]) {
            
            
        }
        
        // get session token key
        
        NSEntityDescription *sessionEntity = _model.entitiesByName[self.sessionEntityName];
        
        Class sessionEntityClass = NSClassFromString(sessionEntity.managedObjectClassName);
        
        NSString *sessionTokenKey = [sessionEntityClass sessionTokenKey];
        
        NSString *token = jsonResponse[sessionTokenKey];
        
        if (!token) {
            
            
            
        }
        
        completionBlock(nil);
        
    }];
}

@end
