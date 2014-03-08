//
//  Client.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/22/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Client.h"
#import "Session.h"
#import "User.h"

#import "Client+NOClientKeysProtocol.h"

@implementation Client

@dynamic created;
@dynamic isNotThirdParty;
@dynamic name;
@dynamic resourceID;
@dynamic secret;
@dynamic authorizedUsers;
@dynamic creator;
@dynamic sessions;

@end
