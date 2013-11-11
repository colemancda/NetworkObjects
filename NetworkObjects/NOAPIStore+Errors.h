//
//  NOAPIStore+Errors.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <NetworkObjects/NetworkObjects.h>
#import "NOAPIStoreConstants.h"

@interface NOAPIStore (Errors)

-(NSError *)vaidateFetchRequest:(NSFetchRequest *)fetchRequest;

@end
