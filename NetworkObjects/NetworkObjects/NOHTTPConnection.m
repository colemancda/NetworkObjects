//
//  NOHTTPConnection.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/19/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOHTTPConnection.h"
#import "NOServer.h"

@implementation NOHTTPConnection

-(BOOL)expectsRequestBodyFromMethod:(NSString *)method
                             atPath:(NSString *)path
{
    // if its the login path
    if ([path isEqualToString:self.server.loginPath] &&
        [method isEqualToString:@"GET"]) {
        
        return YES;
    }
    
    if ([method isEqualToString:@"PUT"] ||
        [method isEqualToString:@"GET"]) {
        
        return YES;
    }
    
    return NO;
}

@end
