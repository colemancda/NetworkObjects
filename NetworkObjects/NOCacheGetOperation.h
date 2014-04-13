//
//  NOCacheGetOperation.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 4/13/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <NetworkObjects/NOCacheOperation.h>
#import <NetworkObjects/NOResourceProtocol.h>

@interface NOCacheGetOperation : NOCacheOperation

#pragma mark - Input

@property (nonatomic) NSString *resourceName;

@property (nonatomic) NSUInteger resourceID;

#pragma mark - Output

@property (readonly) NSManagedObject <NOResourceKeysProtocol> *resource;



@end
