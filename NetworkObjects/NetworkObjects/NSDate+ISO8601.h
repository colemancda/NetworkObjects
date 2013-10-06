//
//  NSDate+ISO8601.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ISO8601)

+(NSDateFormatter *)ISO8601DateFormatter;

+(NSDate *)dateWithISO8601String:(NSString *)ISO8601String;

-(NSString *)ISO8601String;

@end
