//
//  Post.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/12/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Post.h"
#import "User.h"

#import "Post+NOResourceProtocol.h"

@implementation Post

@dynamic created;
@dynamic resourceID;
@dynamic text;
@dynamic views;
@dynamic creator;
@dynamic likes;

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    
    self.views = @0;
    
    self.text = @"";
    
    self.created = [NSDate date];
}

@end
