//
//  NOResourceProtocol.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/1/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NetworkObjects/NOResourceProtocolConstants.h>

@protocol NOUserProtocol;
@protocol NOClientProtocol;
@protocol NOSessionProtocol;

// clients only need to implement the keys protocol

/**
 This is the protocol that Core Data entities in NetworkObject clients and servers must implement.
 */

@protocol NOResourceKeysProtocol <NSObject>

#pragma mark - Mapping Keys

// Core Data attribute must be Integer type, is the numerical identifier of this resource

/**
 This returns the key of the attribute that holds the Resource ID.
 
 @return Returns the name of a integer attribute (preferably Integer 64) that will hold the Resource ID of this Resource.
 */

+(NSString *)resourceIDKey;

// URL instances of this resource can be accessed from

/**
 This returns the URL that will be used to access instances of this Resource.
 
 @return Returns a string that will be used to generate a REST URL scheme for this Resource.
 */

+(NSString *)resourcePath;

@end

// For servers only

/**
 This is the protocol that Core Data entities in NetworkObject servers must implement.
 */

@protocol NOResourceProtocol <NSObject, NOResourceKeysProtocol>

#pragma mark - Network Access

// require authorization for this resource to be accessed

/**
 Returns a boolean value indicating whether an authentication session is required to access this Resource.
 
 @return @c YES if this Resource requires authentication or @c NO if this Resource does not require authentication.
 */

+(BOOL)requireSession;

#pragma - Initial Values

// requires that the object be created with provided values

/**
 An NSSet with the names of attributes and relationships that must have a value when this Resource is being created.
 
 @return Returns @c nil (for no initial values) or an NSSet with NSString values representing the properties that must have a value upon creation of new instances.
 */

+(NSSet *)requiredInitialProperties;

#pragma mark - Access

/**
 Determines whether a session can create new instances of this resource.
 
 @param session The session that wants to create a new instance.
 
 @return Returns @c YES or @c NO.
 */

+(BOOL)canCreateNewInstanceFromSession:(NSManagedObject<NOSessionProtocol> *)session;

/**
 Determines whether a session can delete an instance of a Resoource.
 
 @param session The session that wants to delete an instance.
 
 @return Returns @c YES or @c NO.
 */

-(BOOL)canDeleteFromSession:(NSManagedObject<NOSessionProtocol> *)session;

// for access and edits it ask for the entire resource's permission per session first and then for individual relationships and attruibutes.

/**
 Determines the permission level of the entire Resource instance for the session requesting it. When a session requests access (read or write) to an instance, this method is called first an then the individiual permissions for the properties to be accessed.
 
 @param session The session that wants to access an instance.
 
 @see NOResourcePermission
 
 @return Returns a NOResourcePermission constant.
 */
-(NOResourcePermission)permissionForSession:(NSManagedObject<NOSessionProtocol> *)session;

// e.g. you can use this to make a item editable or visible to a group but limit certain attributes or relationship to only be visible or edited by one person.

/**
 Determines the permission level of an attribute for for the session requesting it.
 
 @param attributeName The name of the attribute that is being accessed.
 
 @param session The session that wants to access an instance's attribute.
 
 @see NOResourcePermission
 
 @return Returns a NOResourcePermission constant.
 */
-(NOResourcePermission)permissionForAttribute:(NSString *)attributeName
                                      session:(NSManagedObject<NOSessionProtocol> *)session;

/**
 Determines the permission level of a relationship for the session requesting it.
 
 @param relationshipName The name of the relationship that is being accessed.
 
 @param session The session that wants to access an instance's relationship.
 
 @see NOResourcePermission
 
 @return Returns a NOResourcePermission constant.
 */

-(NOResourcePermission)permissionForRelationship:(NSString *)relationshipName
                                         session:(NSManagedObject<NOSessionProtocol> *)session;

/**
 Determines whether a session can perform a function on an instance of the Resource. Note that the function name given will always be valid.
 
 @param functionName The name of the function that the @c session want to perform.
 
 @param session The session that wants to perform a function.
 
 @return Returns @c YES or @c NO.
 
 */

