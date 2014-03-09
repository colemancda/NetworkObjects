//
//  NSManagedObject+DictionaryRepresentation.m
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 3/8/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NSManagedObject+DictionaryRepresentation.h"

@implementation NSManagedObject (DictionaryRepresentation)

-(NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    for (NSString *attributeName in self.entity.attributesByName) {
        
        id value = [self valueForKey:attributeName];
        
        if (!value) {
            
            value = [NSNull null];
        }
        
        [dictionary addEntriesFromDictionary:@{attributeName: value}];
        
    }
    
    return dictionary;
}

-(BOOL)isEqualToDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
    for (NSString *key in dictionaryRepresentation) {
        
        id value = dictionaryRepresentation[key];
        
        value iseq
        
    }
    
}

@end
