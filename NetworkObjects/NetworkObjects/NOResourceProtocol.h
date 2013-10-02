//
//  NOResourceProtocol.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/1/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOUserProtocol.h"
#import "NOClientProtocol.h"

typedef NS_ENUM(NSInteger, NOResourcePermissions) {
    
    NOResourcePermissionsNoAccess,
    NOResourcePermissionsReadOnly,
    NOResourcePermissionsWrite,
    
};

@protocol NOResourceProtocol <NSObject>

// URL instances of this resource can be accessed from
+(NSString *)resourcePath;

#pragma mark - Attributes and Relationship paths

// Core Data attribute must be Integer type, is the numerical identifier of this resource
+(NSString *)resourceIDKey;

// Owner (user who created resource) relationship key, must be one-to-one relationship
+(NSString *)resourceOwnerKey;

#pragma mark - Instance Methods

-(BOOL)attribute:(NSString *)attributeKey
 isVisibleToUser:(id<NOUserProtocol>)user
          client:(id<NOClientProtocol>)client;




@end
