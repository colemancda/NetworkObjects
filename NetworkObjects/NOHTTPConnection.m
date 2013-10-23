//
//  NOHTTPConnection.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/19/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOHTTPConnection.h"
#import "NOServer.h"
#import "NOHTTPServer.h"

@implementation NOHTTPConnection

-(BOOL)isSecureServer
{
    return (BOOL)self.sslIdentityAndCertificates;
}

-(NSArray *)sslIdentityAndCertificates
{
    NOHTTPServer *httpServer = (NOHTTPServer *)config.server;
    
    NOServer *server = httpServer.server;
    
    if (server) {
        
        
        
    }
    
    return nil;
}

@end
