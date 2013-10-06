//
//  NSManagedObject+CoreDataJSONCompatibility.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (CoreDataJSONCompatibility)

-(NSObject *)JSONCompatibleValueForAttribute:(NSString *)attributeName;

-(void)setJSONCompatibleValue:(NSObject *)value
                 forAttribute:(NSString *)attributeName;

@end