-(BOOL)canPerformFunction:(NSString *)functionName
                  session:(NSManagedObject<NOSessionProtocol> *)session;

#pragma mark - Validate

/**
 Determines whether a new value is a valid new value for an attribute.
 
 @param newValue The new value that will be given to the attribute. Note that this will be a Core Data compatible value and not a JSON compatible value.
 
 @param attributeName The name of the attribute that will be given a new value.
 
 @return Returns @c YES or @c NO.
  */

-(BOOL)isValidValue:(NSObject *)newValue
       forAttribute:(NSString *)attributeName;

/**
 Determines whether a new value is a valid new value for a relationship.
 
 @param newValue The new value that will be given to the relationship. Note that this will be a Core Data compatible value and not a JSON compatible value. For to-one relationships this will be the potential destination Resource and for to-many relationships this will be an array of the potential destination Resources.
 
 @param relationshipName The name of the relationship that will be given a new value. This can be a to-one or to-many relationship.
 
 @return Returns @c YES or @c NO.
 */

-(BOOL)isValidValue:(NSObject *)newValue
    forRelationship:(NSString *)relationshipName;

#pragma mark - Notification

/**
 Notifies the resource that it was created by a certain session. 
 
 @param session The session that created the instance of the Resource.
 
 @see NOSessionProtocol
 */

-(void)wasCreatedBySession:(NSManagedObject<NOSessionProtocol> *)session;

// was viewed

/**
 Notifies the resource that it was accessed (viewed) by a certain session.
 
 @param session The session that accessed the instance of the Resource.
 
 @see NOSessionProtocol
 */

-(void)wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session;

/**
 Notifies the resource that it was edited by a certain session.
 
 @param session The session that edited the instance of the Resource.
 
 @see NOSessionProtocol
 */

-(void)wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)session;

/**
 Notifies the resource that an attribute was accessed (viewed) by a certain session.
 
 @param attributeName The name of the attribute that was accessed.
 
 @param session The session that accessed an attribute of an instance of the Resource.
 
 @see NOSessionProtocol
 */

-(void)attribute:(NSString *)attributeName
wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session;

/**
 Notifies the resource that an attribute was edited by a certain session.
 
 @param attributeName The name of the attribute that was edited.
 
@param session The session that edited an attribute of an instance of the Resource.
 
 @see NOSessionProtocol
 */

-(void)attribute:(NSString *)attributeName
wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)session;

/**
 Notifies the resource that a relationship was accessed (viewed) by a certain session.
 
 @param relationshipName The name of the relationship that was accessed.
 
@param session The session that accessed an relationship of an instance of the Resource.
 
 @see NOSessionProtocol
 */

-(void)relationship:(NSString *)relationshipName
wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session;

/**
 Notifies the resource that a relationship was edited by a certain session.
 
 @param relationshipName The name of the relationship that was edited.
 
 @param session The session that edited an relationship of an instance of the Resource.
 
 @see NOSessionProtocol
 */

-(void)relationship:(NSString *)relationshipName
 wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)session;

#pragma mark - Resource Functions

// if you want to add a function like liking a post or adding a friend without write access to a user's friend relationship

/**
 Return an NSSet containing NSStrings with the names of functions instances of this resource can perform.
 
 @return Returns @c nil if the Resource provides no functions to perform or an NSSet containing NSStrings representing the names of functions that can be performed on instances of the Resource.
 */

+(NSSet *)resourceFunctions;

/**
 Performs a function and returns a NOResourceFunctionCode constant based on the paramters.
 
 @param functionName The name of the function that will be performed.
 
 @param session The session that is performing the function.
 
 @param recievedJsonObject A JSON dictionary that the function can use as input. It may be nil.
 
 @param jsonObjectResponse An optional JSON response that a function can provide.
 
 @return Returns a NOResourceFunctionCode constant indicating the status of the function.
 
 @see NOResourceFunctionCode
 */

-(NOResourceFunctionCode)performFunction:(NSString *)functionName
                             withSession:(NSManagedObject<NOSessionProtocol> *)session
                      recievedJsonObject:(NSDictionary *)recievedJsonObject
                                response:(NSDictionary **)jsonObjectResponse;

@end