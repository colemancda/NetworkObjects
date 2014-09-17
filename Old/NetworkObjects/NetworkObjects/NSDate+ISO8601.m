//
//  NSDate+ISO8601.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NSDate+ISO8601.h"

@implementation NSDate (ISO8601)

+(NSDateFormatter *)ISO8601DateFormatter
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZ";
        
    }
    return dateFormatter;
}

+(NSDate *)dateWithISO8601String:(NSString *)ISO8601String
{
    return [[self ISO8601DateFormatter] dateFromString:ISO8601String];
}

-(NSString *)ISO8601String
{
    return [[self.class ISO8601DateFormatter] stringFromDate:self];
}

@end
