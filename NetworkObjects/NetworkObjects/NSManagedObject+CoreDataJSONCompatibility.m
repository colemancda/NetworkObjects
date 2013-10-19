//
//  NSManagedObject+CoreDataJSONCompatibility.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//
//

#import "NSManagedObject+CoreDataJSONCompatibility.h"
#import "NSDate+ISO8601.h"
#import "Base64.h"

@implementation NSManagedObject (CoreDataJSONCompatibility)

#pragma mark - Convenience methods

-(NSObject *)JSONCompatibleValueForAttribute:(NSString *)attributeName
{
    NSObject *attributeValue = [self valueForKey:attributeName];
    
    NSObject *jsonValue = [self JSONCompatibleValueForAttributeValue:attributeValue
                                                        forAttribute:attributeName];
    
    return jsonValue;
}

-(void)setJSONCompatibleValue:(NSObject *)value
                 forAttribute:(NSString *)attributeName
{
    NSObject *attributeValue = [self attributeValueForJSONCompatibleValue:value
                                                             forAttribute:attributeName];
    
    [self setValue:attributeValue
            forKey:attributeName];
}


#pragma mark - Conversion Methods

-(NSObject *)JSONCompatibleValueForAttributeValue:(NSObject *)attributeValue
                                     forAttribute:(NSString *)attributeName
{
    NSAttributeDescription *attributeDescription = self.entity.attributesByName[attributeName];
    
    if (!attributeDescription) {
        return nil;
    }
    
    // give value based on attribute type
    
    NSObject *originalCoreDataValue = [self valueForKey:attributeName];
    
    Class attributeClass = NSClassFromString(attributeDescription.attributeValueClassName);
    
    // nil attributes can be represented in JSON by NSNull
    if (!originalCoreDataValue) {
        
        return [NSNull null];
    }
    
    // strings and numbers are standard json data types
    if (attributeClass == [NSString class] ||
        attributeClass == [NSNumber class]) {
        
        return originalCoreDataValue;
    }
    
    // date
    if (attributeClass == [NSDate class]) {
        
        // convert to string
        NSDate *date = (NSDate *)originalCoreDataValue;
        return date.ISO8601String;
    }
    
    // data
    if (attributeClass == [NSData class]) {
        
        NSData *data = (NSData *)originalCoreDataValue;
        return data.base64EncodedString;
    }
    
    // error
    return nil;
}

-(NSObject *)attributeValueForJSONCompatibleValue:(NSObject *)jsonValue
                                     forAttribute:(NSString *)attributeName
{
    
    NSAttributeDescription *attributeDescription = self.entity.attributesByName[attributeName];
    
    if (!attributeDescription) {
        return nil;
    }
    
    Class attributeClass = NSClassFromString(attributeDescription.attributeValueClassName);
    
    // if value is NSNull
    if (jsonValue == [NSNull null]) {
        
        return nil;
    }
    
    // no need to change values
    if (attributeClass == [NSString class] ||
        attributeClass == [NSNumber class]) {
        
        return jsonValue;
    }
    
    // set value based on attribute class...
    
    // date
    if (attributeClass == [NSDate class]) {
        
        // value will be nsstring
        NSString *jsonCompatibleValue = (NSString *)jsonValue;
        
        NSDate *date = [NSDate dateWithISO8601String:jsonCompatibleValue];
        
        return date;
    }
    
    // data
    if (attributeClass == [NSData class]) {
        
        // value will be nsstring
        NSString *jsonCompatibleValue = (NSString *)jsonValue;
        
        NSData *data = [NSData dataWithBase64EncodedString:jsonCompatibleValue];
        
        return data;
    }
    
    // unknown value
    
    NSLog(@"Unknown JSON compatible class %@", NSStringFromClass([jsonValue class]));
    
    return nil;
}

@end
