//
//  NOStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/2/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOResourceProtocol.h"

@interface NOStore : NSObject

@property (readonly) NSManagedObjectContext *context;

#pragma mark - Resource Methods

// GET number of instances
-(NSUInteger)numberOfInstancesOfResourceWithEntityDescription:(NSEntityDescription *)entityDescription;

// Search for resource with values and keys
-(id<NOResourceProtocol>)searchForResourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                              withValuesAndKeys:(NSDictionary *)valuesAndKeys
                                              isCaseInsensitive:(BOOL)caseInsensitive;

#pragma mark - Manage Resource Instances
// Cocoa methods to manage a object graph styled after REST but without the networking or authentication, useful for editing NetworkedObjects from the server app or for other internal use.

// e.g. you want to create a new resource but dont wanna write the glue code for assigning it a proper resource ID

-(NSUInteger)newResourceWithEntityDescription:(NSEntityDescription *)entityDescription;

-(id<NOResourceProtocol>)resourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                                    id:(NSUInteger)resourceID;

-(void)deleteResourceWithEntityDescription:(NSEntityDescription *)entityDescription
                                        id:(NSUInteger)resourceID;

@end
