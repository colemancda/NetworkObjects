//
//  User.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/6/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * resourceID;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSSet *authorizedClients;
@property (nonatomic, retain) NSManagedObject *posts;
@property (nonatomic, retain) NSSet *sessions;
@property (nonatomic, retain) NSSet *likedPosts;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addAuthorizedClientsObject:(NSManagedObject *)value;
- (void)removeAuthorizedClientsObject:(NSManagedObject *)value;
- (void)addAuthorizedClients:(NSSet *)values;
- (void)removeAuthorizedClients:(NSSet *)values;

- (void)addSessionsObject:(NSManagedObject *)value;
- (void)removeSessionsObject:(NSManagedObject *)value;
- (void)addSessions:(NSSet *)values;
- (void)removeSessions:(NSSet *)values;

- (void)addLikedPostsObject:(NSManagedObject *)value;
- (void)removeLikedPostsObject:(NSManagedObject *)value;
- (void)addLikedPosts:(NSSet *)values;
- (void)removeLikedPosts:(NSSet *)values;

@end
