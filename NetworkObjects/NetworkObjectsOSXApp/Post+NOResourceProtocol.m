//
//  Post+NOResourceProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Post+NOResourceProtocol.h"
#import "Client.h"
#import "Session.h"
#import "NOSessionProtocol.h"
#import "NOServer.h"

@implementation Post (NOResourceProtocol)

+(NSString *)resourcePath
{
    static NSString *path = @"post";
    return path;
}

+(NSString *)resourceIDKey
{
    static NSString *key = @"resourceID";
    return key;
}

+(BOOL)requireSession
{
    return NO;
}

+(NSSet *)resourceFunctions
{
    return [NSSet setWithArray:@[@"like"]];
}

+(BOOL)canCreateNewInstanceWithSession:(Session *)session
{
    if (session.user && session.client.isNotThirdParty) {
        
        return YES;
    }
    
    return NO;
}

-(BOOL)isVisibleToSession:(NSManagedObject<NOSessionProtocol> *)session
{
    return YES;
}

-(BOOL)isEditableBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
    return YES;
}

-(BOOL)attribute:(NSString *)attributeKey
 isVisibleToSession:(NSManagedObject<NOSessionProtocol> *)session
{
    
    return YES;
}

-(BOOL)attribute:(NSString *)attributeKey
isEditableBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    return YES;
}

-(BOOL)relationship:(NSString *)relationshipKey
    isVisibleToSession:(NSManagedObject<NOSessionProtocol> *)session
{
    
    return YES;
}

-(BOOL)relationship:(NSString *)relationshipKey
isEditableBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
    return YES;
}

-(BOOL)canPerformFunction:(NSString *)functionName
                  session:(NSManagedObject<NOSessionProtocol> *)session
{
    
    return YES;
}

-(NOServerStatusCode)performFunction:(NSString *)functionName
          recievedJsonObject:(NSDictionary *)recievedJsonObject
                    response:(NSDictionary *__autoreleasing *)jsonObjectResponse
{
    if ([functionName isEqualToString:@"like"]) {
        
        
        
    }
    
    return OKStatusCode;
}

-(void)wasAccessedBySession:(NSManagedObject<NOSessionProtocol> *)session
{
    
    
}

-(void)wasCreatedBySession:(NSManagedObject<NOSessionProtocol> *)session
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

@end
