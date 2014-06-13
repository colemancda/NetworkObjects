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
    return @"user";
}

+(NSString *)resourceIDKey
{
    return @"resourceID";
}

#pragma mark

+(NSString *)userAuthorizedClientsKey
{
    return @"authorizedClients";
}

+(NSString *)userSessionsKey
{
    return @"sessions";
}

+(NSString *)userPasswordKey
{
    return @"password";
}

+(NSString *)usernameKey
{
    return @"username";
}

@end
