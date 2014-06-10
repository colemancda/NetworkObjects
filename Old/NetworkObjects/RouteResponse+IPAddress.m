//
//  RouteResponse+IPAddress.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/7/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "RouteResponse+IPAddress.h"
#import "GCDAsyncSocket.h"
#import "HTTPConnection.h"

@implementation HTTPConnection (Socket)

-(GCDAsyncSocket *)socket
{
    return asyncSocket;
}

@end

@implementation RouteResponse (IPAddress)

-(NSString *)ipAddress
{
    // get IP Address
    
    return self.connection.socket.connectedHost;
}

@end
