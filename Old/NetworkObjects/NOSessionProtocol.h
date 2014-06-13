//
//  NOSessionProtocol.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/2/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOResourceProtocol.h"

@protocol NOSessionKeysProtocol <NSObject, NOResourceKeysProtocol>

+(NSString *)sessionTokenKey;

+(NSString *)sessionUserKey;

+(NSString *)sessionClientKey;

@end

@protocol NOSessionProtocol <NSObject, NOResourceProtocol, NOSessionKeysProtocol>

// generate token
-(void)generateToken;

-(BOOL)canUseSessionFromIP:(NSString *)ipAddress
            requestHeaders:(NSDictionary *)headers;

-(void)usedSessionFromIP:(NSString *)ipAddress
          requestHeaders:(NSDictionary *)headers;

@end
