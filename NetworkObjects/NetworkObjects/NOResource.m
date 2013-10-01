//
//  NOResource.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/1/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOResource.h"

@implementation NOResource

+(NSString *)resourceIDKey
{
    static NSString *key = @"resourceID";
    
    return key;
}

@end
