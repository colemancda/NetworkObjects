//
//  Post+NOResourceProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Post+NOResourceProtocol.h"
#import "Post+NOResourceKeysProtocol.h"
#import "Client.h"
#import "Session.h"

// LLVM thinks we didnt implement the protocol becuase its in a category

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"

@implementation Post (NOResourceProtocol)

#pragma clang diagnostic pop

+(BOOL)requireSession
{
    return NO;
}

+(NSSet *)requiredInitialProperties
{
    return nil;
}

#pragma mark - Validate New Values

-(BOOL)validateText:(id *)newValue error:(NSError **)error
{
    return YES;
}

#pragma mark - Permissions

+(BOOL)canSearchFromSession:(NSManagedObject<NOSessionProtocol> *)session
{
    return YES;
}

+(BOOL)canCreateNewInstanceFromSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    Session *session = (Session *)sessionProtocolObject;
    
    // only first party apps can create posts
    if (session.user && session.client.isNotThirdParty.boolValue) {
        
        return YES;
    }
    
    return NO;
}

-(BOOL)canDeleteFromSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    Session *session = (Session *)sessionProtocolObject;
    
    // only creator can delete post
    if (session.user == self.creator && session.client.isNotThirdParty.boolValue) {
        
        return YES;
    }
    
    return NO;
}

-(NOResourcePermission)permissionForSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    Session *session = (Session *)sessionProtocolObject;
    
    // creator has edit permission
    if (session.user == self.creator) {
        
        return NOEditPermission;
    }
    
    return NOReadOnlyPermission;
}

-(NOResourcePermission)permissionForAttribute:(NSString *)attributeName
                                      session:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    if ([attributeName isEqualToString:@"views"]) {
        
        return NOReadOnlyPermission;
    }
    
    return NOEditPermission;
}

-(NOResourcePermission)permissionForRelationship:(NSString *)relationshipName
                                         session:(NSManagedObject<NOSessionProtocol> *)session
{
    // dont wanna directly replace relationship, use function instead
    return NOReadOnlyPermission;
}

#pragma mark - Notifications

-(void)wasCreatedBySession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    Session *session = (Session *)sessionProtocolObject;
    
    // set the creator to the user who created the post
    self.creator = session.user;
    
}

-(void)wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    self.views = [NSNumber numberWithInteger:self.views.integerValue + 1];
}

-(void)wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    
}

-(void)attribute:(NSString *)attributeName
wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
}

-(void)attribute:(NSString *)attributeName
wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
}

-(void)relationship:(NSString *)relationshipName
wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
    
}

-(void)relationship:(NSString *)relationshipName
 wasEditedBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
    
}

#pragma mark - Functions

+(NSSet *)resourceFunctions
{
    return [NSSet setWithArray:@[@"like"]];
}

-(BOOL)canPerformFunction:(NSString *)functionName
                  session:(Session *)session
{
    if ([functionName isEqualToString:@"like"]) {
        
        // session has user and at least readonly permisson
        
        if (session.user &&
            [self permissionForSession:(id)session] > NONoAccessPermission &&
            [self permissionForRelationship:@"likes" session:(id)session] > NONoAccessPermission) {
            
            return YES;
        }
        
    }
    
    return NO;
}

-(NOResourceFunctionCode)performFunction:(NSString *)functionName
                             withSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
                      recievedJsonObject:(NSDictionary *)recievedJsonObject
                                response:(NSDictionary *__autoreleasing *)jsonObjectResponse
{
    Session *session = (Session *)sessionProtocolObject;
    
    if ([functionName isEqualToString:@"like"]) {
        
        // add like
        if (![self.likes containsObject:session.user]) {
            
            [self addLikesObject:session.user];
        }
        
        // unlike
        else {
            
            [self removeLikesObject:session.user];
            
        }
        
    }
    
    return NOFunctionPerformedSuccesfully;
}

@end
