//
//  NOHTTPServer.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/19/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "RoutingHTTPServer.h"
@class NOServer;

@interface NOHTTPServer : RoutingHTTPServer

@property (nonatomic) NOServer *server;

@end
