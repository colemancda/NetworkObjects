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
    return @"post";
}

+(NSString *)resourceIDKey
{
    return @"resourceID";
}


@end
