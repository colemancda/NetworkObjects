//
//  NOUserProtocol.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/1/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkObjects.h"

@protocol NOUserProtocol <NSObject, NOResourceProtocol>

// password
+(NSString *)userPasswordKey;

// one to many relationship to nsmanagedobject that conforms to NOClientProtocol
+(NSString *)userAuthorizedClientsKey;

// one to many relationship to nsmanagedobject that conforms to NOSessionProtocol
+(NSString *)userSessionsKey;


@end
