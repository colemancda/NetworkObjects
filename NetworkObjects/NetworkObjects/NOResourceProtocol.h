//
//  NOResourceProtocol.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/1/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOResourceProtocolConstants.h"

@protocol NOUserProtocol;
@protocol NOClientProtocol;
@protocol NOSessionProtocol;

@protocol NOResourceProtocol <NSObject>

#pragma mark - Network Access

// URL instances of this resource can be accessed from
+(NSString *)resourcePath;

// require authorization for this resource to be accessed
+(BOOL)requireSession;

// requires that the object be created with provided values
+(NSSet *)requireInitialValues;

#pragma mark - Attributes and Relationship paths

// Core Data attribute must be Integer type, is the numerical identifier of this resource
+(NSString *)resourceIDKey;

#pragma mark - Access

+(BOOL)canCreateNewInstanceFromSession:(NSManagedObject<NOSessionProtocol> *)session;

-(BOOL)canDeleteFromSession:(NSManagedObject<NOSessionProtocol> *)session;

// for access and edits it ask for the entire resource's permission per session first and then for individual relationships and attruibutes.
-(NOResourcePermission)permissionForSession:(NSManagedObject<NOSessionProtocol> *)session;

// e.g. you can use this to make a item editable or visible to a group but limit certain attributes or relationship to only be visible or edited by one person.
-(NOResourcePermission)permissionForAttribute:(NSString *)attributeName
                                      session:(NSManagedObject<NOSessionProtocol> *)session;

-(NOResourcePermission)permissionForRelationship:(NSString *)relationshipName
                                         session:(NSManagedObject<NOSessionProtocol> *)session;

-(BOOL)canPerformFunction:(NSString *)functionName
                  session:(NSManagedObject<NOSessionProtocol> *)session;

#pragma mark - Validate

-(BOOL)isValidValue:(NSObject *)newValue
       forAttribute:(NSString *)attributeName;

-(BOOL)isValidValue:(NSObject *)newValue
    forRelationship:(NSString *)relationshipName;

#pragma mark - Notification

-(void)wasCreatedBySession:(NSManagedObject<NOSessionProtocol> *)session;

// was viewed
-(void)wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session;

-(void)wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)session;

-(void)attribute:(NSString *)attributeName
wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session;

-(void)attribute:(NSString *)attributeName
wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)session;

-(void)relationship:(NSString *)relationshipName
wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session;

-(void)relationship:(NSString *)relationshipName
 wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)session;

#pragma mark - Resource Functions

// if you want to add a function like liking a post or adding a friend without write access to a user's friend relationship

+(NSSet *)resourceFunctions;

-(NOResourceFunctionCode)performFunction:(NSString *)functionName
                      recievedJsonObject:(NSDictionary *)recievedJsonObject
                                response:(NSDictionary **)jsonObjectResponse;

@end