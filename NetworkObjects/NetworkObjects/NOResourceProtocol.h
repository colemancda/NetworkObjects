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

#pragma mark - Network Access

// Whether we want this resource to be broadcasted by the server
+(BOOL)isNetworked;

// URL instances of this resource can be accessed from
+(NSString *)resourcePath;

// Broadcasts number of instances
+(BOOL)countEnabled

#pragma mark - Attributes and Relationship paths

// Core Data attribute must be Integer type, is the numerical identifier of this resource
+(NSString *)resourceIDKey;

// Owner (user who created resource) relationship key, must be one-to-one relationship to a NSManagedSubclass that conforms to NOUserProtocol
+(NSString *)resourceOwnerKey;

#pragma mark - Access

-(BOOL)attribute:(NSString *)attributeKey
 isVisibleToUser:(id<NOUserProtocol>)user
          client:(id<NOClientProtocol>)client;

-(BOOL)relationship:(NSString *)relationshipKey
    isVisibleToUser:(id<NOUserProtocol>)user
             client:(id<NOClientProtocol>)client;



@end
