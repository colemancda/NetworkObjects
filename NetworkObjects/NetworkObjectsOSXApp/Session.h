//
//  Session.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Session : NSManagedObject

@property (nonatomic, retain) NSNumber * resourceID;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSDate * lastUse;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSManagedObject *client;
@property (nonatomic, retain) User *user;

@end
