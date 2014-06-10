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
#import "NSString+RandomString.h"
#import "SNSConstants.h"

@implementation Client

@dynamic created;
@dynamic isNotThirdParty;
@dynamic name;
@dynamic resourceID;
@dynamic secret;
@dynamic authorizedUsers;
@dynamic sessions;
@dynamic creator;

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    
    self.created = [NSDate date];
    
    self.isNotThirdParty = @NO;
    
    NSUInteger tokenLength = [[NSUserDefaults standardUserDefaults] integerForKey:kSNSTokenLengthPreferenceKey];
    
    self.secret = [NSString randomStringWithLength:tokenLength];
    
    
}

@end
