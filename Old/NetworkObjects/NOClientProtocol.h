//
//  NOClientProtocol.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/1/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOResourceProtocol.h"

@protocol NOClientKeysProtocol <NSObject, NOResourceKeysProtocol>

// string attribute
+(NSString *)clientSecretKey;

// one to many
+(NSString *)clientSessionsKey;

// many to many
+(NSString *)clientAuthorizedUsersKey;

@end

@protocol NOClientProtocol <NSObject, NOResourceProtocol, NOClientKeysProtocol>



@end
