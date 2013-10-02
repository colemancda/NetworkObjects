//
//  NOServer.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RoutingHTTPServer.h"
#import "NetworkObjects.h"

@interface NOServer : NSObject
{
    RoutingHTTPServer *_httpServer;
}

-(id)initWithStore:(NOStore *)store;

@property (readonly) NOStore *store;

-(void)startOnPort:(NSUInteger)port;

-(void)stop;

@property (readonly) NSDictionary *resourceUrls;

-(void)setupServerRoutes;

// code for handling incoming REST requests (authentication, returning JSON data)
-(void)handleRequest:(RouteRequest *)request
            response:(RouteResponse *)response;


@end
