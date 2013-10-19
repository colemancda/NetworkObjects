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
    return nil;
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
