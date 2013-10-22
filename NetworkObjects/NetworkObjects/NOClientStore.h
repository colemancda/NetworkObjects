//
//  NOClientStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOClientStore : NSObject

#pragma mark - Credentials

@property NSNumber *clientResourceID;

@property NSString *clientSecret;

@property NSString *username;

@property NSString *userPassword;

@property NSString *sessionToken;

#pragma mark

-(void)login

@end
