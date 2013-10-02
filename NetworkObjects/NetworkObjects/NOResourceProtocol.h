//
//  NOResourceProtocol.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/1/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NOResourceProtocol <NSObject>

// Core Data Attribute must be 
+(nsstring *)resourceIDKey;

+(nsstring *)resourcePath;



@end
