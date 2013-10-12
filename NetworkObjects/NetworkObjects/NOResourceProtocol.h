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
@protocol NOSessionProtocol;

typedef NS_ENUM(NSUInteger, NOResourcePermission) {
    
    NoAccessPermission = 0,
    ReadOnlyPermission = 1,
    EditPermission    
};

@protocol NOResourceProtocol <NSObject>

#pragma mark - Network Access

// URL instances of this resource can be accessed from
+(NSString *)resourcePath;

// require authorization for this resource to be accessed
+(BOOL)requireSession;

// requires that the object be created with provided values
+(BOOL)requireInitialValues;

#pragma mark - Attributes and Relationship paths

// Core Data attribute must be Integer type, is the numerical identifier of this resource
+(NSString *)resourceIDKey;

#pragma mark - Access

+(BOOL)canCreateNewInstanceFromSession:(NSManagedObject<NOSessionProtocol> *)session;

-(BOOL)canDeleteFromSession:(NSManagedObject<NOSessionProtocol> *)session;

-(NOResourcePermission)permissionForSession:(NSManagedObject<NOSessionProtocol> *)session;

-(NOResourcePermission)permissionForAttribute:(NSString *)attributeName
                                      session:(NSManagedObject<NOSessionProtocol> *)session;

-(NOResourcePermission)permissionForRelationship:(NSString *)relationshipKey
                                         session:(NSManagedObject<NOSessionProtocol> *)session;

-(BOOL)canPerformFunction:(NSString *)functionName
                  session:(NSManagedObject<NOSessionProtocol> *)session;

#pragma mark - Delegate

-(void)wasCreatedBySession:(NSManagedObject<NOSessionProtocol> *)session;

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

-(NSUInteger)performFunction:(NSString *)functionName
          recievedJsonObject:(NSDictionary *)recievedJsonObject
                    response:(NSDictionary **)jsonObjectResponse;

@end