//
//  User.m
//  NetworkObjectsServer
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "User.h"
#import "Client.h"
#import "Post.h"
#import "Session.h"

#import "User+NOResourceProtocol.h"

@implementation User

@dynamic created;
@dynamic password;
@dynamic resourceID;
@dynamic username;
@dynamic authorizedClients;
@dynamic createdClients;
@dynamic likedPosts;
@dynamic posts;
@dynamic sessions;

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    
    self.created = [NSDate date];
}

@end
