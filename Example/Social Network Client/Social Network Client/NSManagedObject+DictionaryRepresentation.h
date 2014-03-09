//
//  NSManagedObject+DictionaryRepresentation.h
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 3/8/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (DictionaryRepresentation)

@property (readonly) NSDictionary *dictionaryRepresentation;

-(BOOL)isEqualToDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation;

@end
