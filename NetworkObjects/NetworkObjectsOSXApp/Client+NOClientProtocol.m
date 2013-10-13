//
//  Client+NOClientProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/13/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Client+NOClientProtocol.h"
#import "Session.h"

@implementation Client (NOClientProtocol)

// string attribute
+(NSString *)clientSecretKey
{
    static NSString *clientSecretKey = @"secret";
    return clientSecretKey;
}

// one to many
+(NSString *)clientSessionsKey
{
    static NSString *clientSessionsKey = @"sessions";
    return clientSessionsKey;
}

// many to many
+(NSString *)clientAuthorizedUsersKey
{
    static NSString *clientAuthorizedUsersKey = @"authorizedUsers";
    return clientAuthorizedUsersKey;
}

#pragma mark - NOResourceProtocol

+(NSString *)resourcePath
{
    static NSString *path = @"client";
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

+(BOOL)requireInitialValues
{
    return NO;
}

-(BOOL)validInitialValues
{
    return NO;
}

#pragma mark - Permissions

+(BOOL)canCreateNewInstanceFromSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    return YES;
}

-(BOOL)canDeleteFromSession:(NSManagedObject<NOSessionProtocol> *)session
{
    return [self.class canCreateNewInstanceFromSession:session];
}

-(NOResourcePermission)permissionForSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    Session *session = (Session *)sessionProtocolObject;
    
    // creator has edit permission
    if (session.user == self.creator) {
        
        return EditPermission;
    }
    
    return ReadOnlyPermission;
}

-(NOResourcePermission)permissionForAttribute:(NSString *)attributeName
                                      session:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    return NoAccessPermission;
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
    //
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
    return nil;
}

-(BOOL)canPerformFunction:(NSString *)functionName
                  session:(NSManagedObject<NOSessionProtocol> *)session
{
    return NO;
}

-(NOResourceFunctionCode)performFunction:(NSString *)functionName
                      recievedJsonObject:(NSDictionary *)recievedJsonObject
                                response:(NSDictionary *__autoreleasing *)jsonObjectResponse
{
    return InternalErrorPerformingFunction;
}


@end
