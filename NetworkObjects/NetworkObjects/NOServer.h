//
//  NOServer.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkObjects.h"

@interface NOServer : NSObject

// create a nsmanagedobject context and give it to us

-(id)initWithContext:(NSManagedObjectContext *)context;

-(void)startOnPort:(NSUInteger)port;

-(void)stop;

@property (readonly) NSManagedObjectContext *context;

@property (readonly) NSDictionary *resourceUrls;

@end
