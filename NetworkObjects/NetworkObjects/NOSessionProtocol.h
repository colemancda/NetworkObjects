//
//  NOSessionProtocol.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/2/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOResourceProtocol.h"

@protocol NOSessionProtocol <NSObject, NOResourceProtocol>

+(NSString *)sessionTokenKey;

+(NSString *)sessionUserKey;

+(NSString *)sessionClientKey;

// generate token
-(void)generateToken;

@end
