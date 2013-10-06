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

-(NSObject *)JSONCompatibleValueForAttribute:(NSString *)attributeName
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

-(void)setJSONCompatibleValue:(NSObject *)value
                 forAttribute:(NSString *)attributeName
{
    NSAttributeDescription *attributeDescription = self.entity.attributesByName[attributeName];
    
    if (!attributeDescription) {
        return;
    }
    
    Class attributeClass = NSClassFromString(attributeDescription.attributeValueClassName);
    
    // if value is NSNull
    if (value == [NSNull null]) {
        
        [self setValue:nil
                forKey:attributeName];
        
        return;
    }
    
    // no need to change values
    if (attributeClass == [NSString class] ||
        attributeClass == [NSNumber class]) {
        
        [self setValue:value
                forKey:attributeName];
        
        return;
    }
    
    // set value based on attribute class...
    
    // date
    if (attributeClass == [NSDate class]) {
        
        // value will be nsstring
        NSString *jsonCompatibleValue = (NSString *)value;
        
        NSDate *date = [NSDate dateWithISO8601String:jsonCompatibleValue];
        
        [self setValue:date
                forKey:attributeName];
        
        return;
    }
    
    // data
    if (attributeClass == [NSData class]) {
        
        // value will be nsstring
        NSString *jsonCompatibleValue = (NSString *)value;
        
        NSData *data = [NSData dataWithBase64EncodedString:jsonCompatibleValue];
        
        [self setValue:data
                forKey:attributeName];
        
        return;
    }
    
    // unknown value
    
    NSLog(@"Unknown JSON compatible class %@", NSStringFromClass([value class]));
}

@end
