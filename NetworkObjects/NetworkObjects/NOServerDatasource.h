//
//  NOServerDatasource.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/1/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOServer.h"

@protocol NOServerDatasource <NSObject>

-(NSManagedObjectContext *)managedContextForServer:(NOServer *)server;

@end
