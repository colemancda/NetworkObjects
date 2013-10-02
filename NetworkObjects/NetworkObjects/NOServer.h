//
//  NOServer.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkObjects.h"
#import "RoutingHTTPServer.h"

@interface NOServer : NSObject
{
    RoutingHTTPServer *_httpServer;
}

// create a nsmanagedobject context and give it to us

-(void)startOnPort:(NSUInteger)port;

-(void)stop;

@property (readonly) NSManagedObjectContext *context;

@property (readonly) NSDictionary *resourceUrls;

@property id<NOServerDatasource> datasource;

-(NSString *)pathForEntityDescription:(NSEntityDescription *)entityDescription;

-(void)setupServerRoutes;

// code for handling incoming REST requests (authentication, returning JSON data)
-(void)handleRequest:(RouteRequest *)request
            response:(RouteResponse *)response;


@end
