//
//  Client+NOClientKeysProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/22/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Client+NOClientKeysProtocol.h"

@implementation Client (NOClientKeysProtocol)

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

@end
