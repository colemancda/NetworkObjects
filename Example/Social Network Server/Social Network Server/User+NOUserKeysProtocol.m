//
//  User+NOUserKeysProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/22/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "User+NOUserKeysProtocol.h"

@implementation User (NOUserKeysProtocol)

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

#pragma mark

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

@end
