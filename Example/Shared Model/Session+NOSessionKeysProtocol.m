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
    return @"session";
}

+(NSString *)resourceIDKey
{
    return @"resourceID";
}

#pragma mark - Session Protocol

+(NSString *)sessionTokenKey
{
    return @"token";
}

+(NSString *)sessionUserKey
{
    return @"user";
}

+(NSString *)sessionClientKey
{
    return @"client";
}

@end
