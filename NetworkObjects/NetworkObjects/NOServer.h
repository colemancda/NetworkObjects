//
//  NOServer.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOSessionProtocol.h"
@class NOStore, RouteRequest, RouteResponse, RoutingHTTPServer;

NS_ENUM(NSUInteger, NOServerStatusCodes) {
    
    OKStatusCode = 200,
    
    BadRequestStatusCode = 400,
    UnauthorizedStatusCode, // not logged in
    PaymentRequiredStatusCode,
    ForbiddenStatusCode, // item is invisible to user or api app
    NotFoundStatusCode, // item doesnt exist
    MethodNotAllowedStatusCode,
    ConflictStatusCode = 409, // user already exists
    
    InternalServerErrorStatusCode = 500
    
};

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

-(void)handleCreateResourceWithEntityDescription:(NSEntityDescription *)entityDescription
                              recievedJsonObject:(NSDictionary *)recievedJsonObject
                                         session:(NSManagedObject<NOSessionProtocol> *)session
                                        response:(RouteResponse *)response;

-(void)handleFunction:(NSString *)functionName
   recievedJsonObject:(NSDictionary *)recievedJsonObject
             resource:(id<NOResourceProtocol>)resource
              session:(id<NOSessionProtocol>)session
             response:(RouteResponse *)response;

-(void)handleEditResource:(NSManagedObject <NOResourceProtocol> *)resource
       recievedJsonObject:(NSDictionary *)recievedJsonObject
                  session:(NSManagedObject <NOSessionProtocol> *)session
                 response:(RouteResponse *)response;

-(void)handleGetResource:(NSManagedObject <NOResourceProtocol> *)resource
                 session:(NSManagedObject <NOSessionProtocol> *)session
                response:(RouteResponse *)response;

-(void)handleDeleteResource:(NSManagedObject <NOResourceProtocol> *)resource
                    session:(NSManagedObject <NOSessionProtocol> *)session
                   response:(RouteResponse *)response;

@end
