//
//  NSManagedObject+CoreDataJSONCompatibility.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (CoreDataJSONCompatibility)

-(NSObject *)JSONCompatibleValueForKey:(NSString *)key;

-(void)setJSONCompatibleValue:(NSObject *)value
                       forKey:(NSString *)key;

@end
