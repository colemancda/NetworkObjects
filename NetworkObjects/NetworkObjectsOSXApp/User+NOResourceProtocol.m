//
//  User+NOResourceProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/12/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "User+NOResourceProtocol.h"
#import "Session.h"
#import "Client.h"
#import "AppDelegate.h"

@implementation User (NOResourceProtocol)

+(NSString *)resourcePath
{
    static NSString *path = @"user";
    return path;
}

+(NSString *)resourceIDKey
{
    static NSString *key = @"resourceID";
    return key;
}

+(BOOL)requireSession
{
    return YES;
}

+(NSSet *)requiredInitialProperties
{
    return [NSSet setWithArray:@[@"username"]];
}

#pragma mark - NOUserProtocol

+(NSString *)userAuthorizedClientsKey
{
    static NSString *authorizedUserKey = @"authorizedClients";
    return authorizedUserKey;
}

+(NSString *)userSessionsKey
{
    static NSString *userSessionsKey = @"sessions";
    return userSessionsKey;
}

+(NSString *)userPasswordKey
{
    static NSString *userPasswordKey = @"password";
    return userPasswordKey;
}

+(NSString *)usernameKey
{
    static NSString *usernameKey = @"username";
    return usernameKey;
}

#pragma mark - Validate New Values

-(BOOL)isValidValue:(NSObject *)newValue
       forAttribute:(NSString *)attributeName
{
    if ([attributeName isEqualToString:@"username"]) {
        
        // if there is no username set then these must be the initial values edit request
        if (!self.username) {
            
            // new value will be string
            NSString *newUsername = (NSString *)newValue;
            
            // validate that another user doesnt have the same username
            AppDelegate *appDelegate = [NSApp delegate];
            
            __block NSArray *result;
            
            [appDelegate.store.context performBlockAndWait:^{
               
                NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"User"];
                
                fetch.predicate = [NSPredicate predicateWithFormat:@"%K ==[c] %@", @"password", newUsername];
                
                NSError *fetchError;
                result = [appDelegate.store.context executeFetchRequest:fetch
                                                                  error:&fetchError];
                
                if (!result) {
                    
                    [NSException raise:@"Fetch Request Failed"
                                format:@"%@", fetchError.localizedDescription];
                    return;
                }
                
            }];
            
            // no user with that username exists
            if (!result.count) {
                
                return YES;
            }
            
            return NO;
        }
        
        // username is already set, cannot change
        return NO;
    }
    
    
    return YES;
}

-(BOOL)isValidValue:(NSObject *)newValue
    forRelationship:(NSString *)relationshipName
{
    
    return YES;
}

#pragma mark - Permissions

+(BOOL)canCreateNewInstanceFromSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    Session *session = (Session *)sessionProtocolObject;
    
    // only first party apps can create posts
    if (session.user && session.client.isNotThirdParty) {
        
        return YES;
    }
    
    return NO;
}

-(BOOL)canDeleteFromSession:(NSManagedObject<NOSessionProtocol> *)session
{
    return [self.class canCreateNewInstanceFromSession:session];
}

-(NOResourcePermission)permissionForSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    return ReadOnlyPermission;
}

-(NOResourcePermission)permissionForAttribute:(NSString *)attributeName
                                      session:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    return EditPermission;
}

-(NOResourcePermission)permissionForRelationship:(NSString *)relationshipName
                                         session:(NSManagedObject<NOSessionProtocol> *)session
{
    // dont wanna directly replace relationship, use function instead
    return ReadOnlyPermission;
}

#pragma mark - Notifications

-(void)wasCreatedBySession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    
    
}

-(void)wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    
    
    
}

-(void)wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    
}

-(void)attribute:(NSString *)attributeName
wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
}

-(void)attribute:(NSString *)attributeName
wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
}

-(void)relationship:(NSString *)relationshipName
wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
    
}

-(void)relationship:(NSString *)relationshipName
 wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
    
}

#pragma mark - Functions

+(NSSet *)resourceFunctions
{
    return [NSSet setWithArray:@[@"like"]];
}

-(BOOL)canPerformFunction:(NSString *)functionName
                  session:(NSManagedObject<NOSessionProtocol> *)session
{
    return YES;
}

-(NOResourceFunctionCode)performFunction:(NSString *)functionName
                      recievedJsonObject:(NSDictionary *)recievedJsonObject
                                response:(NSDictionary *__autoreleasing *)jsonObjectResponse
{
    if ([functionName isEqualToString:@"like"]) {
        
        NSLog(@"performed 'like' function on %@", self);
        
    }
    
    return FunctionPerformedSuccesfully;
}


@end
