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
    return @"secret";
}

// one to many
+(NSString *)clientSessionsKey
{
    return @"sessions";
}

// many to many
+(NSString *)clientAuthorizedUsersKey
{
    return @"authorizedUsers";
}

#pragma mark - NOResourceProtocol

+(NSString *)resourcePath
{
    return @"client";
}

+(NSString *)resourceIDKey
{
    return @"resourceID";
}

@end
