//
//  NOAPIStore.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <CoreData/CoreData.h>
@class NOAPI;

FOUNDATION_EXPORT NSString *const NOAPIStoreType;

@interface NOAPIStore : NSIncrementalStore 

@property NOAPI *api;

@end
