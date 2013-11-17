//
//  NSManagedObject+CoreDataJSONCompatibility.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (CoreDataJSONCompatibility)

#pragma mark - Convenience methods

-(NSObject *)JSONCompatibleValueForAttribute:(NSString *)attributeName;

-(void)setJSONCompatibleValue:(NSObject *)value
                 forAttribute:(NSString *)attributeName;

#pragma mark - Conversion methods

-(NSObject *)attributeValueForJSONCompatibleValue:(NSObject *)jsonValue
                                     forAttribute:(NSString *)attributeName;

-(NSObject *)JSONCompatibleValueForAttributeValue:(NSObject *)attributeValue
                                     forAttribute:(NSString *)attributeName;

#pragma mark - Validate

-(BOOL)isValidConvertedValue:(id)value
                forAttribute:(NSString *)attributeName;

@end

@interface NSEntityDescription (CoreDataJSONCompatibility)

-(NSObject *)JSONCompatibleValueForAttributeValue:(NSObject *)attributeValue
                                     forAttribute:(NSString *)attributeName;

@end
