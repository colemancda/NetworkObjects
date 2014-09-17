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

-(id)JSONCompatibleValueForAttribute:(NSString *)attributeName;

-(void)setJSONCompatibleValue:(id)value
                 forAttribute:(NSString *)attributeName;

#pragma mark - Conversion methods

-(id)attributeValueForJSONCompatibleValue:(id)jsonValue
                                     forAttribute:(NSString *)attributeName;

-(id)JSONCompatibleValueForAttributeValue:(id)attributeValue
                             forAttribute:(NSString *)attributeName;

#pragma mark - Validate

-(BOOL)isValidConvertedValue:(id)value
                forAttribute:(NSString *)attributeName;

@end

@interface NSEntityDescription (CoreDataJSONCompatibility)

-(id)JSONCompatibleValueForAttributeValue:(id)attributeValue
                             forAttribute:(NSString *)attributeName;

-(id)attributeValueForJSONCompatibleValue:(id)jsonValue
                             forAttribute:(NSString *)attributeName;

@end
