//
//  NOResourceProtocol.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/1/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NOUserProtocol;
@protocol NOClientProtocol;

@protocol NOResourceProtocol <NSObject>

#pragma mark - Network Access

// Whether we want this resource to be broadcasted by the server
+(BOOL)isNetworked;

// URL instances of this resource can be accessed from
+(NSString *)resourcePath;

#pragma mark - Attributes and Relationship paths

// Core Data attribute must be Integer type, is the numerical identifier of this resource
+(NSString *)resourceIDKey;

#pragma mark - Access

-(BOOL)isVisibleToUser:(id<NOUserProtocol>)user
                client:(id<NOClientProtocol>)client;

-(BOOL)isEditableByUser:(id<NOUserProtocol>)user
                 client:(id<NOClientProtocol>)client;

-(BOOL)attribute:(NSString *)attributeKey
 isVisibleToUser:(id<NOUserProtocol>)user
          client:(id<NOClientProtocol>)client;

-(BOOL)attribute:(NSString *)attributeKey
isEditableByUser:(id<NOUserProtocol>)user
          client:(id<NOClientProtocol>)client;

-(BOOL)relationship:(NSString *)relationshipKey
    isVisibleToUser:(id<NOUserProtocol>)user
             client:(id<NOClientProtocol>)client;

-(BOOL)relationship:(NSString *)relationshipKey
   isEditableByUser:(id<NOUserProtocol>)user
             client:(id<NOClientProtocol>)client;

#pragma mark - Resource Functions

// if you want to add a function like liking a post or adding a friend without write access to a user's friend relationship

+(NSSet *)resourceFunctions;

-(NSUInteger)performFunction:(NSString *)functionName
          recievedJsonObject:(NSDictionary *)recievedJsonObject
                    response:(NSDictionary **)jsonObjectResponse;

#pragma mark - Instance Functions



// nsset of the name of functions
+(NSSet *)resourceInstanceFunctions;

// return a HTTP status code
-(NSUInteger)performInstanceFunction:(NSString *)functionName
                  recievedJsonObject:(NSDictionary *)recievedJsonObject
                            response:(NSDictionary **)jsonObjectResponse;


@end