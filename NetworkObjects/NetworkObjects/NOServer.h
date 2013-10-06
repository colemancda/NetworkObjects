//
//  NOServer.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NOStore, RouteRequest, RouteResponse, RoutingHTTPServer;

@interface NOServer : NSObject

-(id)initWithStore:(NOStore *)store;

@property (readonly) NOStore *store;

@property (readonly) RoutingHTTPServer *httpServer;

@property (readonly) NSEntityDescription *userEntityDescription;

@property (readonly) NSEntityDescription *sessionEntityDescription;

@property (readonly) NSEntityDescription *clientEntityDescription;

-(void)startOnPort:(NSUInteger)port;

-(void)stop;

@property (readonly) NSDictionary *resourcePaths;

-(void)setupServerRoutes;

@property BOOL prettyPrintJSON;

#pragma mark - Responding to requests

// code for handling incoming REST requests (authentication, returning JSON data)
-(void)handleRequest:(RouteRequest *)request
forResourceWithEntityDescription:(NSEntityDescription *)entityDescription
          resourceID:(NSNumber *)resourceID
            function:(NSString *)functionName
            response:(RouteResponse *)response;

@end
