//
//  Post.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/13/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Post : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSNumber * resourceID;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * views;
@property (nonatomic, retain) User *creator;
@property (nonatomic, retain) NSSet *likes;
@end

@interface Post (CoreDataGeneratedAccessors)

- (void)addLikesObject:(User *)value;
- (void)removeLikesObject:(User *)value;
- (void)addLikes:(NSSet *)values;
- (void)removeLikes:(NSSet *)values;

@end
