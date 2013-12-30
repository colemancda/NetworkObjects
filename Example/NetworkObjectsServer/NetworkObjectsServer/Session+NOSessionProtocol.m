//
//  Session+NOSessionProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/12/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Session+NOSessionProtocol.h"
#import "NSString+RandomString.h"
#import "AppDelegate.h"
#import "Session+NOSessionKeysProtocol.h"

// LLVM thinks we didnt implement the protocol becuase its in a category

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"

@implementation Session (NOSessionProtocol)

#pragma clang diagnostic pop

-(void)generateToken
{
    // generate token
    
    NSUInteger tokenLength = [[NSUserDefaults standardUserDefaults] integerForKey:TokenLengthPreferenceKey];
    
    self.token = [NSString randomStringWithLength:tokenLength];
}

-(BOOL)canUseSessionFromIP:(NSString *)ipAddress
            requestHeaders:(NSDictionary *)headers
{
    
    return YES;
}

-(void)usedSessionFromIP:(NSString *)ipAddress
          requestHeaders:(NSDictionary *)headers
{
    self.lastUse = [NSDate date];
}

#pragma mark - NOResourceProtocol

+(BOOL)requireSession
{
    return YES;
}


+(NSSet *)requiredInitialProperties
{
    return nil;
}


#pragma mark - Validate New Values

-(BOOL)isValidValue:(NSObject *)newValue
       forAttribute:(NSString *)attributeName
{
    
    return YES;
}

-(BOOL)isValidValue:(NSObject *)newValue
    forRelationship:(NSString *)relationshipName
{
    
    return YES;
}

#pragma mark - Permissions

+(BOOL)canCreateNewInstanceFromSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    // NOServer has its own authentication (session creation) method
    return NO;
}

-(BOOL)canDeleteFromSession:(NSManagedObject<NOSessionProtocol> *)session
{
    // NO
    return [self.class canCreateNewInstanceFromSession:session];
}

-(NOResourcePermission)permissionForSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    Session *session = (Session *)sessionProtocolObject;
    
    // creator has edit permission
    if (session.user == self.user) {
        
        return EditPermission;
    }
    
    return ReadOnlyPermission;
}

-(NOResourcePermission)permissionForAttribute:(NSString *)attributeName
                                      session:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    return NoAccessPermission;
}

-(NOResourcePermission)permissionForRelationship:(NSString *)relationshipName
                                         session:(NSManagedObject<NOSessionProtocol> *)session
{
    // dont wanna directly replace relationship, use function instead
    return ReadOnlyPermission;
}

#pragma mark - Notifications

-(void)wasCreatedBySession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    // doesnt get called
}

-(void)wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    
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
    return nil;
}

-(BOOL)canPerformFunction:(NSString *)functionName
                  session:(NSManagedObject<NOSessionProtocol> *)session
{
    return NO;
}

-(NOResourceFunctionCode)performFunction:(NSString *)functionName
                             withSession:(NSManagedObject<NOSessionProtocol> *)session
                      recievedJsonObject:(NSDictionary *)recievedJsonObject
                                response:(NSDictionary *__autoreleasing *)jsonObjectResponse
{
    return InternalErrorPerformingFunction;
}

@end
