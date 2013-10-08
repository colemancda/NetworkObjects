//
//  RouteResponse+IPAddress.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/7/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "RouteResponse.h"

@interface RouteResponse (IPAddress)

@property (readonly) NSString *ipAddress;

@end
