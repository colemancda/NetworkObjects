//
//  Client.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/13/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Client.h"
#import "Session.h"
#import "User.h"

#import "Client+NOClientProtocol.h"

@implementation Client

@dynamic created;
@dynamic isNotThirdParty;
@dynamic name;
@dynamic resourceID;
@dynamic secret;
@dynamic authorizedUsers;
@dynamic sessions;
@dynamic creator;

@end
