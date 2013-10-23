//
//  Session+NOSessionKeysProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/22/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Session+NOSessionKeysProtocol.h"

@implementation Session (NOSessionKeysProtocol)

+(NSString *)resourcePath
{
    static NSString *path = @"session";
    return path;
}

+(NSString *)resourceIDKey
{
    static NSString *key = @"resourceID";
    return key;
}

#pragma mark

+(NSString *)sessionTokenKey
{
    static NSString *tokenKey = @"token";
    return tokenKey;
}

+(NSString *)sessionUserKey
{
    static NSString *sessionUserKey = @"user";
    return sessionUserKey;
}

+(NSString *)sessionClientKey
{
    static NSString *sessionClientKey = @"client";
    return sessionClientKey;
}

@end
