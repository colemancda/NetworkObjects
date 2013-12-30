//
//  User+NOResourceProtocol.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/12/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "User+NOResourceProtocol.h"
#import "User+NOUserKeysProtocol.h"
#import "Session.h"
#import "Client.h"
#import "AppDelegate.h"
#import <NetworkObjects/NetworkObjects.h>

// LLVM thinks we didnt implement the protocol becuase its in a category

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"

@implementation User (NOResourceProtocol)

#pragma clang diagnostic pop

+(BOOL)requireSession
{
    return YES;
}

+(NSSet *)requiredInitialProperties
{
    return [NSSet setWithArray:@[@"username", @"password"]];
}

#pragma mark - Validate New Values

-(BOOL)isValidValue:(NSObject *)newValue
       forAttribute:(NSString *)attributeName
{
    if ([attributeName isEqualToString:@"username"]) {
        
        // if there is no username set then these must be the initial values edit request
        if (!self.username) {
            
            // new value will be string
            NSString *newUsername = (NSString *)newValue;
            
            // validate that another user doesnt have the same username
            AppDelegate *appDelegate = [NSApp delegate];
            
            __block NSArray *result;
            
            [appDelegate.store.context performBlockAndWait:^{
               
                NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"User"];
                
                fetch.predicate = [NSPredicate predicateWithFormat:@"%K ==[c] %@", @"username", newUsername];
                
                NSError *fetchError;
                result = [appDelegate.store.context executeFetchRequest:fetch
                                                                  error:&fetchError];
                
                if (!result) {
                    
                    [NSException raise:@"Fetch Request Failed"
                                format:@"%@", fetchError.localizedDescription];
                    return;
                }
                
            }];
            
            // no user with that username exists
            if (!result.count) {
                
                return YES;
            }
            
            return NO;
        }
        
        // username is already set, cannot change
        return NO;
    }
    
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
    Session *session = (Session *)sessionProtocolObject;
    
    // only first party apps can create users
    if (session.client.isNotThirdParty.boolValue) {
        
        return YES;
    }
    
    return NO;
}

-(BOOL)canDeleteFromSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    Session *session = (Session *)sessionProtocolObject;
    
    // only first party apps can delete users
    if (session.client.isNotThirdParty.boolValue && session.user == self) {
        
        return YES;
    }
    
    return NO;
}

-(NOResourcePermission)permissionForSession:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    Session *session = (Session *)sessionProtocolObject;
    
    // first party app
    if (session.client.isNotThirdParty) {
        
        return EditPermission;
    }
    
    return ReadOnlyPermission;
}

-(NOResourcePermission)permissionForAttribute:(NSString *)attributeName
                                      session:(NSManagedObject<NOSessionProtocol> *)sessionProtocolObject
{
    return EditPermission;
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
    return [NSSet setWithArray:@[@"like"]];
}

-(BOOL)canPerformFunction:(NSString *)functionName
                  session:(NSManagedObject<NOSessionProtocol> *)session
{
    return YES;
}

-(NOResourceFunctionCode)performFunction:(NSString *)functionName
                      recievedJsonObject:(NSDictionary *)recievedJsonObject
                                response:(NSDictionary *__autoreleasing *)jsonObjectResponse
{
    if ([functionName isEqualToString:@"like"]) {
        
        NSLog(@"performed 'like' function on %@", self);
        
    }
    
    return FunctionPerformedSuccesfully;
}


@end
