//
//  NOCacheOperation.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 4/12/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;
@class NOAPI;

@interface NOCacheOperation : NSOperation

#pragma mark - Input

@property NOAPI *API;

@property NSURLSession *URLSession;

@property NSManagedObjectContext *context;

#pragma mark - Output

@property (readonly) NSURLSessionDataTask *dataTask;

@property (readonly) NSError *error;

@end
