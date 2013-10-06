//
//  Post+NOResourceProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "Post+NOResourceProtocol.h"
#import "Client.h"

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

+(BOOL)userCanCreateNewInstance:(NSManagedObject<NOUserProtocol> *)user
                         client:(NSManagedObject<NOClientProtocol> *)client
{
    Client *ourClient = (Client *)client;
    
    if (user && ourClient.isNotThirdParty) {
        
        return YES;
    }
    
    return NO;
}

-(BOOL)isVisibleToUser:(NSManagedObject<NOUserProtocol> *)user
                client:(NSManagedObject<NOClientProtocol> *)client
{
    return YES;
}

-(BOOL)isEditableByUser:(NSManagedObject<NOUserProtocol> *)user
                 client:(NSManagedObject<NOClientProtocol> *)client
{
    
    return YES;
}

-(BOOL)attribute:(NSString *)attributeKey
 isVisibleToUser:(NSManagedObject<NOUserProtocol> *)user
          client:(NSManagedObject<NOClientProtocol> *)client
{
    
    return YES;
}

-(BOOL)attribute:(NSString *)attributeKey
isEditableByUser:(NSManagedObject<NOUserProtocol> *)user
          client:(NSManagedObject<NOClientProtocol> *)client
{
    return YES;
}

-(BOOL)relationship:(NSString *)relationshipKey
    isVisibleToUser:(NSManagedObject<NOUserProtocol> *)user
             client:(NSManagedObject<NOClientProtocol> *)client
{
    
    return YES;
}

-(BOOL)relationship:(NSString *)relationshipKey
   isEditableByUser:(NSManagedObject<NOUserProtocol> *)user
             client:(NSManagedObject<NOClientProtocol> *)client
{
    
    return YES;
}

-(BOOL)canPerformFunction:(NSString *)functionName
                     user:(NSManagedObject<NOUserProtocol> *)user
                   client:(NSManagedObject<NOClientProtocol> *)client
{
    
    return YES;
}

-(NSUInteger)performFunction:(NSString *)functionName
          recievedJsonObject:(NSDictionary *)recievedJsonObject
                    response:(NSDictionary *__autoreleasing *)jsonObjectResponse
{
    if ([functionName isEqualToString:@"like"]) {
        
        
        
    }
}

@end
