//
//  NSManagedObject+NOResourceProtocolCoreDataJSONCompatibility.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/19/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NOResourceProtocol.h"

@interface NSManagedObject (NOResourceProtocolCoreDataJSONCompatibility)

#pragma mark - Convenience methods

-(NSNumber *)JSONCompatibleValueForToOneRelationship:(NSString *)relationshipName;

-(void)setJSONCompatibleValue:(NSNumber *)value
         forToOneRelationship:(NSString *)relationshipName;

-(NSArray *)JSONCompatibleValueForToManyRelationship:(NSString *)relationshipName;

-(void)setJSONCompatibleValue:(NSArray *)value
        forToManyRelationship:(NSString *)relationshipName;

#pragma mark - Conversion Methods

-(NSObject *)JSONCompatibleValueForToOneRelationshipValue:(NSManagedObject<NOResourceProtocol> *)relationshipvalue
                                          forRelationship:(NSString *)relationshipName;

-(NSManagedObject<NOResourceProtocol> *)toOneRelationshipValueForJSONCompatibleValue:(NSNumber *)jsonValue forRelationship:(NSString *)relationshipName;

-(NSArray *)JSONCompatibleValueForToManyRelationshipValue:(NSArray *)relationshipvalue
                                          forRelationship:(NSString *)relationshipName;

-(NSArray *)toManyRelationshipValueForJSONCompatibleValue:(NSArray *)jsonValue
                                          forRelationship:(NSString *)relationshipName;

@end
