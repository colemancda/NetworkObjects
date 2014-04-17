//
//  Post+NOResourceKeysProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/22/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Post+NOResourceKeysProtocol.h"

@implementation Post (NOResourceKeysProtocol)

+(NSString *)resourcePath
{
    static NSString *path = @"post";
    return path;
}

+(NSString *)resourceIDKey
{
    static NSString *key = @"resourceID";
    return key;
}


@end
